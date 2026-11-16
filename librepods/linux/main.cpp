#include <QSettings>
#include <QLocalServer>
#include <QLocalSocket>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QBluetoothSocket>
#include <QBluetoothDeviceInfo>
#include <QBluetoothAddress>
#include <QQuickWindow>
#include <QLoggingCategory>
#include <QThread>
#include <QTimer>
#include <QDateTime>
#include <QProcess>
#include <QRegularExpression>
#include <QTranslator>
#include <QLibraryInfo>
#include <QDir>
#include <QStandardPaths>
#include <QSocketNotifier>
#include <csignal>
#include <cerrno>
#include <cstring>
#include <memory>
#include <QtEndian>
#include <sys/socket.h>
#include <unistd.h>

#include "airpods_packets.h"
#include "logger.h"
#include "media/mediacontroller.h"
#include "trayiconmanager.h"
#include "enums.h"
#include "battery.hpp"
#include "BluetoothMonitor.h"
#include "autostartmanager.hpp"
#include "deviceinfo.hpp"
#include "ble/blemanager.h"
#include "ble/bleutils.h"
#include "QRCodeImageProvider.hpp"
#include "systemsleepmonitor.hpp"

using namespace AirpodsTrayApp::Enums;

Q_LOGGING_CATEGORY(librepods, "riaspods")

// The AirPods control channel: a plain L2CAP connection to PSM 0x1001.
// It is opened directly instead of through BlueZ's profile API, because BlueZ refuses
// that until it has finished connecting its own audio profiles, which delayed the first
// data (and the connect card) by about five seconds after every connection.
class AapSocket : public QObject {
    Q_OBJECT
public:
    explicit AapSocket(QObject *parent = nullptr) : QObject(parent) {}
    ~AapSocket() override { shut(); }

    bool isOpen() const { return m_connected; }
    bool isBusy() const { return m_fd >= 0; } // connecting or connected

    bool connectTo(const QBluetoothAddress &address)
    {
        shut();
        struct {
            sa_family_t family;
            quint16 psm;
            quint8 bdaddr[6];
            quint16 cid;
            quint8 bdaddrType;
        } addr;
        struct { quint8 level; quint8 keySize; } security = {2 /* medium: encrypted */, 0};
        const int afBluetooth = 31, protoL2cap = 0, solBluetooth = 274, btSecurity = 4;

        m_fd = ::socket(afBluetooth, SOCK_SEQPACKET | SOCK_NONBLOCK | SOCK_CLOEXEC, protoL2cap);
        if (m_fd < 0)
        {
            return false;
        }
        ::setsockopt(m_fd, solBluetooth, btSecurity, &security, sizeof(security));

        memset(&addr, 0, sizeof(addr));
        addr.family = afBluetooth;
        addr.psm = qToLittleEndian<quint16>(0x1001);
        const quint64 mac = address.toUInt64();
        for (int i = 0; i < 6; ++i)
        {
            addr.bdaddr[i] = static_cast<quint8>(mac >> (8 * i));
        }
        if (::connect(m_fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0 && errno != EINPROGRESS)
        {
            m_lastError = errno;
            shut();
            return false;
        }

        m_write = new QSocketNotifier(m_fd, QSocketNotifier::Write, this);
        connect(m_write, &QSocketNotifier::activated, this, &AapSocket::onWritable);
        return true;
    }

    qint64 write(const QByteArray &data)
    {
        if (!m_connected)
        {
            return -1;
        }
        return ::send(m_fd, data.constData(), data.size(), MSG_NOSIGNAL);
    }

    void close() { shut(); }
    int lastError() const { return m_lastError; }

signals:
    void connected();
    void failed(int error);   // could not be opened
    void disconnected();      // was open, closed by the AirPods or the link
    void packet(const QByteArray &data);

private:
    void onWritable()
    {
        m_write->setEnabled(false);
        int err = 0;
        socklen_t len = sizeof(err);
        ::getsockopt(m_fd, SOL_SOCKET, SO_ERROR, &err, &len);
        if (err != 0)
        {
            m_lastError = err;
            shut();
            emit failed(err);
            return;
        }
        m_connected = true;
        m_read = new QSocketNotifier(m_fd, QSocketNotifier::Read, this);
        connect(m_read, &QSocketNotifier::activated, this, &AapSocket::onReadable);
        emit connected();
    }

    void onReadable()
    {
        // one read is one packet on this kind of socket
        char buffer[4096];
        const ssize_t n = ::recv(m_fd, buffer, sizeof(buffer), 0);
        if (n > 0)
        {
            emit packet(QByteArray(buffer, static_cast<int>(n)));
            return;
        }
        if (n < 0 && (errno == EAGAIN || errno == EINTR))
        {
            return;
        }
        m_lastError = n < 0 ? errno : 0;
        shut();
        emit disconnected();
    }

    void shut()
    {
        if (m_write) { m_write->setEnabled(false); m_write->deleteLater(); m_write = nullptr; }
        if (m_read) { m_read->setEnabled(false); m_read->deleteLater(); m_read = nullptr; }
        if (m_fd >= 0) { ::close(m_fd); m_fd = -1; }
        m_connected = false;
    }

    int m_fd = -1;
    bool m_connected = false;
    int m_lastError = 0;
    QSocketNotifier *m_write = nullptr;
    QSocketNotifier *m_read = nullptr;
};

class AirPodsTrayApp : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool airpodsConnected READ areAirpodsConnected NOTIFY airPodsStatusChanged)
    Q_PROPERTY(int earDetectionBehavior READ earDetectionBehavior WRITE setEarDetectionBehavior NOTIFY earDetectionBehaviorChanged)
    Q_PROPERTY(bool crossDeviceEnabled READ crossDeviceEnabled WRITE setCrossDeviceEnabled NOTIFY crossDeviceEnabledChanged)
    Q_PROPERTY(AutoStartManager *autoStartManager READ autoStartManager CONSTANT)
    Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled NOTIFY notificationsEnabledChanged)
    Q_PROPERTY(int retryAttempts READ retryAttempts WRITE setRetryAttempts NOTIFY retryAttemptsChanged)
    Q_PROPERTY(bool hideOnStart READ hideOnStart CONSTANT)
    Q_PROPERTY(DeviceInfo *deviceInfo READ deviceInfo CONSTANT)
    Q_PROPERTY(QString phoneMacStatus READ phoneMacStatus NOTIFY phoneMacStatusChanged)
    Q_PROPERTY(bool hearingAidEnabled READ hearingAidEnabled WRITE setHearingAidEnabled NOTIFY hearingAidEnabledChanged)

