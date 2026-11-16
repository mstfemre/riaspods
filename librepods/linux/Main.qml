pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWindow
    visible: !airPodsTrayApp.hideOnStart
    width: 460
    height: 676
    title: "RiasPods"
    objectName: "mainWindowObject"
    color: "transparent"

    signal replayRequested()
    property bool wasConnected: false

    background: GlassPanel {
        radius: Theme.windowRadius
        tint: Qt.rgba(16/255, 16/255, 24/255, 0.46)
        sheen: 0.18
    }

    onClosing: mainWindow.visible = false
    onVisibleChanged: if (visible) replayRequested()

    Shortcut { sequence: "Escape"; onActivated: if (stackView.depth > 1) stackView.pop(); else mainWindow.visible = false }

    ConnectPopup { id: connectPopup }

    // The connect card opens as soon as battery levels are known. They usually are already
    // (from the case's advertisement when its lid was opened); otherwise the first report
    // is awaited for a moment so the card does not open half empty.
    property bool popupPending: false
    function batteryKnown() {
        const b = airPodsTrayApp.deviceInfo.battery
        return (b.leftPodAvailable && b.leftPodLevel > 0) || (b.rightPodAvailable && b.rightPodLevel > 0)
            || (b.headsetAvailable && b.headsetLevel > 0)
    }
    function showPopupNow() {
        if (!popupPending) return
        popupPending = false
        popupFallback.stop()
        connectPopup.present()
        mainWindow.replayRequested()
    }
    Timer { id: popupFallback; interval: 1200; onTriggered: mainWindow.showPopupNow() }

    Connections {
        target: airPodsTrayApp
        function onAirPodsStatusChanged() {
            const now = airPodsTrayApp.airpodsConnected
            if (now && !mainWindow.wasConnected) {
                mainWindow.popupPending = true
                popupFallback.restart()
                if (mainWindow.batteryKnown()) mainWindow.showPopupNow()
            } else if (!now && mainWindow.wasConnected) {
                mainWindow.popupPending = false
                popupFallback.stop()
                connectPopup.dismiss()
            }
            mainWindow.wasConnected = now
        }
    }
    Connections {
        target: airPodsTrayApp.deviceInfo.battery
        function onBatteryStatusChanged() {
            const b = airPodsTrayApp.deviceInfo.battery
            if (mainWindow.popupPending && airPodsTrayApp.airpodsConnected && mainWindow.batteryKnown())
                mainWindow.showPopupNow()
        }
    }

    Component.onCompleted: {
        wasConnected = airPodsTrayApp.airpodsConnected
        if (Qt.application.arguments.indexOf("--popup-test") >= 0)
            connectPopup.present()
        if (Qt.application.arguments.indexOf("--settings-test") >= 0)
            stackView.push(settingsPage)
    }

    function reopen(pageToLoad) {
        if (pageToLoad == "settings") {
            if (stackView.depth == 1)
                stackView.push(settingsPage)
        } else {
            if (stackView.depth > 1)
                stackView.pop()
        }
        if (!mainWindow.visible)
            mainWindow.visible = true
        raise()
        requestActivate()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.BackButton && stackView.depth > 1)
                stackView.pop()
        }
    }

    FontLoader {
        id: iconFont
        source: "qrc:/icons/assets/fonts/SF-Symbols-6.ttf"
    }

    // ---------- shared building blocks ----------
    component SectionLabel: GlassText {
        color: Theme.secondary
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
    }

    component SettingRow: Item {
        id: row
        property string title: ""
        property string subtitle: ""
        property bool last: false
        default property alias trailing: slot.data
        width: parent ? parent.width : 0
        implicitHeight: row.subtitle !== "" ? 64 : 54
        height: implicitHeight

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: slot.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            GlassText { width: parent.width; text: row.title; font.pixelSize: 15; elide: Text.ElideRight }
            GlassText { width: parent.width; visible: row.subtitle !== ""; text: row.subtitle; color: Theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap }
        }
        Item {
            id: slot
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
        Rectangle {
            visible: !row.last
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: parent.right
            height: 1
            color: Theme.separator
        }
    }

    component GlassField: TextField {
        implicitHeight: 36
        leftPadding: 12
        rightPadding: 12
        color: Theme.label
        placeholderTextColor: Theme.tertiary
        selectionColor: Theme.blue
        font.family: Theme.family
        font.pixelSize: 14
        background: Rectangle {
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.25)
            border.width: 1
            border.color: parent.activeFocus ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.14)
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage

        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 46; to: 0; duration: 420; easing.type: Easing.OutCubic }
            }
        }
        pushExit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 220 }
                NumberAnimation { property: "x"; from: 0; to: -46; duration: 360; easing.type: Easing.OutCubic }
            }
        }
        popEnter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: -46; to: 0; duration: 420; easing.type: Easing.OutCubic }
            }
        }
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 220 }
                NumberAnimation { property: "x"; from: 0; to: 46; duration: 360; easing.type: Easing.OutCubic }
            }
        }
    }

    // ---------- main page ----------
    Component {
        id: mainPage
        Item {
            id: page
            property real t: 1.6   // intro timeline
            function sec(d) {
                const x = Math.max(0, Math.min(1, (page.t - d) / 0.6))
                return 1 - Math.pow(1 - x, 3)
            }
            function replay() {
                introAnim.stop()
                page.t = 0
                warmMain.ticks = 0
                warmMain.guard = 0
                warmMain.restart()
            }
            Timer {
                id: warmMain
                property int ticks: 0
                property int guard: 0
                interval: 50
                repeat: true
                onTriggered: {
                    ticks = showcase.ready ? ticks + 1 : 0
                    if (ticks >= 3 || ++guard > 30) { stop(); introAnim.restart(); showcase.play() }
                }
            }
            NumberAnimation { id: introAnim; target: page; property: "t"; from: 0; to: 1.8; duration: 1300 }
            Connections {
                target: mainWindow
                function onReplayRequested() { page.replay() }
            }
            Component.onCompleted: if (mainWindow.visible) page.replay()

            // header
            Item {
                id: header
                x: 26; y: 26
                width: parent.width - 52
                height: 56
                opacity: page.sec(0.0)
                transform: Translate { y: (1 - page.sec(0.0)) * 18 }

                Column {
                    anchors.left: parent.left
                    anchors.right: gear.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    GlassText {
                        width: parent.width
                        elide: Text.ElideRight
                        text: airPodsTrayApp.deviceInfo.deviceName !== "" ? airPodsTrayApp.deviceInfo.deviceName : "AirPods"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.5
                    }
                    Row {
                        spacing: 7
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: airPodsTrayApp.airpodsConnected ? Theme.green : Theme.red
                        }
                        GlassText {
                            text: airPodsTrayApp.airpodsConnected ? qsTr("Connected") : qsTr("Disconnected")
                            color: Theme.secondary
                            font.pixelSize: 14
                        }
                    }
                }
                GlassButton {
                    id: gear
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    round: true
                    iconFamily: iconFont.name
                    iconGlyph: "菱"
                    onClicked: stackView.push(settingsPage)
                }
            }

            PodsShowcase {
                id: showcase
                x: 26
                y: 90
                width: parent.width - 52
                height: implicitHeight
                info: airPodsTrayApp.deviceInfo
                active: mainWindow.visible && stackView.depth === 1
                turns: 1
                lingerMs: 60000
                // never fully 0: an invisible item is not drawn, and the 3D view must warm up
                opacity: Math.max(0.004, page.sec(0.1) * (airPodsTrayApp.airpodsConnected ? 1 : 0.45))
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            Column {
                id: controls
                x: 26
                y: 394
                width: parent.width - 52
                spacing: 12
                visible: airPodsTrayApp.airpodsConnected
                opacity: page.sec(0.9)
                transform: Translate { y: (1 - page.sec(0.9)) * 22 }

                SectionLabel { text: qsTr("Noise Control"); leftPadding: 6 }
                SegmentedControl {
                    width: parent.width
                    model: [qsTr("Off"), qsTr("Noise Cancel"), qsTr("Transparency"), qsTr("Adaptive")]
                    currentIndex: airPodsTrayApp.deviceInfo.noiseControlMode
                    onCurrentIndexChanged: airPodsTrayApp.setNoiseControlModeInt(currentIndex)
                }

                GlassPanel {
                    width: parent.width
                    height: listCol.height
                    radius: Theme.cardRadius
                    tint: Qt.rgba(1, 1, 1, 0.03)
                    sheen: 0.10
                    rim: 0.35

                    Column {
                        id: listCol
                        width: parent.width

                        Item {
                            width: parent.width
                            height: airPodsTrayApp.deviceInfo.adaptiveModeActive ? 78 : 0
                            visible: height > 1
                            clip: true
                            Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

                            GlassText { x: 18; y: 12; text: qsTr("Adaptive Noise Level"); font.pixelSize: 15 }
                            GlassText {
                                anchors.right: parent.right; anchors.rightMargin: 18; y: 13
                                text: Math.round(levelSlider.value)
                                color: Theme.secondary
                                font.pixelSize: 14
                            }
                            Slider {
                                id: levelSlider
                                x: 12; y: 38
                                width: parent.width - 24
                                from: 0; to: 100; stepSize: 1
                                value: airPodsTrayApp.deviceInfo.adaptiveNoiseLevel

                                Timer {
                                    id: debounceTimer
                                    interval: 500
                                    onTriggered: if (!levelSlider.pressed) airPodsTrayApp.setAdaptiveNoiseLevel(levelSlider.value)
                                }
                                onPressedChanged: if (!pressed) airPodsTrayApp.setAdaptiveNoiseLevel(value)
                                onValueChanged: if (pressed) debounceTimer.restart()

                                background: Rectangle {
                                    x: levelSlider.leftPadding
                                    y: levelSlider.topPadding + levelSlider.availableHeight / 2 - height / 2
                                    width: levelSlider.availableWidth
                                    height: 6; radius: 3
                                    color: Qt.rgba(1, 1, 1, 0.18)
                                    Rectangle { width: levelSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: Qt.rgba(1, 1, 1, 0.9) }
                                }
                                handle: Rectangle {
                                    x: levelSlider.leftPadding + levelSlider.visualPosition * (levelSlider.availableWidth - width)
                                    y: levelSlider.topPadding + levelSlider.availableHeight / 2 - height / 2
                                    width: 22; height: 22; radius: 11
                                    color: "white"
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.12)
                                    scale: levelSlider.pressed ? 1.15 : 1
                                    Behavior on scale { NumberAnimation { duration: 140 } }
                                }
                            }
                            Rectangle { anchors.bottom: parent.bottom; x: 18; width: parent.width - 18; height: 1; color: Theme.separator }
                        }

                        SettingRow {
                            title: qsTr("Conversational Awareness")
                            GlassSwitch {
                                checked: airPodsTrayApp.deviceInfo.conversationalAwareness
                                onToggled: airPodsTrayApp.setConversationalAwareness(checked)
                            }
                        }
                        SettingRow {
                            title: qsTr("Hearing Aid")
                            last: true
                            GlassSwitch {
                                checked: airPodsTrayApp.deviceInfo.hearingAidEnabled
                                onToggled: airPodsTrayApp.setHearingAidEnabled(checked)
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------- settings page ----------
    Component {
        id: settingsPage
        Item {
            id: sp

            Item {
                id: sHeader
                x: 26; y: 26
                width: parent.width - 52
                height: 44
                GlassButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    round: true
                    iconFamily: iconFont.name
                    iconGlyph: ""
                    onClicked: stackView.pop()
                }
                GlassText {
                    anchors.centerIn: parent
                    text: qsTr("Settings")
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
            }

            Flickable {
                anchors.top: sHeader.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentWidth: width
                contentHeight: sCol.height + 28
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: sCol
                    x: 26
                    width: parent.width - 52
                    spacing: 10

                    SectionLabel { text: qsTr("Pause Behavior When Removing AirPods"); leftPadding: 6 }
                    SegmentedControl {
                        width: parent.width
                        model: [qsTr("One Removed"), qsTr("Both Removed"), qsTr("Never")]
                        currentIndex: airPodsTrayApp.earDetectionBehavior
                        onCurrentIndexChanged: airPodsTrayApp.earDetectionBehavior = currentIndex
                    }

                    Item { width: 1; height: 6 }
                    SectionLabel { text: qsTr("General"); leftPadding: 6 }
                    GlassPanel {
                        width: parent.width
                        height: gCol.height
                        tint: Qt.rgba(1, 1, 1, 0.03); sheen: 0.10; rim: 0.35
                        Column {
                            id: gCol
                            width: parent.width
                            SettingRow {
                                title: qsTr("Auto-Start on Login")
                                GlassSwitch {
                                    checked: airPodsTrayApp.autoStartManager.autoStartEnabled
                                    onToggled: airPodsTrayApp.autoStartManager.autoStartEnabled = checked
                                }
                            }
                            SettingRow {
                                title: qsTr("Enable System Notifications")
                                GlassSwitch {
                                    checked: airPodsTrayApp.notificationsEnabled
                                    onToggled: airPodsTrayApp.notificationsEnabled = checked
                                }
                            }
                            SettingRow {
                                title: qsTr("Cross-Device Connectivity with Android")
                                GlassSwitch {
                                    checked: airPodsTrayApp.crossDeviceEnabled
                                    onToggled: airPodsTrayApp.setCrossDeviceEnabled(checked)
                                }
                            }
                            SettingRow {
                                visible: airPodsTrayApp.airpodsConnected
                                height: visible ? implicitHeight : 0
                                title: qsTr("One Bud ANC Mode")
                                subtitle: qsTr("More noise reduction with one AirPod, uses more battery")
                                GlassSwitch {
                                    checked: airPodsTrayApp.deviceInfo.oneBudANCMode
                                    onToggled: airPodsTrayApp.deviceInfo.oneBudANCMode = checked
                                }
                            }
                            SettingRow {
                                title: qsTr("Bluetooth Retry Attempts")
                                last: true
                                Row {
                                    spacing: 10
                                    GlassButton { round: true; implicitWidth: 32; implicitHeight: 32; text: ""; iconGlyph: "−"; onClicked: airPodsTrayApp.retryAttempts = Math.max(1, airPodsTrayApp.retryAttempts - 1) }
                                    GlassText { anchors.verticalCenter: parent.verticalCenter; text: airPodsTrayApp.retryAttempts; font.pixelSize: 16; font.weight: Font.DemiBold; width: 20; horizontalAlignment: Text.AlignHCenter }
                                    GlassButton { round: true; implicitWidth: 32; implicitHeight: 32; text: ""; iconGlyph: "+"; onClicked: airPodsTrayApp.retryAttempts = Math.min(10, airPodsTrayApp.retryAttempts + 1) }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 6; visible: airPodsTrayApp.airpodsConnected }
                    SectionLabel { visible: airPodsTrayApp.airpodsConnected; text: qsTr("Device"); leftPadding: 6 }
                    GlassPanel {
                        visible: airPodsTrayApp.airpodsConnected
                        width: parent.width
                        height: visible ? dCol.height : 0
                        tint: Qt.rgba(1, 1, 1, 0.03); sheen: 0.10; rim: 0.35
                        Column {
                            id: dCol
                            width: parent.width
                            padding: 0
                            Item {
                                width: parent.width; height: 58
                                GlassField { id: newNameField; x: 14; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 130; placeholderText: airPodsTrayApp.deviceInfo.deviceName; maximumLength: 32 }
                                GlassButton { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; implicitWidth: 92; text: qsTr("Rename"); onClicked: airPodsTrayApp.renameAirPods(newNameField.text) }
                                Rectangle { anchors.bottom: parent.bottom; x: 18; width: parent.width - 18; height: 1; color: Theme.separator }
                            }
                            Item {
                                width: parent.width; height: 58
                                GlassField { id: newPhoneMacField; x: 14; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 130; placeholderText: (PHONE_MAC_ADDRESS !== "" ? PHONE_MAC_ADDRESS : "00:00:00:00:00:00"); maximumLength: 32 }
                                GlassButton { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; implicitWidth: 92; text: qsTr("Set MAC"); onClicked: airPodsTrayApp.setPhoneMac(newPhoneMacField.text) }
                            }
                        }
                    }

                    Item { width: 1; height: 4 }
                    GlassButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: 240
                        text: qsTr("Show Magic Cloud Keys QR")
                        onClicked: keysQrDialog.show()
                    }
                    KeysQRDialog {
                        id: keysQrDialog
                        encKey: airPodsTrayApp.deviceInfo.magicAccEncKey
                        irk: airPodsTrayApp.deviceInfo.magicAccIRK
                    }
                }
            }
        }
    }
}
