import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.modules

// Secondary surface that morphs out of the notch, driven by NotchState.bubbleScene
// Enter: notch stretches, the bubble grows out of it fused as one shape, pinches off and settles
// Exit: the same timeline in reverse
Rectangle {
    id: root

    // Notch the bubble emerges from, set by the parent
    property Rectangle origin: null

    // Notch stretch: 0 = rest, 1 = pulled down, below 0 = recoil
    property real stretch: 0.0

    // 0 = merged inside the notch, 1 = settled below it
    property real progress: 0.0
    property real drop: 0.0

    // 0 = content hidden, 1 = content fully visible
    property real contentProgress: 0.0

    // 0 = fused with the notch (borders hidden), 1 = separate shapes
    readonly property real _split: _scene === "none" ? 1.0 : Math.max(0.0, Math.min(1.0, (progress - _morph.separateStart) / (1.0 - _morph.separateStart)))

    readonly property var _morph: Config.notch.morph

    // Module registry: maps scene name -> component factory
    // To add a new bubble module: register it here and create its Module file
    readonly property var _registry: ({
            "notification": notificationComponent,
            "none": null
        })

    // Scene currently mounted, lags behind NotchState while the exit plays
    property string _scene: "none"
    property bool _exiting: false

    // Origin geometry with a null guard
    readonly property real _originX: origin ? origin.x : 0
    readonly property real _originY: origin ? origin.y : 0
    readonly property real _originWidth: origin ? origin.width : 0
    readonly property real _originHeight: origin ? origin.height : 0

    // Final size comes from the mounted module
    readonly property real _targetWidth: loader.item ? loader.item.implicitWidth : 0
    readonly property real _targetHeight: loader.item ? loader.item.implicitHeight : 0

    // Opens up only after the bubble starts separating, no upper clamp so it can bounce
    readonly property real _widen: Math.max(0.0, (progress - _morph.separateStart) / (1.0 - _morph.separateStart))

    // Hidden when idle so it never captures input
    visible: _scene !== "none"

    // Same width as the notch while fused, so it reads as the notch elongating
    x: _originX + (_originWidth - width) / 2
    // Vertical motion is clamped, its bounce comes from `drop` instead
    y: _originY + (_originHeight + Config.notch.gap) * Math.min(progress, 1.0) + drop

    width: _originWidth + (_targetWidth - _originWidth) * _widen
    height: _originHeight + (_targetHeight - _originHeight) * Math.min(progress, 1.0)

    radius: Config.metrics.radius[500]
    color: Config.theme.backgroundPrimary
    border.color: Config.theme.borderSubtle
    border.width: Config.metrics.borderThin

    // Strand joining notch and bubble while they pull apart, thins out and pinches off
    Rectangle {
        id: neck

        readonly property real _gap: root.y - (root._originY + root._originHeight)
        readonly property real _overlap: 3

        visible: _gap > 0 && root._split < 1.0
        width: Math.max(0, (root._originWidth - Config.metrics.radiusMedium * 2) * (1.0 - root._split))
        height: _gap + _overlap * 2
        x: (root.width - width) / 2
        y: -_gap - _overlap
        color: root.color
    }

    Component {
        id: notificationComponent
        NotificationModule {}
    }

    // Clips the content to the surface while it is still smaller than the final size
    Item {
        anchors.fill: parent
        clip: true

        Loader {
            id: loader

            // Fixed final size so content does not reflow while the surface resizes
            width: Math.max(0, root._targetWidth - Config.notch.padding * 2)
            height: Math.max(0, root._targetHeight - Config.notch.padding * 2)
            x: (root.width - width) / 2
            y: Config.notch.padding

            sourceComponent: root._registry[root._scene] ?? null

            // Kept barely visible so the effect compiles before the reveal
            opacity: Math.max(root.contentProgress, 0.01)
            transform: Translate {
                y: -root._morph.contentOffset * (1.0 - root.contentProgress)
            }

            // Layer only while animating so the text stays crisp at rest
            layer.enabled: root.contentProgress < 1.0
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: root._morph.contentBlurMax
                blur: 1.0 - root.contentProgress
            }
        }
    }

    Connections {
        target: NotchState
        function onBubbleSceneChanged() {
            root._sync();
        }
    }

    Component.onCompleted: _sync()

    // Mounts or unmounts the module so it matches NotchState
    function _sync() {
        if (_exiting)
            return;

        const desired = NotchState.bubbleScene;
        if (desired === _scene)
            return;

        // Different scene already mounted: exit first, then re-sync
        if (_scene !== "none") {
            _exit();
            return;
        }

        _scene = desired;
        _enter();
    }

    function _enter() {
        exitAnim.stop();
        stretch = 0.0;
        progress = 0.0;
        drop = 0.0;
        contentProgress = 0.0;
        enterAnim.restart();
    }

    function _exit() {
        _exiting = true;
        enterAnim.stop();
        exitAnim.restart();
    }

    function _onExitFinished() {
        _scene = "none";
        _exiting = false;
        stretch = 0.0;
        progress = 0.0;
        drop = 0.0;
        contentProgress = 0.0;
        _sync();
    }

    SequentialAnimation {
        id: enterAnim

        // Let the module mount and render once before moving
        PauseAnimation {
            duration: root._morph.mountDelay
        }

        // Notch is pulled down
        NumberAnimation {
            target: root
            property: "stretch"
            to: 1.0
            duration: root._morph.stretchDuration
            easing.type: Easing.OutCubic
        }

        ParallelAnimation {
            // Notch recoils past rest while the bubble leaves in the opposite direction
            NumberAnimation {
                target: root
                property: "stretch"
                to: 0.0
                duration: root._morph.recoilDuration
                easing.type: Easing.OutBack
                easing.overshoot: root._morph.recoilOvershoot
            }
            NumberAnimation {
                target: root
                property: "progress"
                to: 1.0
                duration: root._morph.detachDuration
                easing.type: Easing.OutBack
                easing.overshoot: root._morph.bubbleOvershoot
            }

            // Content starts late so it finishes together with the resize
            SequentialAnimation {
                PauseAnimation {
                    duration: Math.max(0, root._morph.detachDuration - root._morph.contentDuration)
                }
                NumberAnimation {
                    target: root
                    property: "contentProgress"
                    to: 1.0
                    duration: root._morph.contentDuration
                    easing.type: Easing.OutCubic
                }
            }

            // Bubble goes a bit past its spot, then returns
            SequentialAnimation {
                PauseAnimation {
                    duration: root._morph.detachDuration * root._morph.dropStart
                }
                NumberAnimation {
                    target: root
                    property: "drop"
                    to: root._morph.dropDistance
                    duration: root._morph.dropOutDuration
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "drop"
                    to: 0.0
                    duration: root._morph.dropBackDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            // Content leaves first while the bubble backs off and retracts
            NumberAnimation {
                target: root
                property: "contentProgress"
                to: 0.0
                duration: root._morph.contentDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "progress"
                to: 0.0
                duration: root._morph.detachDuration
                easing.type: Easing.InBack
                easing.overshoot: root._morph.bubbleOvershoot
            }

            // Notch squashes then swells as it absorbs the bubble
            SequentialAnimation {
                PauseAnimation {
                    duration: Math.max(0, root._morph.detachDuration - root._morph.recoilDuration)
                }
                NumberAnimation {
                    target: root
                    property: "stretch"
                    to: 1.0
                    duration: root._morph.recoilDuration
                    easing.type: Easing.InCubic
                }
            }
        }

        // Notch recoils slightly below rest, then settles
        NumberAnimation {
            target: root
            property: "stretch"
            to: 0.0
            duration: root._morph.recoilDuration
            easing.type: Easing.OutBack
            easing.overshoot: root._morph.recoilOvershoot
        }

        ScriptAction {
            script: root._onExitFinished()
        }
    }
}