public:
    AirPodsTrayApp(bool debugMode, bool hideOnStart, QQmlApplicationEngine *parent = nullptr)
        : QObject(parent), debugMode(debugMode), m_settings(new QSettings("RiasPods", "RiasPods"))
        , m_autoStartManager(new AutoStartManager(this)), m_hideOnStart(hideOnStart), parent(parent)
        , m_deviceInfo(new DeviceInfo(this)), m_bleManager(new BleManager(this))
        , m_systemSleepMonitor(new SystemSleepMonitor(this))
    {
        QLoggingCategory::setFilterRules(QString("riaspods.debug=%1").arg(debugMode ? "true" : "false"));
        LOG_INFO("Initializing RiasPods");

        // Initialize tray icon and connect signals
        trayManager = new TrayIconManager(this);
        trayManager->setNotificationsEnabled(loadNotificationsEnabled());
        connect(trayManager, &TrayIconManager::trayClicked, this, &AirPodsTrayApp::onTrayIconActivated);
        connect(trayManager, &TrayIconManager::openApp, this, &AirPodsTrayApp::onOpenApp);
        connect(trayManager, &TrayIconManager::openSettings, this, &AirPodsTrayApp::onOpenSettings);
        connect(trayManager, &TrayIconManager::noiseControlChanged, this, &AirPodsTrayApp::setNoiseControlMode);
        connect(trayManager, &TrayIconManager::conversationalAwarenessToggled, this, &AirPodsTrayApp::setConversationalAwareness);
        connect(m_deviceInfo, &DeviceInfo::batteryStatusChanged, trayManager, &TrayIconManager::updateBatteryStatus);
        connect(m_deviceInfo, &DeviceInfo::noiseControlModeChanged, trayManager, &TrayIconManager::updateNoiseControlState);
        connect(m_deviceInfo, &DeviceInfo::conversationalAwarenessChanged, trayManager, &TrayIconManager::updateConversationalAwareness);
        connect(trayManager, &TrayIconManager::notificationsEnabledChanged, this, &AirPodsTrayApp::saveNotificationsEnabled);
        connect(trayManager, &TrayIconManager::notificationsEnabledChanged, this, &AirPodsTrayApp::notificationsEnabledChanged);

        // Initialize MediaController and connect signals
        mediaController = new MediaController(this);
        connect(mediaController, &MediaController::mediaStateChanged, this, &AirPodsTrayApp::handleMediaStateChange);
        mediaController->followMediaChanges();

        monitor = new BluetoothMonitor(this);
        connect(monitor, &BluetoothMonitor::deviceConnected, this, &AirPodsTrayApp::bluezDeviceConnected);
        connect(monitor, &BluetoothMonitor::deviceDisconnected, this, &AirPodsTrayApp::bluezDeviceDisconnected);
        connect(monitor, &BluetoothMonitor::connectFailed, this, &AirPodsTrayApp::onAutoConnectFailed);

        connect(m_bleManager, &BleManager::deviceFound, this, &AirPodsTrayApp::bleDeviceFound);
        connect(m_deviceInfo->getBattery(), &Battery::primaryChanged, this, &AirPodsTrayApp::primaryChanged);
        connect(m_systemSleepMonitor, &SystemSleepMonitor::systemGoingToSleep, this, &AirPodsTrayApp::onSystemGoingToSleep);
        connect(m_systemSleepMonitor, &SystemSleepMonitor::systemWakingUp, this, &AirPodsTrayApp::onSystemWakingUp);

        // Load settings
        CrossDevice.isEnabled = loadCrossDeviceEnabled();
        setEarDetectionBehavior(loadEarDetectionSettings());
        setRetryAttempts(loadRetryAttempts());

        m_reconnectTimer = new QTimer(this);
        m_reconnectTimer->setSingleShot(true);
        connect(m_reconnectTimer, &QTimer::timeout, this, &AirPodsTrayApp::onReconnectTimer);

        LOG_INFO("AirPodsTrayApp initialized");

        initializeDBus();
        initializeBluetooth();
        // AirPods that are already connected (login, restart of the app) are reported
        // through the same path as a fresh connection.
        monitor->checkAlreadyConnectedDevices();
    }

    ~AirPodsTrayApp() {
        saveCrossDeviceEnabled();
        saveEarDetectionSettings();

        delete socket;
        delete phoneSocket;
    }

    bool areAirpodsConnected() const { return socket && socket->isOpen(); }
    int earDetectionBehavior() const { return mediaController->getEarDetectionBehavior(); }
    bool crossDeviceEnabled() const { return CrossDevice.isEnabled; }
    AutoStartManager *autoStartManager() const { return m_autoStartManager; }
    bool notificationsEnabled() const { return trayManager->notificationsEnabled(); }
    void setNotificationsEnabled(bool enabled) { trayManager->setNotificationsEnabled(enabled); }
    int retryAttempts() const { return m_retryAttempts; }
    bool hideOnStart() const { return m_hideOnStart; }
    DeviceInfo *deviceInfo() const { return m_deviceInfo; }
    QString phoneMacStatus() const { return m_phoneMacStatus; }
    bool hearingAidEnabled() const { return m_deviceInfo->hearingAidEnabled(); }

private:
    bool debugMode;
    bool isConnectedLocally = false;

    QQmlApplicationEngine *parent = nullptr;

    struct {
        bool isAvailable = true;
        bool isEnabled = true; // Ability to disable the feature
    } CrossDevice;

    void initializeDBus() { }

    bool isAirPodsDevice(const QBluetoothDeviceInfo &device)
    {
        return device.serviceUuids().contains(QBluetoothUuid("74ec2172-0bad-4d01-8f77-997b2be0722a"));
    }

    void notifyAndroidDevice()
    {
        if (!CrossDevice.isEnabled) {
            return;
        }

        if (phoneSocket && phoneSocket->isOpen())
        {
            phoneSocket->write(AirPodsPackets::Phone::NOTIFICATION);
            LOG_DEBUG("Sent notification packet to Android: " << AirPodsPackets::Phone::NOTIFICATION.toHex());
        }
        else
        {
            LOG_WARN("Phone socket is not open, cannot send notification packet");
        }
    }

    void disconnectDevice(const QString &devicePath) {
        LOG_INFO("Disconnecting device at " << devicePath);
    }

