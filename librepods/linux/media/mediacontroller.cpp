#include "mediacontroller.h"
#include "logger.h"
#include "eardetection.hpp"
#include "playerstatuswatcher.h"
#include "pulseaudiocontroller.h"

#include <QDebug>
#include <QProcess>
#include <QThread>
#include <QTimer>
#include <QRegularExpression>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>

MediaController::MediaController(QObject *parent) : QObject(parent) {
  m_pulseAudio = new PulseAudioController(this);
  if (!m_pulseAudio->initialize())
  {
    LOG_ERROR("Failed to initialize PulseAudio controller");
  }

  // One timer for the A2DP retries, so activating again while a retry is pending
  // restarts that retry instead of starting a second chain beside it.
  m_retryTimer = new QTimer(this);
  m_retryTimer->setSingleShot(true);
  m_retryTimer->setInterval(1500);
  connect(m_retryTimer, &QTimer::timeout, this, &MediaController::tryActivateA2dp);
}

void MediaController::handleEarDetection(EarDetection *earDetection)
{
  if (earDetectionBehavior == Disabled)
  {
    LOG_DEBUG("Ear detection is disabled, ignoring status");
    return;
  }

  // Count buds instead of comparing "primary" and "secondary": with a single bud in use
  // (the other one in the case) the old "both must be in ear" test paused on every packet.
  const int inEar = (earDetection->isPrimaryInEar() ? 1 : 0) + (earDetection->isSecondaryInEar() ? 1 : 0);
  const int before = m_lastInEarCount;
  m_lastInEarCount = inEar;

  LOG_DEBUG("Ear detection: in ear " << before << " -> " << inEar);

  bool shouldPause = false;
  bool shouldResume = false;
  if (before >= 0)
  {
    if (earDetectionBehavior == PauseWhenOneRemoved)
    {
      shouldPause = inEar < before;
      shouldResume = inEar > before;
    }
    else if (earDetectionBehavior == PauseWhenBothRemoved)
    {
      shouldPause = before > 0 && inEar == 0;
      shouldResume = before == 0 && inEar > 0;
    }
  }

  if (shouldPause && isActiveOutputDeviceAirPods() && getCurrentMediaState() == Playing)
  {
    LOG_DEBUG("Pausing playback for ear detection");
    pause();
  }

  if (inEar > 0)
  {
    if (before <= 0) LOG_INFO("At least one AirPod is in ear");
    activateA2dpProfile();

    if (shouldResume && !pausedByAppServices.isEmpty())
    {
      // the sink needs a moment to come back after the profile is switched on again
      QTimer::singleShot(isActiveOutputDeviceAirPods() ? 0 : 1200, this, [this]() {
        if (m_lastInEarCount > 0 && !pausedByAppServices.isEmpty() && isActiveOutputDeviceAirPods())
          play();
      });
    }
  }
  else if (before != 0)
  {
    // The audio card stays on: switching it to "off" here took the AirPods out of the
    // system's output list whenever they were not worn (case open, on the desk).
    LOG_INFO("Both AirPods are out of ear");
  }
}

void MediaController::setEarDetectionBehavior(EarDetectionBehavior behavior)
{
  earDetectionBehavior = behavior;
  LOG_INFO("Set ear detection behavior to: " << behavior);
}

void MediaController::followMediaChanges() {
  playerStatusWatcher = new PlayerStatusWatcher("", this);
  connect(playerStatusWatcher, &PlayerStatusWatcher::playbackStatusChanged,
          this, [this](const QString &status)
          {
            LOG_DEBUG("Playback status changed: " << status);
            MediaState state = mediaStateFromPlayerctlOutput(status);
            emit mediaStateChanged(state);
          });
}

bool MediaController::isActiveOutputDeviceAirPods() {
  if (connectedDeviceMacAddress.isEmpty()) return false; // contains("") is always true
  QString defaultSink = m_pulseAudio->getDefaultSink();
  LOG_DEBUG("Default sink: " << defaultSink);
  return defaultSink.contains(connectedDeviceMacAddress);
}

