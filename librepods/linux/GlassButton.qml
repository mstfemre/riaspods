import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control
    property bool prominent: false
    property bool round: false
    property string iconGlyph: ""
    property alias iconFamily: glyph.font.family
    implicitHeight: round ? 38 : 36
    implicitWidth: round ? 38 : Math.max(76, label.implicitWidth + 32)
    padding: 0
    hoverEnabled: true
    scale: down ? 0.94 : 1.0
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    background: Rectangle {
        radius: height / 2
        color: control.prominent
               ? (control.down ? "#0A6FE0" : Theme.blue)
               : Qt.rgba(1, 1, 1, control.down ? 0.26 : (control.hovered ? 0.20 : 0.13))
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, control.prominent ? 0.30 : 0.22)
        Behavior on color { ColorAnimation { duration: 160 } }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }
    contentItem: Item {
        Text {
            id: glyph
            visible: control.round
            anchors.centerIn: parent
            text: control.iconGlyph
            color: Theme.label
            font.pixelSize: 17
        }
        Text {
            id: label
            visible: !control.round
            anchors.centerIn: parent
            text: control.text
            color: Theme.label
            font.family: Theme.family
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }
}