public slots:
    void connectToDevice(const QString &address) {
        LOG_INFO("Connecting to device with address: " << address);
        QBluetoothAddress btAddress(address);
        QBluetoothDeviceInfo device(btAddress, "", 0);
        connectToDevice(device);
    }

    void setNoiseControlMode(NoiseControlMode mode)
    {
        if (m_deviceInfo->noiseControlMode() == mode)
        {
            LOG_INFO("Noise control mode is already set to: " << static_cast<int>(mode));
            return;
        }
        LOG_INFO("Setting noise control mode to: " << mode);
        QByteArray packet = AirPodsPackets::NoiseControl::getPacketForMode(mode);
        writePacketToSocket(packet, "Noise control mode packet written: ");
    }
    void setNoiseControlModeInt(int mode)
    {
        if (mode < 0 || mode > static_cast<int>(NoiseControlMode::Adaptive))
        {
            LOG_ERROR("Invalid noise control mode: " << mode);
            return;
        }
        setNoiseControlMode(static_cast<NoiseControlMode>(mode));
    }

    void setConversationalAwareness(bool enabled)
    {
        LOG_INFO("Setting conversational awareness to: " << (enabled ? "enabled" : "disabled"));
        QByteArray packet = enabled ? AirPodsPackets::ConversationalAwareness::ENABLED
                                    : AirPodsPackets::ConversationalAwareness::DISABLED;

        writePacketToSocket(packet, "Conversational awareness packet written: ");
        m_deviceInfo->setConversationalAwareness(enabled);
    }

    void setOneBudANCMode(bool enabled)
    {
        if (m_deviceInfo->oneBudANCMode() == enabled)
        {
            LOG_INFO("One Bud ANC mode is already " << (enabled ? "enabled" : "disabled"));
            return;
        }

        LOG_INFO("Setting One Bud ANC mode to: " << (enabled ? "enabled" : "disabled"));
        QByteArray packet = enabled ? AirPodsPackets::OneBudANCMode::ENABLED
                                    : AirPodsPackets::OneBudANCMode::DISABLED;

        if (writePacketToSocket(packet, "One Bud ANC mode packet written: "))
        {
            m_deviceInfo->setOneBudANCMode(enabled);
        }
        else
        {
            LOG_ERROR("Failed to send One Bud ANC mode command: socket not open");
        }
    }

    void setRetryAttempts(int attempts)
    {
        if (m_retryAttempts != attempts)
        {
            LOG_DEBUG("Setting retry attempts to: " << attempts);
            m_retryAttempts = attempts;
            emit retryAttemptsChanged(attempts);
            saveRetryAttempts(attempts);
        }
    }

    void initiateMagicPairing()
    {
        if (!socket || !socket->isOpen())
        {
            LOG_ERROR("Socket nicht offen, Magic Pairing kann nicht gestartet werden");
            return;
        }

        writePacketToSocket(AirPodsPackets::MagicPairing::REQUEST_MAGIC_CLOUD_KEYS, "Magic Pairing packet written: ");
    }

    void setAdaptiveNoiseLevel(int level)
    {
        level = qBound(0, level, 100);
        if (m_deviceInfo->adaptiveNoiseLevel() != level && m_deviceInfo->adaptiveModeActive())
        {
            QByteArray packet = AirPodsPackets::AdaptiveNoise::getPacket(level);
            writePacketToSocket(packet, "Adaptive noise level packet written: ");
            m_deviceInfo->setAdaptiveNoiseLevel(level);
        }
    }

    void renameAirPods(const QString &newName)
    {
        if (newName.isEmpty())
        {
            LOG_WARN("Cannot set empty name");
            return;
        }
        if (newName.size() > 32)
        {
            LOG_WARN("Name is too long, must be 32 characters or less");
            return;
        }
        if (newName == m_deviceInfo->deviceName())
        {
            LOG_INFO("Name is already set to: " << newName);
            return;
        }

        QByteArray packet = AirPodsPackets::Rename::getPacket(newName);
        if (writePacketToSocket(packet, "Rename packet written: "))
        {
            LOG_INFO("Sent rename command for new name: " << newName);
            m_deviceInfo->setDeviceName(newName);
        }
        else
        {
            LOG_ERROR("Failed to send rename command: socket not open");
        }
    }

    void setEarDetectionBehavior(int behavior)
    {
        if (behavior == earDetectionBehavior())
        {
            LOG_INFO("Ear detection behavior is already set to: " << behavior);
            return;
        }

        mediaController->setEarDetectionBehavior(static_cast<MediaController::EarDetectionBehavior>(behavior));
        saveEarDetectionSettings();
        emit earDetectionBehaviorChanged(behavior);
    }

    void setCrossDeviceEnabled(bool enabled)
    {
        if (CrossDevice.isEnabled == enabled)
        {
            LOG_INFO("Cross-device feature is already " << (enabled ? "enabled" : "disabled"));
            return;
        }

        CrossDevice.isEnabled = enabled;
        saveCrossDeviceEnabled();
        connectToPhone();
        emit crossDeviceEnabledChanged(enabled);
    }

    void setPhoneMac(const QString &mac)
    {
        if (mac.isEmpty()) {
            LOG_WARN("Empty MAC provided, ignoring");
            m_phoneMacStatus = QStringLiteral("No MAC provided (ignoring)");
            emit phoneMacStatusChanged();
            return;
        }

        // Basic MAC address validation (accepts formats like AA:BB:CC:DD:EE:FF, AABBCCDDEEFF, AA-BB-CC-DD-EE-FF)
        QRegularExpression re("^([0-9A-Fa-f]{2}([-:]?)){5}[0-9A-Fa-f]{2}$");
        if (!re.match(mac).hasMatch()) {
            LOG_ERROR("Invalid MAC address format: " << mac);
            m_phoneMacStatus = QStringLiteral("Invalid MAC: ") + mac;
            emit phoneMacStatusChanged();
            return;
        }

        // Set environment variable for the running process
        qputenv("PHONE_MAC_ADDRESS", mac.toUtf8());
        LOG_INFO("PHONE_MAC_ADDRESS environment variable set to: " << mac);

        m_phoneMacStatus = QStringLiteral("Updated MAC: ") + mac;
        emit phoneMacStatusChanged();

        // Update QML context property so UI placeholders reflect the new value
        if (parent) {
            parent->rootContext()->setContextProperty("PHONE_MAC_ADDRESS", mac);
        }

        // If a phone socket exists, restart connection using the new MAC
        if (phoneSocket && phoneSocket->isOpen()) {
            phoneSocket->close();
            phoneSocket->deleteLater();
            phoneSocket = nullptr;
        }
        connectToPhone();
    }

    void updatePhoneMacStatus(const QString &status)
    {
        m_phoneMacStatus = status;
        emit phoneMacStatusChanged();
    }

    void setHearingAidEnabled(bool enabled)
    {
        LOG_INFO("Setting hearing aid to: " << (enabled ? "enabled" : "disabled"));
        QByteArray packet = enabled ? AirPodsPackets::HearingAid::ENABLED
                                    : AirPodsPackets::HearingAid::DISABLED;

        writePacketToSocket(packet, "Hearing aid packet written: ");
        m_deviceInfo->setHearingAidEnabled(enabled);
    }

    bool writePacketToSocket(const QByteArray &packet, const QString &logMessage)
    {
        if (socket && socket->isOpen())
        {
            socket->write(packet);
            LOG_DEBUG(logMessage << packet.toHex());
            return true;
        }
        else
        {
            LOG_ERROR("Socket is not open, cannot write packet");
            return false;
        }
    }

    bool loadCrossDeviceEnabled() { return m_settings->value("crossdevice/enabled", false).toBool(); }
    void saveCrossDeviceEnabled() { m_settings->setValue("crossdevice/enabled", CrossDevice.isEnabled); }

    int loadEarDetectionSettings() { return m_settings->value("earDetection/setting", MediaController::EarDetectionBehavior::PauseWhenOneRemoved).toInt(); }
    void saveEarDetectionSettings() { m_settings->setValue("earDetection/setting", mediaController->getEarDetectionBehavior()); }

    bool loadNotificationsEnabled() const { return m_settings->value("notifications/enabled", true).toBool(); }
    void saveNotificationsEnabled(bool enabled) { m_settings->setValue("notifications/enabled", enabled); }

    int loadRetryAttempts() const { return m_settings->value("bluetooth/retryAttempts", 3).toInt(); }
    void saveRetryAttempts(int attempts) { m_settings->setValue("bluetooth/retryAttempts", attempts); }

    void onSystemGoingToSleep()
    {
        if (m_bleManager->isScanning())
        {
            LOG_INFO("Stopping BLE scan before going to sleep");
            m_bleManager->stopScan();
        }
    }
    void onSystemWakingUp()
    {
        LOG_INFO("System is waking up");
        if (!areAirpodsConnected())
        {
            m_bleManager->startScan();
        }

        // Check if AirPods are already connected and activate A2DP profile
        if (areAirpodsConnected() && m_deviceInfo && !m_deviceInfo->bluetoothAddress().isEmpty())
        {
            LOG_INFO("AirPods already connected after wake-up, re-activating A2DP profile");
            mediaController->setConnectedDeviceMacAddress(m_deviceInfo->bluetoothAddress().replace(":", "_"));

            // Always activate A2DP profile after system wake since the profile might have been lost
            QTimer::singleShot(1000, this, [this]()
            {
                mediaController->activateA2dpProfile();
                LOG_INFO("A2DP profile activation attempted after system wake-up");
            });
        }

        // Also check for already connected devices via BlueZ
        monitor->checkAlreadyConnectedDevices();
    }