void MediaController::handleConversationalAwareness(const QByteArray &data) {
    if (data.size() < 10) {
        LOG_ERROR("Invalid conversational awareness packet");
        return;
    }

    uint8_t flag = (uint8_t)data[9];

    switch (flag) {
    case 0x01:
        LOG_INFO("Conversational awareness event: voice detected");

        if (initialVolume == -1 && isActiveOutputDeviceAirPods()) {
            QString sink = m_pulseAudio->getDefaultSink();
            initialVolume = m_pulseAudio->getSinkVolume(sink);
            LOG_DEBUG("Initial volume saved: " << initialVolume << "%");
        }

        if (initialVolume != -1) {
            QString sink = m_pulseAudio->getDefaultSink();
            int target = initialVolume * 0.20;
            m_pulseAudio->setSinkVolume(sink, target);
            LOG_INFO("Volume lowered to " << target << "%");
        }
        break;

    case 0x08:
        LOG_INFO("Conversational awareness disabled");
        initialVolume = -1;
        break;

    case 0x09:
        LOG_INFO("Conversational awareness enabled");
        break;

    default:
        LOG_INFO("Conversational awareness event: voice ended");

        if (initialVolume != -1 && isActiveOutputDeviceAirPods()) {
            QString sink = m_pulseAudio->getDefaultSink();
            m_pulseAudio->setSinkVolume(sink, initialVolume);
            LOG_INFO("Volume restored to " << initialVolume << "%");
            initialVolume = -1;
        }
        break;
    }
}


bool MediaController::isA2dpProfileAvailable() {
  return !getPreferredA2dpProfile().isEmpty();
}

QString MediaController::getPreferredA2dpProfile() {
  if (m_deviceOutputName.isEmpty()) {
    return QString();
  }

  // "a2dp-sink" is the codec the audio server itself prefers (AAC on AirPods);
  // the SBC variants are only fallbacks.
  static const QStringList profiles = {"a2dp-sink", "a2dp-sink-sbc_xq", "a2dp-sink-sbc"};
  for (const QString &profile : profiles) {
    if (m_pulseAudio->isProfileAvailable(m_deviceOutputName, profile)) {
      return profile;
    }
  }
  return QString();
}

void MediaController::activateA2dpProfile() {
  m_retryTimer->stop();
  m_wantA2dp = true;
  m_a2dpRetries = 0;
  m_a2dpReconnectTried = false;
  tryActivateA2dp();
}

void MediaController::tryActivateA2dp() {
  if (!m_wantA2dp || connectedDeviceMacAddress.isEmpty()) {
    return;
  }

  // The audio card shows up a moment after the Bluetooth link and disappears with it,
  // so it is looked up every time instead of trusting a stored name.
  m_deviceOutputName = m_pulseAudio->getCardNameForDevice(connectedDeviceMacAddress);
  const QString profile = getPreferredA2dpProfile();
  if (profile.isEmpty()) {
    // Not there yet: wait for it. (This used to restart WirePlumber, which cut the audio
    // of every application and froze the window for seconds.)
    if (m_a2dpRetries < 8) {
      ++m_a2dpRetries;
      m_retryTimer->start();
    } else if (!m_a2dpReconnectTried) {
      // The Bluetooth link is up but the audio card is gone: the A2DP stream failed and
      // nothing brings it back on its own. Ask BlueZ to connect the profile again.
      m_a2dpReconnectTried = true;
      m_a2dpRetries = 0;
      reconnectA2dp();
      m_retryTimer->start();
    } else {
      LOG_WARN("A2DP profile did not become available for the AirPods");
    }
    return;
  }
  m_a2dpRetries = 0;

  // Only bring the card back when it is switched off; a profile that is already active
  // (music, or the headset profile during a call) is left alone.
  const QString active = m_pulseAudio->getActiveProfile(m_deviceOutputName);
  if (!active.isEmpty() && active != "off") {
    return;
  }

  LOG_INFO("Activating A2DP profile for AirPods: " << profile);
  if (!m_pulseAudio->setCardProfile(m_deviceOutputName, profile)) {
    LOG_ERROR("Failed to activate A2DP profile: " << profile);
  }
}

void MediaController::reconnectA2dp() {
  if (connectedDeviceMacAddress.isEmpty()) {
    return;
  }
  QString path = "/org/bluez/hci0/dev_" + connectedDeviceMacAddress.toUpper();
  path.replace(':', '_');
  LOG_INFO("A2DP audio missing, asking BlueZ to reconnect it");
  QDBusMessage msg = QDBusMessage::createMethodCall("org.bluez", path, "org.bluez.Device1", "ConnectProfile");
  msg << QStringLiteral("0000110b-0000-1000-8000-00805f9b34fb"); // A2DP sink
  QDBusConnection::systemBus().asyncCall(msg, 20000);
}

