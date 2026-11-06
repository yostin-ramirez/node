import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services

// Notification card: avatar on the left, title and body stacked on the right
Item {
    id: root

    readonly property var notification: NotificationService.current
    readonly property var _cfg: Config.modules.notification

    anchors.fill: parent
    implicitWidth: _cfg.width
    implicitHeight: _cfg.height

    ClippingRectangle {
        id: avatar
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Config.metrics.space[100]
            topMargin: Config.metrics.space[100]
        }
        width: root._cfg.avatarSize
        height: root._cfg.avatarSize
        radius: root._cfg.avatarRadius
        color: Config.theme.backgroundSecondary

        Image {
            id: avatarImage
            anchors.fill: parent
            source: root.notification.image
            // Fixed source size avoids texture reloads
            sourceSize.width: root._cfg.avatarSize * 2
            sourceSize.height: root._cfg.avatarSize * 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        // Initial shown when there is no usable image
        Text {
            anchors.centerIn: parent
            visible: avatarImage.status !== Image.Ready
            text: root.notification.appName.charAt(0).toUpperCase()
            color: Config.theme.textSecondary
            font.family: Config.theme.fontPrimary
            font.pixelSize: root._cfg.avatarInitialSize
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors {
            left: avatar.right
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            leftMargin: Config.metrics.spacingMedium
            topMargin: Config.metrics.spacingSmall
            rightMargin: Config.metrics.space[200]
            bottomMargin: Config.metrics.space[100]
        }
        spacing: root._cfg.textSpacing

        Text {
            width: parent.width
            text: root.notification.title
            color: Config.theme.textPrimary
            font.family: Config.theme.fontPrimary
            font.pixelSize: Config.theme.fontSizePrimary
            font.weight: Font.DemiBold
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.notification.body
            textFormat: Text.PlainText
            color: Config.theme.textSecondary
            font.family: Config.theme.fontPrimary
            font.pixelSize: Config.theme.fontSizePrimary
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            maximumLineCount: root._cfg.bodyMaxLines
            elide: Text.ElideRight
        }
    }

    // Click closes the notification
    TapHandler {
        onTapped: NotificationService.dismiss()
    }
}