private slots:
    void onTrayIconActivated()
    {
        QQuickWindow *window = qobject_cast<QQuickWindow *>(
            QGuiApplication::topLevelWindows().constFirst());
        if (window)
        {
            window->show();
            window->raise();
            window->requestActivate();
        }
    }

    void onOpenApp()
    {
        QObject *rootObject = parent->rootObjects().first();
        if (rootObject) {
            QMetaObject::invokeMethod(rootObject, "reopen", Q_ARG(QVariant, "app"));
        }
        else
        {
            loadMainModule();
        }
    }

    void onOpenSettings()
    {
        QObject *rootObject = parent->rootObjects().first();
        if (rootObject) {
            QMetaObject::invokeMethod(rootObject, "reopen", Q_ARG(QVariant, "settings"));
        }
        else
        {
            loadMainModule();
        }
    }

    void sendHandshake() {
        LOG_INFO("Connected to device, sending initial packets");
        writePacketToSocket(AirPodsPackets::Connection::HANDSHAKE, "Handshake packet written: ");
    }

    void bluezDeviceConnected(const QString &address, const QString &name)
    {
        QBluetoothDeviceInfo device(QBluetoothAddress(address), name, 0);
        m_retryCount = 0;
        m_autoConnectAttempts = 0;
        connectToDevice(device);

        // After a reboot the AirPods can be connected with their audio card switched off.
        // Bring it up once the link has settled, unless ear detection says nobody wears them.
        QTimer::singleShot(2000, this, [this, address]()
        {
            if (address.isEmpty() || !monitor->isDeviceConnected(address))
            {
                return;
            }
            QString formattedAddress = address;
            mediaController->setConnectedDeviceMacAddress(formattedAddress.replace(":", "_"));
            const bool earStateKnown = areAirpodsConnected()
                && mediaController->getEarDetectionBehavior() != MediaController::EarDetectionBehavior::Disabled;
            if (!earStateKnown || m_deviceInfo->getEarDetection()->oneOrMorePodsInEar())
            {
                mediaController->activateA2dpProfile();
            }
        });
    }

    // Detach from the control socket without letting its late signals reach us.
    void dropSocket()
    {
        if (!socket)
        {
            return;
        }
        AapSocket *old = socket;
        socket = nullptr;
        old->disconnect();
        old->close();
        old->deleteLater();
    }

    void onDeviceDisconnected(const QBluetoothAddress &address)
    {
        LOG_INFO("Device disconnected: " << address.toString());
        m_reconnectTimer->stop();
        m_retryCount = 0;
        dropSocket();
        if (phoneSocket && phoneSocket->isOpen())
        {
            phoneSocket->write(AirPodsPackets::Connection::AIRPODS_DISCONNECTED);
            LOG_DEBUG("AIRPODS_DISCONNECTED packet written: " << AirPodsPackets::Connection::AIRPODS_DISCONNECTED.toHex());
        }

        // The name and model are kept (see DeviceInfo::reset)
        m_deviceInfo->reset();
        mediaController->clearConnectedDevice();
        // A disconnect with the lid still open (the AirPods moved to the phone) must not
        // be answered by connecting again: a new opening of the lid is required.
        m_lidOpen = true;
        m_lidSeenAt = QDateTime::currentMSecsSinceEpoch();
        m_autoConnectHoldUntil = m_lidSeenAt + 20000;
        // the last advertisements of a closing case still say "open"
        m_freeConnectHoldUntil = m_lidSeenAt + 4000;
        m_bleManager->startScan();
        emit airPodsStatusChanged();

        // Show system notification
        trayManager->showNotification(
            tr("AirPods Disconnected"),
            tr("Your AirPods have been disconnected"));
        trayManager->resetTrayIcon();
    }

    // The control socket failed or was closed by the AirPods. Try again, but only while
    // BlueZ still holds the link: once the AirPods have moved to another device (or into
    // the case) a reconnect attempt would page them and pull them back.
    void scheduleReconnect(const QBluetoothDeviceInfo &device)
    {
        if (m_reconnectTimer->isActive())
        {
            return;
        }
        if (m_retryCount >= m_retryAttempts)
        {
            // the counter starts over with the next connection BlueZ reports
            LOG_ERROR("Giving up on the AirPods control connection after " << m_retryCount << " attempts");
            return;
        }
        ++m_retryCount;
        m_reconnectDevice = device;
        LOG_INFO("Retrying connection (attempt " << m_retryCount << ")");
        m_reconnectTimer->start(700 * m_retryCount);
    }

    void onReconnectTimer()
    {
        if (!monitor->isDeviceConnected(m_reconnectDevice.address().toString()))
        {
            LOG_INFO("AirPods are no longer connected, not retrying");
            m_retryCount = 0;
            return;
        }
        connectToDevice(m_reconnectDevice);
    }

    void bluezDeviceDisconnected(const QString &address, const QString &name)
    {
        if (address == m_deviceInfo->bluetoothAddress())
        {
            onDeviceDisconnected(QBluetoothAddress(address));
        } else {
            LOG_WARN("Disconnected device does not match connected device: " << address << " != " << m_deviceInfo->bluetoothAddress());
        }
    }

    void parseMetadata(const QByteArray &data)
    {
        // Verify the data starts with the METADATA header
        if (!data.startsWith(AirPodsPackets::Parse::METADATA))
        {
            LOG_ERROR("Invalid metadata packet: Incorrect header");
            return;
        }

        int pos = AirPodsPackets::Parse::METADATA.size(); // Start after the header

        // Check if there is enough data to skip the initial bytes (based on example structure)
        if (data.size() < pos + 6)
        {
            LOG_ERROR("Metadata packet too short to parse initial bytes");
            return;
        }
        pos += 6; // Skip 6 bytes after the header as per example structure

        auto extractString = [&data, &pos]() -> QString
        {
            if (pos >= data.size())
            {
                return QString();
            }
            int start = pos;
            while (pos < data.size() && data.at(pos) != '\0')
            {
                ++pos;
            }
            QString str = QString::fromUtf8(data.mid(start, pos - start));
            if (pos < data.size())
            {
                ++pos; // Move past the null terminator
            }
            return str;
        };

        m_deviceInfo->setDeviceName(extractString());
        m_deviceInfo->setModelNumber(extractString());
        m_deviceInfo->setManufacturer(extractString());

        m_deviceInfo->setModel(parseModelNumber(m_deviceInfo->modelNumber()));
        emit modelChanged();

        // Log extracted metadata
        LOG_INFO("Parsed AirPods metadata:");
        LOG_INFO("Device Name: " << m_deviceInfo->deviceName());
        LOG_INFO("Model Number: " << m_deviceInfo->modelNumber());
        LOG_INFO("Manufacturer: " << m_deviceInfo->manufacturer());
    }

    QString getEarStatus(char value)
    {
        return (value == 0x00) ? "In Ear" : (value == 0x01) ? "Out of Ear"
                                                            : "In case";
    }

    void connectToDevice(const QBluetoothDeviceInfo &device)
    {
        // BlueZ can announce the same connection more than once; an attempt that is
        // already under way must not be torn down and started over.
        if (socket && m_socketAddress == device.address() && socket->isBusy())
        {
            LOG_INFO("Already connected or connecting to the device: " << device.name());
            return;
        }

        LOG_INFO("Connecting to device: " << device.name());

        m_reconnectTimer->stop();
        dropSocket();

        AapSocket *localSocket = new AapSocket(this);
        socket = localSocket;
        m_socketAddress = device.address();
        m_deviceInfo->setBluetoothAddress(device.address().toString());

        connect(localSocket, &AapSocket::connected, this, [this, localSocket]()
        {
            if (localSocket != socket)
            {
                return;
            }
            m_retryCount = 0;
            sendHandshake();
            emit airPodsStatusChanged();
        });

        connect(localSocket, &AapSocket::packet, this, [this, localSocket](const QByteArray &data)
        {
            if (localSocket != socket)
            {
                return;
            }
            parseData(data);
            relayPacketToPhone(data);
        });

        connect(localSocket, &AapSocket::disconnected, this, [this, device, localSocket]()
        {
            if (localSocket != socket)
            {
                return;
            }
            LOG_WARN("AirPods control connection closed");
            emit airPodsStatusChanged();
            scheduleReconnect(device);
        });

        connect(localSocket, &AapSocket::failed, this, [this, device, localSocket](int error)
        {
            if (localSocket != socket)
            {
                return;
            }
            LOG_ERROR("Control connection failed: " << strerror(error));
            emit airPodsStatusChanged();
            scheduleReconnect(device);
        });

        if (!localSocket->connectTo(device.address()))
        {
            LOG_ERROR("Control connection could not be started: " << strerror(localSocket->lastError()));
            scheduleReconnect(device);
        }
        notifyAndroidDevice();
    }

    void parseData(const QByteArray &data)
    {
        LOG_DEBUG("Received: " << data.toHex());

        if (data.startsWith(AirPodsPackets::Parse::HANDSHAKE_ACK))
        {
            writePacketToSocket(AirPodsPackets::Connection::SET_SPECIFIC_FEATURES, "Set specific features packet written: ");
        }
        else if (data.startsWith(AirPodsPackets::Parse::FEATURES_ACK))
        {
            writePacketToSocket(AirPodsPackets::Connection::REQUEST_NOTIFICATIONS, "Request notifications packet written: ");

            QTimer::singleShot(2000, this, [this]() {
                if (areAirpodsConnected() && m_deviceInfo->batteryStatus().isEmpty()) {
                    writePacketToSocket(AirPodsPackets::Connection::REQUEST_NOTIFICATIONS, "Request notifications packet written: ");
                }
            });
        }
        // Magic Cloud Keys Response
        else if (data.startsWith(AirPodsPackets::MagicPairing::MAGIC_CLOUD_KEYS_HEADER))
        {
            auto keys = AirPodsPackets::MagicPairing::parseMagicCloudKeysPacket(data);
            LOG_INFO("Received Magic Cloud Keys:");
            LOG_INFO("MagicAccIRK: " << keys.magicAccIRK.toHex());
            LOG_INFO("MagicAccEncKey: " << keys.magicAccEncKey.toHex());

            // Store the keys
            m_deviceInfo->setMagicAccIRK(keys.magicAccIRK);
            m_deviceInfo->setMagicAccEncKey(keys.magicAccEncKey);
            m_deviceInfo->saveToSettings(*m_settings);
        }
        // Get CA state
        else if (data.startsWith(AirPodsPackets::ConversationalAwareness::HEADER)) {
            if (auto result = AirPodsPackets::ConversationalAwareness::parseState(data))
            {
                m_deviceInfo->setConversationalAwareness(result.value());
                LOG_INFO("Conversational awareness state received: " << m_deviceInfo->conversationalAwareness());
            }
        }
        // Hearing Aid state
        else if (data.startsWith(AirPodsPackets::HearingAid::HEADER)) {
            if (auto result = AirPodsPackets::HearingAid::parseState(data))
            {
                m_deviceInfo->setHearingAidEnabled(result.value());
                LOG_INFO("Hearing aid state received: " << m_deviceInfo->hearingAidEnabled());
            }
        }
        // Noise Control Mode
        else if (data.size() == 11 && data.startsWith(AirPodsPackets::NoiseControl::HEADER))
        {
            if (auto value = AirPodsPackets::NoiseControl::parseMode(data))
            {
                m_deviceInfo->setNoiseControlMode(value.value());
                LOG_INFO("Noise control mode received: " << m_deviceInfo->noiseControlMode());
            }
        }
        // Ear Detection
        else if (data.size() == 8 && data.startsWith(AirPodsPackets::Parse::EAR_DETECTION))
        {
            m_deviceInfo->getEarDetection()->parseData(data);
            mediaController->handleEarDetection(m_deviceInfo->getEarDetection());
        }
        // Battery Status
        else if ((data.size() == 22 || data.size() == 12) && data.startsWith(AirPodsPackets::Parse::BATTERY_STATUS))
        {
            m_deviceInfo->getBattery()->parsePacket(data);
            m_deviceInfo->updateBatteryStatus();
            LOG_INFO("Battery status: " << m_deviceInfo->batteryStatus());
        }
        // Conversational Awareness Data
        else if (data.size() == 10 && data.startsWith(AirPodsPackets::ConversationalAwareness::DATA_HEADER))
        {
            LOG_INFO("Received conversational awareness data");
            mediaController->handleConversationalAwareness(data);
        }
        else if (data.startsWith(AirPodsPackets::Parse::METADATA))
        {
            parseMetadata(data);
            m_settings->setValue("DeviceInfo/address", m_deviceInfo->bluetoothAddress());
            initiateMagicPairing();
            mediaController->setConnectedDeviceMacAddress(m_deviceInfo->bluetoothAddress().replace(":", "_"));
            if (m_deviceInfo->getEarDetection()->oneOrMorePodsInEar()) // AirPods get added as output device only after this
            {
                mediaController->activateA2dpProfile();
            }
            m_bleManager->stopScan();
            emit airPodsStatusChanged();
        }
        else if (data.startsWith(AirPodsPackets::OneBudANCMode::HEADER)) {
            if (auto value = AirPodsPackets::OneBudANCMode::parseState(data))
            {
                m_deviceInfo->setOneBudANCMode(value.value());
                LOG_INFO("One Bud ANC mode received: " << m_deviceInfo->oneBudANCMode());
            }
        }
        else
        {
            LOG_DEBUG("Unrecognized packet format: " << data.toHex());
        }
    }

    void connectToPhone() {
        if (!CrossDevice.isEnabled) {
            return;
        }

        if (phoneSocket && phoneSocket->isOpen()) {
            LOG_INFO("Already connected to the phone");
            return;
        }
        QBluetoothAddress phoneAddress("00:00:00:00:00:00"); // Default address, will be overwritten if PHONE_MAC_ADDRESS is set
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();

        if (!env.value("PHONE_MAC_ADDRESS").isEmpty())
        {
            phoneAddress = QBluetoothAddress(env.value("PHONE_MAC_ADDRESS"));
        }
        phoneSocket = new QBluetoothSocket(QBluetoothServiceInfo::L2capProtocol);
        connect(phoneSocket, &QBluetoothSocket::connected, this, [this]() {
            LOG_INFO("Connected to phone");
            if (!lastBatteryStatus.isEmpty()) {
                phoneSocket->write(lastBatteryStatus);
                LOG_DEBUG("Sent last battery status to phone: " << lastBatteryStatus.toHex());
            }
            if (!lastEarDetectionStatus.isEmpty()) {
                phoneSocket->write(lastEarDetectionStatus);
                LOG_DEBUG("Sent last ear detection status to phone: " << lastEarDetectionStatus.toHex());
            }
        });

        connect(phoneSocket, QOverload<QBluetoothSocket::SocketError>::of(&QBluetoothSocket::errorOccurred), this, [this](QBluetoothSocket::SocketError error) {
            LOG_ERROR("Phone socket error: " << error << ", " << phoneSocket->errorString());
        });

        phoneSocket->connectToService(phoneAddress, QBluetoothUuid("1abbb9a4-10e4-4000-a75c-8953c5471342"));
    }

    void relayPacketToPhone(const QByteArray &packet)
    {
        if (!CrossDevice.isEnabled) {
            return;
        }
        if (phoneSocket && phoneSocket->isOpen())
        {
            phoneSocket->write(AirPodsPackets::Phone::NOTIFICATION + packet);
        }
        else
        {
            connectToPhone();
            LOG_WARN("Phone socket is not open, cannot relay packet");
        }
    }

    void handlePhonePacket(const QByteArray &packet) {
        if (packet.startsWith(AirPodsPackets::Phone::NOTIFICATION))
        {
            QByteArray airpodsPacket = packet.mid(4);
            if (socket && socket->isOpen()) {
                socket->write(airpodsPacket);
                LOG_DEBUG("Relayed packet to AirPods: " << airpodsPacket.toHex());
            } else {
                LOG_ERROR("Socket is not open, cannot relay packet to AirPods");
            }
        }
        else if (packet.startsWith(AirPodsPackets::Phone::CONNECTED))
        {
            LOG_INFO("AirPods connected");
            isConnectedLocally = true;
            CrossDevice.isAvailable = false;
        }
        else if (packet.startsWith(AirPodsPackets::Phone::DISCONNECTED))
        {
            LOG_INFO("AirPods disconnected");
            isConnectedLocally = false;
            CrossDevice.isAvailable = true;
        }
        else if (packet.startsWith(AirPodsPackets::Phone::STATUS_REQUEST))
        {
            LOG_INFO("Connection status request received");
            QByteArray response = (socket && socket->isOpen()) ? AirPodsPackets::Phone::CONNECTED
                                                               : AirPodsPackets::Phone::DISCONNECTED;
            phoneSocket->write(response);
            LOG_DEBUG("Sent connection status response: " << response.toHex());
        }
        else if (packet.startsWith(AirPodsPackets::Phone::DISCONNECT_REQUEST))
        {
            LOG_INFO("Disconnect request received");
            if (socket && socket->isOpen()) {
                socket->close();
                LOG_INFO("Disconnected from AirPods");
                QProcess process;
                process.start("bluetoothctl", QStringList() << "disconnect" << m_deviceInfo->bluetoothAddress());
                process.waitForFinished();
                QString output = process.readAllStandardOutput().trimmed();
                LOG_INFO("Bluetoothctl output: " << output);
                isConnectedLocally = false;
                CrossDevice.isAvailable = true;
            }
        }
        else
        {
            if (socket && socket->isOpen()) {
                socket->write(packet);
                LOG_DEBUG("Relayed packet to AirPods: " << packet.toHex());
            } else {
                LOG_ERROR("Socket is not open, cannot relay packet to AirPods");
            }
        }
    }

    void onPhoneDataReceived() {
        QByteArray data = phoneSocket->readAll();
        LOG_DEBUG("Data received from phone: " << data.toHex());
        QMetaObject::invokeMethod(this, "handlePhonePacket", Qt::QueuedConnection, Q_ARG(QByteArray, data));
    }

    void bleDeviceFound(const BleInfo &device)
    {
        if (BLEUtils::isValidIrkRpa(m_deviceInfo->magicAccIRK(), device.address)) {
            // an advertisement with a model id we do not know must not erase the known model
            if (device.modelName != AirPodsModel::Unknown)
                m_deviceInfo->setModel(device.modelName);
            auto decryptet = BLEUtils::decryptLastBytes(device.encryptedPayload, m_deviceInfo->magicAccEncKey());
            m_deviceInfo->getBattery()->parseEncryptedPacket(decryptet, device.primaryLeft, device.isThisPodInTheCase, isModelHeadset(m_deviceInfo->model()));
            m_deviceInfo->getEarDetection()->overrideEarDetectionStatus(device.isPrimaryInEar, device.isSecondaryInEar);
            maybeAutoConnect(device);
        }
    }

    // Connect when the lid of our case is opened, like an iPhone does.
    void maybeAutoConnect(const BleInfo &device)
    {
        // only the case's own advertisement carries the lid state
        if (!device.isThisPodInTheCase || device.lidState == BleInfo::LidState::UNKNOWN)
        {
            return;
        }

        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        const bool open = device.lidState == BleInfo::LidState::OPEN;
        if (open != m_lidOpen || now - m_lidSeenAt > 8000)
        {
            LOG_INFO("Case lid " << (open ? "open" : "closed") << ", AirPods state "
                     << static_cast<int>(device.connectionState));
        }
        // a closed case stops advertising, so a long silence counts as "was closed"
        const bool opened = open && (!m_lidOpen || now - m_lidSeenAt > 8000);
        m_lidOpen = open;
        m_lidSeenAt = now;

        // AirPods that sit in an open case and are connected to nothing can be taken at
        // any time, not only at the moment the lid opens. Without this a case that was
        // closed and opened again shortly after a disconnect was never noticed.
        const bool freeToTake = open && device.connectionState == BleInfo::ConnectionState::DISCONNECTED
                                && now >= m_freeConnectHoldUntil;
        if (freeToTake && !opened)
        {
            LOG_INFO("Case is open and the AirPods are not connected anywhere");
        }
        if (!freeToTake && (!opened || now < m_autoConnectHoldUntil))
        {
            return;
        }
        if (socket && socket->isBusy())
        {
            return;
        }
        using State = BleInfo::ConnectionState;
        if (device.connectionState == State::MUSIC || device.connectionState == State::CALL ||
            device.connectionState == State::RINGING || device.connectionState == State::HANGING_UP)
        {
            LOG_INFO("Case opened, but the AirPods are in use on another device; not connecting");
            return;
        }

        m_autoConnectHoldUntil = now + 10000;
        m_freeConnectHoldUntil = now + 10000;
        m_autoConnectAttempts = 1;
        if (monitor->connectAirPods(m_settings->value("DeviceInfo/address").toString()))
        {
            LOG_INFO("Case opened, connecting to the AirPods");
        }
    }

    // The AirPods often do not answer the first call (they are busy greeting the phone
    // when the lid opens). Keep trying for as long as the lid stays open.
    void onAutoConnectFailed(const QString &reason)
    {
        if (m_autoConnectAttempts == 0)
        {
            return; // not an attempt of ours
        }
        LOG_WARN("Connecting to the AirPods failed: " << reason);
        if (m_autoConnectAttempts >= 5)
        {
            m_autoConnectAttempts = 0;
            return;
        }
        QTimer::singleShot(1000, this, [this]() {
            const qint64 now = QDateTime::currentMSecsSinceEpoch();
            const bool lidStillOpen = m_lidOpen && now - m_lidSeenAt < 15000;
            if (m_autoConnectAttempts == 0 || !lidStillOpen || (socket && socket->isBusy()))
            {
                m_autoConnectAttempts = 0;
                return;
            }
            ++m_autoConnectAttempts;
            m_autoConnectHoldUntil = now + 10000;
            m_freeConnectHoldUntil = now + 10000;
            if (monitor->connectAirPods(m_settings->value("DeviceInfo/address").toString()))
            {
                LOG_INFO("Trying again (attempt " << m_autoConnectAttempts << ")");
            }
            else
            {
                m_autoConnectAttempts = 0; // already connected, or nothing to connect to
            }
        });
    }

