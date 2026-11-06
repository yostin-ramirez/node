pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject media: QtObject {
        // Media Thumbnail
        readonly property int thumbnailSize: Metrics.iconMedium
        readonly property int thumbnailRadius: Metrics.radiusSmall

        // Audio Visualizer
        readonly property int visualizerBarCount: 6
        readonly property color visualizerBarColor: Theme.textPrimary
        readonly property int visualizerBarWidth: 2
        readonly property int maxVisualizerBarHeight: 24
        readonly property real visualizerBarSpacing: 1.6
        readonly property real visualizerBarSensitivity: 0.8

        // Progress Bar
        readonly property color progressBarColor: Theme.textSecondary
        readonly property int progressBarThicknessSmall: 2
        readonly property int progressBarThicknessMedium: 4
    }

    readonly property QtObject notification: QtObject {
        // Card layout
        readonly property int width: 300
        readonly property int height: 68

        // Avatar
        readonly property int avatarSize: 24
        readonly property int avatarRadius: Metrics.radius[225]
        readonly property int avatarInitialSize: 10

        // Text
        readonly property int textSpacing: 3
        readonly property int bodyMaxLines: 2
    }
}
