import QtQuick
import QtQuick3D

// Real-time 3D turntable of the AirPods Pro 3: buds on the left, case on the right.
// One View3D, one render pass; mesh data is shared between the two model instances.
View3D {
    id: root
    property bool showBuds: true
    property bool showCase: true
    property real unit: 22            // pixels per model unit (case is ~6.2 units wide)
    property real yaw: 0
    property real intro: 1            // 0..1 pop-in
    property real lidOpen: 0

    readonly property bool both: showBuds && showCase
    property real colX: both ? width * 0.25 / unit : 0
    Behavior on colX { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

    // --fps prints the slowest frame of every second, to check the animation is smooth
    readonly property bool fpsLog: Qt.application.arguments.indexOf("--fps") >= 0
    property real worst: 0
    property int frames: 0
    FrameAnimation {
        running: root.fpsLog
        onTriggered: {
            root.worst = Math.max(root.worst, frameTime * 1000)
            if (++root.frames >= 60) {
                console.log("LP3D worst frame", root.worst.toFixed(1), "ms over 60 frames")
                root.frames = 0; root.worst = 0
            }
        }
    }

    // turns < 0 spins for as long as the view is shown; otherwise it does that many
    // full turns and comes to rest facing the front (a still view costs nothing to draw).
    property int turns: -1
    property real restAngle: -24

    function play() {
        introAnim.restart()
        spin()
    }
    function spin() {
        if (turns < 0 || turnAnim.running) return
        turnAnim.restart()
    }

    NumberAnimation { id: introAnim; target: root; property: "intro"; from: 0; to: 1; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    NumberAnimation {
        target: root; property: "yaw"
        from: 0; to: 360
        duration: 9000
        loops: Animation.Infinite
        running: root.turns < 0 && root.visible
    }
    NumberAnimation {
        id: turnAnim
        target: root; property: "yaw"
        from: 0; to: 360 * Math.max(1, root.turns)
        duration: 5200 * Math.max(1, root.turns)
        easing.type: Easing.InOutSine
    }

    environment: SceneEnvironment {
        backgroundMode: SceneEnvironment.Transparent
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.High
        lightProbe: Texture { source: "maps/studio.png"; mappingMode: Texture.LightProbe }
        probeExposure: 1.15
        tonemapMode: SceneEnvironment.TonemapModeLinear
    }

    camera: cam
    OrthographicCamera {
        id: cam
        z: 100
        clipNear: 1
        clipFar: 300
        horizontalMagnification: root.unit
        verticalMagnification: root.unit
    }
    DirectionalLight { eulerRotation: Qt.vector3d(-35, -30, 0); brightness: 0.5 }

    // buds
    Node {
        visible: root.showBuds
        x: -root.colX
        eulerRotation.x: 6
        scale: Qt.vector3d(root.intro, root.intro, root.intro)
        Node {
            eulerRotation.y: root.yaw + root.restAngle + 30
            AirPodsModel {
                scale: Qt.vector3d(100, 100, 100)
                showCase: false
                y: -2.65
                z: -1.3
            }
        }
    }

    // case
    Node {
        visible: root.showCase
        x: root.colX
        eulerRotation.x: 6
        scale: Qt.vector3d(root.intro, root.intro, root.intro)
        Node {
            eulerRotation.y: root.yaw + root.restAngle
            AirPodsModel {
                scale: Qt.vector3d(100, 100, 100)
                showBuds: false
                lidOpen: root.lidOpen
                y: 0.95
            }
        }
    }
}