public:
    void handleMediaStateChange(MediaController::MediaState state) {
        // Taking the AirPods over when playback starts belongs to the phone hand-off
        // feature; without it this only spawned a blocking bluetoothctl on every "play".
        if (state == MediaController::MediaState::Playing && CrossDevice.isEnabled) {
            LOG_INFO("Media started playing, sending disconnect request to Android and taking over audio");
            sendDisconnectRequestToAndroid();
            connectToAirPods(true);
        }
    }

    void sendDisconnectRequestToAndroid()
    {
        if (!CrossDevice.isEnabled) return;

        if (phoneSocket && phoneSocket->isOpen())
        {
            phoneSocket->write(AirPodsPackets::Phone::DISCONNECT_REQUEST);
            LOG_DEBUG("Sent disconnect request to Android: " << AirPodsPackets::Phone::DISCONNECT_REQUEST.toHex());
        }
        else
        {
            LOG_WARN("Phone socket is not open, cannot send disconnect request");
        }
    }

    bool isPhoneConnected() {
        return phoneSocket && phoneSocket->isOpen();
    }

    void connectToAirPods(bool force) {
        if (socket && socket->isBusy()) {
            LOG_INFO("Already connected to AirPods");
            return;
        }

        const QString address = m_deviceInfo->bluetoothAddress();
        if (force && !address.isEmpty()) {
            LOG_INFO("Forcing connection to AirPods");
            // BlueZ reports the result through the monitor; never wait for it here.
            QProcess::startDetached("bluetoothctl", QStringList() << "connect" << address);
            return;
        }
        if (!monitor->checkAlreadyConnectedDevices()) {
            LOG_WARN("AirPods not found among connected devices");
        }
    }

    void initializeBluetooth() {
        connectToPhone();

        m_deviceInfo->loadFromSettings(*m_settings);
        if (!areAirpodsConnected()) {
            m_bleManager->startScan();
        }
    }

    void loadMainModule() {
        parent->load(QUrl(QStringLiteral("qrc:/linux/Main.qml")));
    }

