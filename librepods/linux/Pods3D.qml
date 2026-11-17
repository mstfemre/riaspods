import QtQuick
import QtQuick3D
import QtQuick.Window

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
        if (turns < 0 || spinning) return
        spinStart = Date.now()
        spinning = true
    }

    NumberAnimation { id: introAnim; target: root; property: "intro"; from: 0; to: 1; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 }

    // The spin is stepped by a timer at about 60 fps instead of a NumberAnimation: an
    // animation changes the scene on every vsync, which redraws the 3D view 240 times a
    // second on a 240 Hz monitor. The angle comes from the clock, so the speed is exact.
    property bool spinning: false
    property double spinStart: 0
    // the view may stay loaded in a hidden window, so the endless spin also needs it shown
    readonly property bool endless: turns < 0 && visible && Window.visibility !== Window.Hidden
    onEndlessChanged: if (endless) spinStart = Date.now()
    // Spin curve: speed ramps up over the first 8% (~0.4 s) and then eases out to rest, so
    // the model visibly starts turning at once (an InOutSine crawls for the first second).
    function ease(t) {
        const r = 0.08
        const vmax = 1 / (r / 2 + 2 * (1 - r) / Math.PI)   // makes ease(1) == 1
        if (t < r) return vmax * t * t / (2 * r)
        return vmax * (r / 2 + 2 * (1 - r) / Math.PI * Math.sin(Math.PI / 2 * (t - r) / (1 - r)))
    }
    readonly property real frameMs: {
        const hz = Screen.refreshRate > 0 ? Screen.refreshRate : 60
        return 1000 / hz * Math.max(1, Math.round(hz / 60))   // a whole number of vsyncs
    }
    Timer {
        interval: Math.max(1, Math.floor(root.frameMs))
        repeat: true
        running: root.endless || root.spinning
        onTriggered: {
            const ms = Date.now() - root.spinStart
            if (root.endless) {
                root.yaw = (ms / 9000 * 360) % 360
                return
            }
            const n = Math.max(1, root.turns)
            const t = Math.min(1, ms / (5200 * n))
            root.yaw = 360 * n * root.ease(t)
            if (t >= 1) root.spinning = false
        }
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
