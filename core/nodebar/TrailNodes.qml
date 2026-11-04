import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

RowLayout {
    spacing: 8

    anchors {
        fill: parent
        leftMargin: 16
        rightMargin: 16
    }

    // Left (Mocks)
    Text {
        text: "􀙇"
        font.pixelSize: 14
        font.family: "SF Pro"
        color: "white"
    }

    Text {
        text: "􀝗"
        font.pixelSize: 14
        font.family: "SF Pro"
        color: "white"
    }

    Text {
        text: "􂽂"
        font.pixelSize: 14
        font.family: "SF Pro"
        color: "#888888"
    }

    Item {
        Layout.fillWidth: true
    }

    // Right (Mocks)
    Row {
        spacing: 0
        rightPadding: 6

        Text {
            text: DateService.dayShort
            font.pixelSize: Config.theme.fontSizePrimary
            font.family: "BDO Grotesk"
            font.weight: Font.DemiBold
            color: "white"
        }

        Text {
            text: DateService.dayNumber
            font.pixelSize: Config.theme.fontSizePrimary
            font.family: "BDO Grotesk"
            font.weight: Font.DemiBold
            color: "#FF383C"
        }
    }

    Text {
        text: "􀑇"
        font.pixelSize: 14
        font.family: "SF Pro"
        color: "white"
    }
}