signals:
    void noiseControlModeChanged(NoiseControlMode mode);
    void earDetectionStatusChanged(const QString &status);
    void batteryStatusChanged(const QString &status);
    void conversationalAwarenessChanged(bool enabled);
    void adaptiveNoiseLevelChanged(int level);
    void deviceNameChanged(const QString &name);
    void modelChanged();
    void primaryChanged();
    void airPodsStatusChanged();
    void earDetectionBehaviorChanged(int behavior);
    void crossDeviceEnabledChanged(bool enabled);
    void notificationsEnabledChanged(bool enabled);
    void retryAttemptsChanged(int attempts);
    void oneBudANCModeChanged(bool enabled);
    void phoneMacStatusChanged();
    void hearingAidEnabledChanged(bool enabled);

private:
    AapSocket *socket = nullptr;
    QBluetoothSocket *phoneSocket = nullptr;
    QByteArray lastBatteryStatus;
    QByteArray lastEarDetectionStatus;
    MediaController* mediaController;
    TrayIconManager *trayManager;
    BluetoothMonitor *monitor;
    QSettings *m_settings;
    AutoStartManager *m_autoStartManager;
    int m_retryAttempts = 3;
    bool m_hideOnStart = false;
    DeviceInfo *m_deviceInfo;
    BleManager *m_bleManager;
    SystemSleepMonitor *m_systemSleepMonitor = nullptr;
    QString m_phoneMacStatus;
    QTimer *m_reconnectTimer = nullptr;
    int m_retryCount = 0;
    QBluetoothDeviceInfo m_reconnectDevice;
    QBluetoothAddress m_socketAddress;
    bool m_lidOpen = false;
    qint64 m_lidSeenAt = 0;
    qint64 m_autoConnectHoldUntil = 0;
    qint64 m_freeConnectHoldUntil = 0;
    int m_autoConnectAttempts = 0;
};

