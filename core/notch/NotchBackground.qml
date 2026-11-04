import QtQuick
import qs.config

// Visual shell of the notch: background, border, shape.
// Contains NotchStage but does not control its internals.
Rectangle {
    id: root

    radius: Config.metrics.radius[350]
    color: Config.theme.backgroundPrimary
    border.color: Config.theme.borderSubtle
    border.width: Config.metrics.borderThin

    transformOrigin: Item.Top

    HoverHandler {
        id: hoverHandler
    }

    // Composable hover scale
    scale: hoverHandler.hovered ? 1.04 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 2
        }
    }

    // Bind width to stage implicit width
    width: notchStage.implicitWidth

    // Dynamic height responding to module needs
    height: notchStage.implicitHeight
    Behavior on height {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    NotchStage {
        id: notchStage
        anchors {
            fill: parent
            margins: Config.notch.padding
            // Give the bottom slot its own inset so it sits flush with the border
            bottomMargin: Config.metrics.borderThin
        }
    }
}
