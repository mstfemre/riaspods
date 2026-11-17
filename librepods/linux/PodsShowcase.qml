import QtQuick

// Buds + case turntable with battery rings, like the iPhone pairing sheet.
Item {
    id: root
    property var info
    property real spriteScale: 0.5
    property real revealT: 1     // 0..1 reveal of rings/labels
    property bool active: true
    // keep the loaded 3D view this long after it goes off screen, so reopening is instant
    property int lingerMs: 0
    // only linger after the view was really shown (not for the initial binding at startup)
    property bool completed: false
    Component.onCompleted: completed = true
    onActiveChanged: if (completed && !active && lingerMs > 0) linger.restart(); else linger.stop()
    Timer { id: linger; interval: Math.max(1, root.lingerMs) }
    // keep the 3D view loaded even while off screen (a hidden window draws nothing, so this
    // only costs memory); creating it blocks the UI for about half a second
    property bool keepLoaded: false
    property int turns: -1        // -1: keep spinning, n: n turns then rest (hover spins again)

    readonly property bool demo: Qt.application.arguments.indexOf("--showcase-test") >= 0
    readonly property bool sprites: info.podIcon === "pro3"
    readonly property var battery: info.battery
    // a level of 0 means "not reported yet", so such a bud is treated as absent
    readonly property bool leftOk: battery.leftPodAvailable && battery.leftPodLevel > 0
    readonly property bool rightOk: battery.rightPodAvailable && battery.rightPodLevel > 0
    readonly property bool headsetOk: battery.headsetAvailable && battery.headsetLevel > 0
    readonly property bool budsShown: demo || leftOk || rightOk || headsetOk
    readonly property int budsLevel: {
        if (demo) return 84
        if (headsetOk) return battery.headsetLevel
        if (leftOk && rightOk) return Math.min(battery.leftPodLevel, battery.rightPodLevel)
        return leftOk ? battery.leftPodLevel : battery.rightPodLevel
    }
    // true once the 3D view exists (or is not needed), so callers can start their animation
    readonly property bool ready: !sprites || !(budsShown || caseShown) || view3d.status === Loader.Ready
    readonly property bool budsCharging: demo || (headsetOk && battery.headsetCharging) || (leftOk && battery.leftPodCharging) || (rightOk && battery.rightPodCharging)
    readonly property bool caseShown: demo || battery.caseKnown
    readonly property int caseLevelV: demo ? 97 : battery.caseCachedLevel
    readonly property bool caseStale: demo ? false : !battery.caseLive
    property real nowSecs: Date.now() / 1000

    implicitWidth: 400
    implicitHeight: stageH + 150
    readonly property real stageH: 300 * spriteScale

    function pct(v) { return Qt.locale().name.indexOf("tr") === 0 ? "%" + v : v + "%" }
    function ago(seen) {
        if (seen <= 0) return ""
        const m = Math.max(0, Math.round((nowSecs - seen) / 60))
        if (m < 1) return qsTr("just now")
        if (m < 60) return qsTr("%1 min ago").arg(m)
        const h = Math.round(m / 60)
        if (h < 24) return qsTr("%1 h ago").arg(h)
        return qsTr("%1 d ago").arg(Math.round(h / 24))
    }

    function play() {
        if (view3d.item) view3d.item.play()
        ringAnim.restart()
    }

    NumberAnimation { id: ringAnim; target: root; property: "revealT"; from: 0; to: 1; duration: 1100; easing.type: Easing.OutCubic }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.nowSecs = Date.now() / 1000 }

    // ---- 3D turntable (exists while on screen, or always with keepLoaded)
    Loader {
        id: view3d
        active: root.sprites && (root.active || root.keepLoaded || linger.running) && (root.budsShown || root.caseShown)
        x: 0; y: 0
        width: root.width
        height: root.stageH
        sourceComponent: Pods3D {
            showBuds: root.budsShown
            showCase: root.caseShown
            unit: 22 * root.spriteScale / 0.5
            turns: root.turns
        }
    }

    HoverHandler { onHoveredChanged: if (hovered && view3d.item) view3d.item.spin() }

    // ---- buds column
    Item {
        id: budsCol
        visible: root.budsShown
        x: root.caseShown ? 0 : root.width * 0.25
        width: root.width * 0.5
        height: parent.height
        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Image {
            visible: !root.sprites
            source: root.sprites ? "" : "qrc:/icons/assets/" + root.info.podIcon
            height: 90; width: 100
            fillMode: Image.PreserveAspectFit
            mipmap: true
            x: (parent.width - width) / 2
            y: root.stageH - 105
        }
        BatteryRing {
            id: budsRing
            x: (parent.width - width) / 2
            y: root.stageH + 18
            level: root.budsLevel
            charging: root.budsCharging
            progress: root.revealT
        }
        GlassText {
            id: budsPct
            anchors.horizontalCenter: parent.horizontalCenter
            y: budsRing.y + budsRing.height + 6
            text: root.pct(root.budsLevel)
            font.pixelSize: 22
            font.weight: Font.Medium
            opacity: root.revealT
        }
        GlassText {
            visible: !root.demo && root.leftOk && root.rightOk
            anchors.horizontalCenter: parent.horizontalCenter
            y: budsPct.y + 28
            text: "L " + root.pct(root.battery.leftPodLevel) + "   R " + root.pct(root.battery.rightPodLevel)
            color: Theme.tertiary
            font.pixelSize: 12
            opacity: root.revealT
        }
    }

    // ---- case column
    Item {
        id: caseCol
        visible: root.caseShown
        x: root.budsShown ? root.width * 0.5 : root.width * 0.25
        width: root.width * 0.5
        height: parent.height
        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Image {
            visible: !root.sprites
            source: root.sprites ? "" : "qrc:/icons/assets/" + root.info.caseIcon
            height: 90; width: 110
            fillMode: Image.PreserveAspectFit
            mipmap: true
            x: (parent.width - width) / 2
            y: root.stageH - 105
        }
        BatteryRing {
            id: caseRing
            x: (parent.width - width) / 2
            y: root.stageH + 18
            level: root.caseLevelV
            charging: !root.demo && root.battery.caseCachedCharging
            progress: root.revealT
        }
        GlassText {
            id: casePct
            anchors.horizontalCenter: parent.horizontalCenter
            y: caseRing.y + caseRing.height + 6
            text: root.pct(root.caseLevelV)
            font.pixelSize: 22
            font.weight: Font.Medium
            opacity: root.revealT
        }
        GlassText {
            visible: root.caseStale
            anchors.horizontalCenter: parent.horizontalCenter
            y: casePct.y + 28
            text: root.ago(root.battery.caseSeenSecs)
            color: Theme.tertiary
            font.pixelSize: 12
            opacity: root.revealT
        }
    }
}
