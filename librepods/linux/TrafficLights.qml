import QtQuick 2.15

// macOS-style window controls (red / yellow / green). The symbols appear when the
// pointer is over the group, and the lights turn grey while the window is unfocused.
// The window has a fixed size, so the green light is shown disabled, as macOS does.
Row {
    id: lights
    property bool active: true
    property bool zoomable: false
    signal closeClicked()
    signal minimizeClicked()
    signal zoomClicked()

    spacing: 8
    property bool hovered: hover.hovered
    HoverHandler { id: hover }

    component Light: Rectangle {
        id: light
        property color tint
        property string glyph
        property bool usable: true
        signal clicked()
        width: 12; height: 12; radius: 6
        color: !light.usable ? Qt.rgba(1, 1, 1, 0.16)
             : lights.active || lights.hovered ? tint : Qt.rgba(142/255, 142/255, 147/255, 0.44)
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.18)
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -0.5
            visible: lights.hovered && light.usable
            text: light.glyph
            color: Qt.rgba(0, 0, 0, 0.6)
            font.pixelSize: 10
            font.weight: Font.Bold
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "black"
            opacity: tap.pressed && light.usable ? 0.22 : 0
        }
        TapHandler {
            id: tap
            enabled: light.usable
            onTapped: light.clicked()
        }
    }

    Light { tint: "#FF5F57"; glyph: "×"; onClicked: lights.closeClicked() }
    Light { tint: "#FEBC2E"; glyph: "−"; onClicked: lights.minimizeClicked() }
    Light { tint: "#28C840"; glyph: "+"; usable: lights.zoomable; onClicked: lights.zoomClicked() }
}