void MediaController::setConnectedDeviceMacAddress(const QString &macAddress) {
  connectedDeviceMacAddress = macAddress;
  m_deviceOutputName = m_pulseAudio->getCardNameForDevice(connectedDeviceMacAddress);
  LOG_DEBUG("Device output name set to: " << m_deviceOutputName);
}

void MediaController::clearConnectedDevice() {
  connectedDeviceMacAddress.clear();
  m_deviceOutputName.clear();
  m_wantA2dp = false;
  m_a2dpRetries = 0;
  m_a2dpReconnectTried = false;
  m_retryTimer->stop();
  m_lastInEarCount = -1;
  initialVolume = -1;
}

MediaController::MediaState MediaController::mediaStateFromPlayerctlOutput(
    const QString &output) const {
  if (output == "Playing") {
    return MediaState::Playing;
  } else if (output == "Paused") {
    return MediaState::Paused;
  } else {
    return MediaState::Stopped;
  }
}

MediaController::MediaState MediaController::getCurrentMediaState() const
{
  return mediaStateFromPlayerctlOutput(PlayerStatusWatcher::getCurrentPlaybackStatus(""));
}

QStringList MediaController::getPlayingMediaPlayers()
{
  QStringList playingServices;
  QDBusConnection bus = QDBusConnection::sessionBus();

  QStringList services = bus.interface()->registeredServiceNames().value();
  for (const QString &service : services)
  {
    if (!service.startsWith("org.mpris.MediaPlayer2."))
    {
      continue;
    }

    QDBusInterface playerInterface(
        service,
        "/org/mpris/MediaPlayer2",
        "org.mpris.MediaPlayer2.Player",
        bus);

    if (!playerInterface.isValid())
    {
      continue;
    }

    QVariant playbackStatus = playerInterface.property("PlaybackStatus");
    if (playbackStatus.isValid() && playbackStatus.toString() == "Playing")
    {
      playingServices << service;
      LOG_DEBUG("Found playing service: " << service);
    }
  }

  return playingServices;
}

void MediaController::play()
{
  if (pausedByAppServices.isEmpty())
  {
    LOG_INFO("No services to resume");
    return;
  }

  QDBusConnection bus = QDBusConnection::sessionBus();
  int resumedCount = 0;

  for (const QString &service : pausedByAppServices)
  {
    QDBusInterface playerInterface(
        service,
        "/org/mpris/MediaPlayer2",
        "org.mpris.MediaPlayer2.Player",
        bus);

    if (!playerInterface.isValid())
    {
      LOG_WARN("Service no longer available: " << service);
      continue;
    }

    QDBusReply<void> reply = playerInterface.call("Play");
    if (reply.isValid())
    {
      LOG_INFO("Resumed playback for: " << service);
      resumedCount++;
    }
    else
    {
      LOG_ERROR("Failed to resume " << service << ": " << reply.error().message());
    }
  }

  if (resumedCount > 0)
  {
    LOG_INFO("Resumed " << resumedCount << " media player(s) via DBus");
    pausedByAppServices.clear();
  }
  else
  {
    LOG_ERROR("Failed to resume any media players via DBus");
  }
}

void MediaController::pause()
{
  QDBusConnection bus = QDBusConnection::sessionBus();
  QStringList services = bus.interface()->registeredServiceNames().value();

  pausedByAppServices.clear();
  int pausedCount = 0;

  for (const QString &service : services)
  {
    if (!service.startsWith("org.mpris.MediaPlayer2."))
    {
      continue;
    }

    QDBusInterface playerInterface(
        service,
        "/org/mpris/MediaPlayer2",
        "org.mpris.MediaPlayer2.Player",
        bus);

    if (!playerInterface.isValid())
    {
      continue;
    }

    QVariant playbackStatus = playerInterface.property("PlaybackStatus");
    LOG_DEBUG("PlaybackStatus for " << service << ": " << playbackStatus.toString());
    if (!playbackStatus.isValid() || playbackStatus.toString() != "Playing")
    {
      continue;
    }

    QDBusReply<void> reply = playerInterface.call("Pause");
    LOG_DEBUG("Pausing service: " << service);
    if (reply.isValid())
    {
      LOG_INFO("Paused playback for: " << service);
      pausedByAppServices << service;
      pausedCount++;
    }
    else
    {
      LOG_ERROR("Failed to pause " << service << ": " << reply.error().message());
    }
  }

  if (pausedCount > 0)
  {
    LOG_INFO("Paused " << pausedCount << " media player(s) via DBus");
  }
  else
  {
    LOG_INFO("No playing media players found to pause");
  }
}

MediaController::~MediaController() {
}
