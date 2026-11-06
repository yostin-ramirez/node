pragma Singleton
import QtQuick
import Quickshell

// Single source of truth for what the notch is showing.
// Observes services, applies priority rules, and exposes the resolved scene names.
// UI components must never decide what to display — they only react to this.
Singleton {
    id: root

    // Scene identifiers — matched against NotchStage's module registry
    readonly property var scene: ({
            None: "none",
            Media: "media",
            Notification: "notification"
            // Future: Notification, Call, Timer, etc.
        })

    // Primary slot: the main notch content
    property string primaryScene: scene.None

    // Secondary slot: compact concurrent activity (bubble)
    property string bubbleScene: scene.None

    // Priority order (index 0 = highest priority)
    readonly property var _priority: [
        // Scene.Call,
        // Scene.Notification,
        // Scene.Timer,
        scene.Media
    ]

    readonly property var _bubblePriority: [scene.Notification]

    // Active state per scene — add one entry per future scene type
    function _isActive(candidate) {
        switch (candidate) {
        case scene.Notification:
            return NotificationService.isActive;
        case scene.Media:
            // Default scene, same effective behavior as before
            return true;
        default:
            return false;
        }
    }

    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            root._resolve();
        }
    }

    Connections {
        target: NotificationService
        function onIsActiveChanged() {
            root._resolve();
        }
    }

    Component.onCompleted: _resolve()

    function _pick(candidates) {
        for (let i = 0; i < candidates.length; i++) {
            if (root._isActive(candidates[i]))
                return candidates[i];
        }
        return scene.None;
    }

    function _resolve() {
        primaryScene = _pick(_priority);
        bubbleScene = _pick(_bubblePriority);
    }
}
