import QtQuick
import qs.config

// Icon-only toggle button without background
// Controlled: the parent owns the state and flips it in onToggled
Item {
    id: root

    // Default config
    property bool checked: true
    property string activeIcon: ""
    property string inactiveIcon: ""
    property color activeColor: Config.theme.textPrimary
    property color inactiveColor: Config.theme.textSecondary
    property string fontFamily: "SF Pro"
    property int iconSize: 14

    signal toggled

    // Reserves the wider glyph so neighbors do not shift when toggling
    implicitWidth: Math.max(activeMetrics.advanceWidth, inactiveMetrics.advanceWidth)
    implicitHeight: label.implicitHeight

    TextMetrics {
        id: activeMetrics
        font: label.font
        text: root.activeIcon
    }

    TextMetrics {
        id: inactiveMetrics
        font: label.font
        text: root.inactiveIcon
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.checked ? root.activeIcon : root.inactiveIcon
        color: root.checked ? root.activeColor : root.inactiveColor
        font.family: root.fontFamily
        font.pixelSize: root.iconSize
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        // Hit area larger than the small glyph
        margin: 6
        onTapped: root.toggled()
    }
}