// SIGTERM/SIGINT (logout, pkill) must end the event loop normally: only a clean exit
// lets Qt write its shader caches, which makes the 3D view appear instantly next time.
static int g_quitFd[2] = {-1, -1};
static void quitSignalHandler(int)
{
    const char c = 1;
    ssize_t r = ::write(g_quitFd[0], &c, 1);
    (void)r;
}

int main(int argc, char *argv[]) {
    // Glass UI draws its own controls; use the plain Basic style as a base.
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    QApplication app(argc, argv);

    // Load translations
    QTranslator *translator = new QTranslator(&app);
    QString locale = QLocale::system().name();

    // Try to load translation from various locations
    QStringList translationPaths = {
        QCoreApplication::applicationDirPath() + "/translations",
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/riaspods/translations",
        "/usr/share/riaspods/translations",
        "/usr/local/share/riaspods/translations"
    };

    for (const QString &path : translationPaths) {
        if (translator->load("librepods_" + locale, path)) {
            app.installTranslator(translator);
            break;
        }
    }

    // Look for a running instance first. (Removing the server socket before this check
    // made every second launch start a duplicate instead of reopening the window.)
    QLocalSocket socket_check;
    socket_check.connectToServer("riaspods");

    if (socket_check.waitForConnected(300)) {
        LOG_INFO("Another instance already running! Reopening window...");

        socket_check.write("reopen");
        socket_check.flush();
        socket_check.waitForBytesWritten(200);
        socket_check.disconnectFromServer();

        return 0;
    }
    if (::socketpair(AF_UNIX, SOCK_STREAM, 0, g_quitFd) == 0) {
        auto *quitNotifier = new QSocketNotifier(g_quitFd[1], QSocketNotifier::Read, &app);
        QObject::connect(quitNotifier, &QSocketNotifier::activated, &app, [quitNotifier]() {
            quitNotifier->setEnabled(false);
            QCoreApplication::quit();
        });
        std::signal(SIGTERM, quitSignalHandler);
        std::signal(SIGINT, quitSignalHandler);
    }
    app.setDesktopFileName("riaspods");
    app.setQuitOnLastWindowClosed(false);

    bool debugMode = false;
    bool hideOnStart = false;
    for (int i = 1; i < argc; ++i) {
        if (QString(argv[i]) == "--debug")
            debugMode = true;

        if (QString(argv[i]) == "--hide")
            hideOnStart = true;
    }

    // Settings written under the app's former name (pairing keys, preferences) move along.
    {
        const QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
        const QString current = configDir + "/RiasPods/RiasPods.conf";
        const QString former = configDir + "/AirPodsTrayApp/AirPodsTrayApp.conf";
        if (!QFile::exists(current) && QFile::exists(former))
        {
            QDir().mkpath(configDir + "/RiasPods");
            QFile::copy(former, current);
        }
    }

    QQmlApplicationEngine engine;
    qmlRegisterType<Battery>("me.kavishdevar.Battery", 1, 0, "Battery");
    qmlRegisterType<DeviceInfo>("me.kavishdevar.DeviceInfo", 1, 0, "DeviceInfo");
    AirPodsTrayApp *trayApp = new AirPodsTrayApp(debugMode, hideOnStart, &engine);
    engine.rootContext()->setContextProperty("airPodsTrayApp", trayApp);

    // Expose PHONE_MAC_ADDRESS environment variable to QML for placeholder in settings
    {
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        QString phoneMacEnv = env.value("PHONE_MAC_ADDRESS", "");
        engine.rootContext()->setContextProperty("PHONE_MAC_ADDRESS", phoneMacEnv);
        // Initialize the visible status in the GUI
        trayApp->updatePhoneMacStatus(phoneMacEnv.isEmpty() ? QStringLiteral("No phone MAC set") : phoneMacEnv);
    }

    engine.addImageProvider("qrcode", new QRCodeImageProvider());
    trayApp->loadMainModule();

    QLocalServer server;
    QLocalServer::removeServer("riaspods");

    if (!server.listen("riaspods"))
    {
        LOG_ERROR("Unable to start the listening server");
        LOG_DEBUG("Server error: " << server.errorString());
    }
    else
    {
        LOG_DEBUG("Server started, waiting for connections...");
    }
    QObject::connect(&server, &QLocalServer::newConnection, [&]() {
        QLocalSocket* socket = server.nextPendingConnection();
        // Handles Proper Connection
        QObject::connect(socket, &QLocalSocket::readyRead, [socket, &engine, &trayApp]() {
            QString msg = socket->readAll();
            // Check if the message is "reopen", if so, trigger onOpenApp function
            if (msg == "reopen") {
                LOG_INFO("Reopening app window");
                QObject *rootObject = engine.rootObjects().first();
                if (rootObject) {
                    QMetaObject::invokeMethod(rootObject, "reopen", Q_ARG(QVariant, "app"));
                }
                else
                {
                    trayApp->loadMainModule();
                }
            }
            else if (msg == "noise:off") {
                trayApp->setNoiseControlModeInt(0);
            }
            else if (msg == "noise:anc") {
                trayApp->setNoiseControlModeInt(1);
            }
            else if (msg == "noise:transparency") {
                trayApp->setNoiseControlModeInt(2);
            }
            else if (msg == "noise:adaptive") {
                trayApp->setNoiseControlModeInt(3);
            }
            else
            {
                LOG_ERROR("Unknown message received: " << msg);
            }
            socket->disconnectFromServer();
        });
        // Handles connection errors
        QObject::connect(socket, &QLocalSocket::errorOccurred, [socket]() {
            LOG_ERROR("Failed to connect to the duplicate app instance");
            LOG_DEBUG("Connection error: " << socket->errorString());
        });

        // Handle server-level errors
        QObject::connect(&server, &QLocalServer::serverError, [&]() {
            LOG_ERROR("Server failed to accept a new connection");
            LOG_DEBUG("Server error: " << server.errorString());
        });
    });

    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&]() {
        LOG_DEBUG("Application quitting. Cleaning up local server...");

        if (server.isListening()) {
            server.close();
        }

        QLocalServer::removeServer("riaspods");
        QFile stale("/tmp/riaspods");
        if (stale.exists())
            stale.remove();
    });
    return app.exec();
}

#include "main.moc"
