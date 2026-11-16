pragma Singleton
import QtQuick 2.15

QtObject {
    // Apple-like typography. SF Pro is used when installed, Inter is the closest free match.
    readonly property string family: {
        const wanted = ["SF Pro Display", "SF Pro Text", "Inter Display", "Inter", "Noto Sans"]
        const have = Qt.fontFamilies()
        for (let i = 0; i < wanted.length; i++)
            if (have.indexOf(wanted[i]) >= 0) return wanted[i]
        return ""
    }

    readonly property color label: Qt.rgba(1, 1, 1, 0.96)
    readonly property color secondary: Qt.rgba(235/255, 235/255, 245/255, 0.62)
    readonly property color tertiary: Qt.rgba(235/255, 235/255, 245/255, 0.34)
    readonly property color separator: Qt.rgba(1, 1, 1, 0.10)
    readonly property color green: "#30D158"
    readonly property color yellow: "#FFD60A"
    readonly property color red: "#FF453A"
    readonly property color blue: "#0A84FF"

    // Glass tints
    readonly property color glassBase: Qt.rgba(22/255, 22/255, 30/255, 0.42)
    readonly property color glassFill: Qt.rgba(1, 1, 1, 0.07)
    readonly property color glassFillStrong: Qt.rgba(1, 1, 1, 0.14)

    readonly property int windowRadius: 20
    readonly property int cardRadius: 16

    readonly property int easeOutDuration: 420
}
