pragma Singleton
import QtQuick

QtObject {
    // Base size
    readonly property int width: 200
    readonly property int height: 36

    // Layout
    readonly property int padding: 6
    readonly property int gap: 4

    // Bubble morph
    readonly property QtObject morph: QtObject {
        // Notch pulled down before the bubble leaves
        readonly property int stretchWidth: 10
        readonly property int stretchHeight: 6
        readonly property int stretchDuration: 200

        // Notch recoil, overshoot makes it squash past rest
        readonly property int recoilDuration: 500
        readonly property real recoilOvershoot: 2

        // Bubble travel, overshoot makes it bounce away from the notch
        readonly property int detachDuration: 600
        readonly property real bubbleOvershoot: 0.6

        // Progress where the bubble stops being part of the notch
        readonly property real separateStart: 0.2

        // Content reveal, ends together with the bubble resize
        readonly property int contentDuration: 700
        readonly property real contentOffset: 10
        readonly property int contentBlurMax: 24

        // Delay so the module mounts and renders before the motion starts
        readonly property int mountDelay: 80

        // Extra vertical bounce: bubble goes past its final spot then returns
        readonly property real dropDistance: 3
        // Fraction of detachDuration where the drop starts
        readonly property real dropStart: 0.3
        readonly property int dropOutDuration: 150
        readonly property int dropBackDuration: 350

    }
}
