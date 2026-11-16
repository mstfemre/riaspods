import QtQuick
import QtQuick.Shapes

// Apple style battery ring with an optional charging bolt.
Item {
    id: root
    property int level: 0
    property bool charging: false
    property bool dimmed: false
    property real progress: 1       // 0..1 intro sweep
    implicitWidth: 52
    implicitHeight: 52
    width: implicitWidth
    height: implicitHeight

    readonly property color tone: level <= 20 && !charging ? Theme.red : Theme.green
    readonly property real sweep: 360 * Math.max(0.02, level / 100) * progress

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.22)
            strokeWidth: 4
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.width / 2 - 3; radiusY: root.height / 2 - 3; startAngle: -90; sweepAngle: 360 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.tone
            strokeWidth: 4
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2; radiusX: root.width / 2 - 3; radiusY: root.height / 2 - 3; startAngle: -90; sweepAngle: root.sweep }
        }
    }

    Shape {
        visible: root.charging
        anchors.centerIn: parent
        width: 16; height: 22
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.tone
            strokeColor: "transparent"
            startX: 10; startY: 0
            PathLine { x: 1; y: 12.5 }
            PathLine { x: 7.2; y: 12.5 }
            PathLine { x: 5.5; y: 22 }
            PathLine { x: 15; y: 8.5 }
            PathLine { x: 8.8; y: 8.5 }
            PathLine { x: 10; y: 0 }
        }
    }
}
