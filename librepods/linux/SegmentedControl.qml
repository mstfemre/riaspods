pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQuick.Controls 2.15

// Glass segmented control with a sliding thumb.
Control {
    id: root
    property var model: ["Option 1", "Option 2"]
    property int currentIndex: 0

    implicitHeight: 40
    padding: 3
    focusPolicy: Qt.StrongFocus
    activeFocusOnTab: true

    // widths proportional to the label length so long labels fit
    property var segWidths: []
    function recompute() {
        var w = []
        var total = 0
        for (var i = 0; i < metrics.count; i++) {
            var t = metrics.itemAt(i)
            var iw = t ? t.implicitWidth + 22 : 60
            w.push(iw)
            total += iw
        }
        var k = total > 0 ? root.availableWidth / total : 1
        for (var j = 0; j < w.length; j++) w[j] = w[j] * k
        segWidths = w
    }
    onAvailableWidthChanged: recompute()
    onModelChanged: recompute()

    function segX(i) {
        var x = 0
        for (var j = 0; j < i; j++) x += (segWidths[j] || 0)
        return x
    }

    // hidden measuring texts
    Repeater {
        id: metrics
        model: root.model
        delegate: GlassText {
            required property string modelData
            visible: false
            text: modelData
            font.pixelSize: 13
            font.weight: Font.DemiBold
            Component.onCompleted: root.recompute()
        }
    }

    background: Rectangle {
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.22)
        border.width: root.activeFocus ? 1.5 : 1
        border.color: root.activeFocus ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.12)
    }

    contentItem: Item {
        // sliding glass thumb
        Rectangle {
            id: thumb
            x: root.segX(root.currentIndex)
            width: root.segWidths[root.currentIndex] || 0
            height: parent.height
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.24)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.38)
            Behavior on x { SpringAnimation { spring: 4.5; damping: 0.38; mass: 0.9 } }
            Behavior on width { SpringAnimation { spring: 4.5; damping: 0.38; mass: 0.9 } }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.25) }
                    GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }

        Repeater {
            model: root.model
            delegate: Item {
                id: seg
                required property int index
                required property string modelData
                x: root.segX(index)
                width: root.segWidths[index] || 0
                height: parent.height
                GlassText {
                    anchors.centerIn: parent
                    text: seg.modelData
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.currentIndex === seg.index ? Theme.label : Theme.secondary
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.currentIndex !== seg.index) root.currentIndex = seg.index
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left && root.currentIndex > 0) { root.currentIndex--; event.accepted = true }
        else if (event.key === Qt.Key_Right && root.currentIndex < root.model.length - 1) { root.currentIndex++; event.accepted = true }
        else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            var i = event.key - Qt.Key_1
            if (i < root.model.length) { root.currentIndex = i; event.accepted = true }
        }
    }
}
