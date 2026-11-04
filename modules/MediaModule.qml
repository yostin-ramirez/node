import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components

Item {
    id: root

    readonly property font fontConfig: Qt.font({
        family: Config.theme.fontPrimary,
        pixelSize: Config.theme.fontSizePrimary,
        weight: Font.DemiBold
    })

    property Item bottomTarget: null

    // Each trigger source has its own flag so they compose without overriding each other
    readonly property bool _autoActive: autoPreviewTimer.running
    readonly property bool _hoverActive: thumbnail.isHovered

    // isPreviewActive drives thumbnail expansion and metadata visibility
    readonly property bool isPreviewActive: _autoActive || _hoverActive

    // If both are somehow active simultaneously, loop mode takes priority
    readonly property int _marqueeMode: _hoverActive ? MarqueeText.StringMode.Loop : MarqueeText.StringMode.Once

    anchors.fill: parent
    implicitHeight: isPreviewActive ? Config.metrics.size[1600] : Config.notch.height
    implicitWidth: Config.notch.width

    // Auto-preview on song change — fires Once mode marquee
    Connections {
        target: MediaService
        function onTitleChanged() {
            autoPreviewTimer.restart();
        }
    }

    Timer {
        id: autoPreviewTimer
        interval: 4000
    }

    MediaThumbnail {
        id: thumbnail
        anchors {
            left: parent.left
            top: parent.top
        }

        baseSize: Config.metrics.iconMedium
        radius: Config.modules.media.thumbnailRadius
        thumbnailUrl: MediaService.thumbnailUrl
        isPreviewActive: root.isPreviewActive
    }

    MediaMetadata {
        id: metadata
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 5
            bottomMargin: 2
        }

        titleText: MediaService.title
        artistText: MediaService.artist
        icon: ""
        textColor: Config.theme.textSecondary
        textFont: root.fontConfig
        iconColor: Config.theme.textSecondary

        active: root.isPreviewActive
        triggerMode: root._marqueeMode
    }

    AudioVisualizer {
        anchors {
            right: parent.right
            top: parent.top
        }

        service: AudioService
        barCount: Config.modules.media.visualizerBarCount
        barColor: Config.modules.media.visualizerBarColor
        barWidth: Config.modules.media.visualizerBarWidth
        maxBarHeight: Config.modules.media.maxVisualizerBarHeight
        barSpacing: Config.modules.media.visualizerBarSpacing
        barSensitivity: Config.modules.media.visualizerBarSensitivity
    }

    ProgressBar {
        id: progress
        barColor: Config.modules.media.progressBarColor
        progress: MediaService.playbackProgress
    }

    Component.onCompleted: {
        if (root.bottomTarget) {
            progress.parent = root.bottomTarget;
            progress.anchors.left = root.bottomTarget.left;
            progress.anchors.right = root.bottomTarget.right;
            progress.anchors.bottom = root.bottomTarget.bottom;
        }
    }

    Component.onDestruction: {
        if (progress.parent === root.bottomTarget)
            progress.parent = null;
    }
}
