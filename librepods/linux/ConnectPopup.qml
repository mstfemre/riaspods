import QtQuick
import QtQuick.Window

// iPhone-style connection sheet: slides up, the buds and the case spin into view,
// battery rings fill. Tap the X (or anywhere) to dismiss.
Window {
    id: popup
    width: 400
    height: 448
    title: "RiasPods Connect"
    color: "transparent"
    visible: false
    transientParent: null
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    property int lifetime: 7500
    property bool leaving: false
    readonly property var info: airPodsTrayApp.deviceInfo

    // Show the window with the card parked below it, let the 3D view load and draw its
    // first frames there, and only then slide the card in. This keeps the slide smooth.
    function present() {
        leaving = false
        exitAnim.stop()
        enterAnim.stop()
        card.opacity = 1
        cardMove.y = 470
        visible = true
        warm.ticks = 0
        warm.total = 0
        warm.restart()
    }
    function begin() {
        enterAnim.restart()
        showcase.play()
        life.restart()
    }
    Timer {
        id: warm
        property int ticks: 0      // consecutive ticks with the 3D view ready
        property int total: 0
        interval: 50
        repeat: true
        onTriggered: {
            ticks = showcase.ready ? ticks + 1 : 0
            if (ticks >= 4 || ++total > 30) { stop(); popup.begin() }
        }
    }

    function dismiss() {
        if (leaving || !visible) return
        leaving = true
        life.stop()
        warm.stop()
        enterAnim.stop()
        exitAnim.restart()
    }

    Timer {
        id: life
        interval: popup.lifetime
        running: false
        onTriggered: if (!hover.hovered) popup.dismiss(); else life.restart()
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: cardMove; property: "y"; from: 470; to: 0; duration: 640; easing.type: Easing.OutQuint }
    }
    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic }
        NumberAnimation { target: cardMove; property: "y"; to: 470; duration: 360; easing.type: Easing.InCubic }
        onFinished: { popup.visible = false; popup.leaving = false }
    }

    Item {
        id: card
        anchors.fill: parent
        opacity: 1
        transform: Translate { id: cardMove; y: 470 }

        GlassPanel {
            anchors.fill: parent
            radius: 20
            tint: Qt.rgba(0.102, 0.118, 0.122, 0.97)
            sheen: 0.03
            rim: 0.30
        }

        GlassText {
            id: title
            anchors.horizontalCenter: parent.horizontalCenter
            y: 36
            width: 275
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            lineHeight: 1.04
            text: popup.info.deviceName !== "" ? popup.info.deviceName : "AirPods"
            font.pixelSize: 32
            font.weight: Font.Bold
            font.letterSpacing: -0.4
        }

        // close button
        Rectangle {
            id: closeBtn
            width: 36; height: 36; radius: 18
            x: parent.width - width - 22
            y: 30
            color: closeArea.pressed ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
            Behavior on color { ColorAnimation { duration: 120 } }
            Rectangle { anchors.centerIn: parent; width: 14; height: 2.4; radius: 1.2; rotation: 45; color: Theme.label }
            Rectangle { anchors.centerIn: parent; width: 14; height: 2.4; radius: 1.2; rotation: -45; color: Theme.label }
            MouseArea { id: closeArea; anchors.fill: parent; onClicked: popup.dismiss() }
        }

        PodsShowcase {
            id: showcase
            x: 14
            y: 134
            width: parent.width - 28
            height: implicitHeight
            info: popup.info
            active: popup.visible && !popup.leaving
        }
    }

    HoverHandler { id: hover }
}
