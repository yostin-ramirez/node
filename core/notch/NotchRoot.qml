import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root

    anchors.top: true

    // Max notch width
    implicitWidth: 500
    implicitHeight: 500

    exclusiveZone: -1
    color: "transparent"

    aboveWindows: true
    focusable: true

    WlrLayershell.namespace: "notch"

    mask: Region {
        item: background

        Region {
            item: bubble.visible ? bubble : null
        }
    }

    NotchBackground {
        id: background
        z: 1
        morphStretch: bubble.stretch
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    NotchBubble {
        id: bubble
        origin: background
    }
}
