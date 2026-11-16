import QtQuick 2.15
import QtQuick.Controls 2.15

// iOS style switch
Switch {
    id: control
    implicitWidth: 52
    implicitHeight: 32
    padding: 0
    spacing: 0
    text: ""

    indicator: Rectangle {
        implicitWidth: 52
        implicitHeight: 32
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: height / 2
        color: control.checked ? Theme.green : Qt.rgba(1, 1, 1, 0.20)
        border.width: 1
        border.color: control.checked ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.18)
        Behavior on color { ColorAnimation { duration: 220 } }

        Rectangle {
            id: knob
            width: control.down ? 32 : 28
            height: 28
            radius: 14
            y: 2
            x: control.checked ? parent.width - width - 2 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            Behavior on width { NumberAnimation { duration: 140 } }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#FFFFFF" }
                    GradientStop { position: 1.0; color: "#E6E7EC" }
                }
            }
        }
    }
    contentItem: Item {}
}
