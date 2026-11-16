import QtQuick
import QtQuick.Shapes

// Liquid-glass surface: translucent tint (the compositor blurs what is behind the window),
// a soft specular sheen on top and a thin gradient rim light.
Item {
    id: root
    property real radius: Theme.cardRadius
    property color tint: Theme.glassBase
    property real sheen: 0.16
    property real rim: 0.55
    property bool shadowless: true
    default property alias content: holder.data

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
    }

    // Diagonal frost: brighter near the top-left like light catching the glass.
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.sheen) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.035) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.07) }
        }
    }

    // Gradient rim (outer rounded rect minus inner rounded rect, even-odd fill).
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillRule: ShapePath.OddEvenFill
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: root.width; y2: root.height
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.rim) }
                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, 0.06) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, root.rim * 0.55) }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height; radius: root.radius }
            PathRectangle { x: 1.2; y: 1.2; width: root.width - 2.4; height: root.height - 2.4; radius: Math.max(0, root.radius - 1.2) }
        }
    }

    Item { id: holder; anchors.fill: parent }
}
