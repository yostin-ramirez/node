import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.config

Item {
    id: root

    // Default config
    property string thumbnailUrl: ""
    property bool isPreviewActive: false
    property int baseSize: Config.metrics.iconMedium
    property int expansionSize: 4
    property int radius: Config.metrics.radius[200] // TODO: link with radius property of clipping wrapper

    readonly property bool isHovered: hoverHandler.hovered

    // Target sizes for crisp rendering
    readonly property int _maxSize: baseSize + expansionSize

    width: (isPreviewActive || isHovered) ? _maxSize : baseSize
    height: (isPreviewActive || isHovered) ? _maxSize : baseSize

    property string _activeUrl: ""
    property string _pendingUrl: ""
    property bool _isInitialized: false

    HoverHandler {
        id: hoverHandler
    }

    Behavior on width {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 4.6
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 4.6
        }
    }

    onThumbnailUrlChanged: {
        if (!_isInitialized) {
            _activeUrl = thumbnailUrl;
            _isInitialized = true;
            return;
        }
        if (thumbnailUrl === _activeUrl)
            return;
        _pendingUrl = thumbnailUrl;
    }

    Image {
        id: imgPreload
        visible: false
        source: root._pendingUrl
        sourceSize.width: root._maxSize
        sourceSize.height: root._maxSize
        asynchronous: true
        cache: true
        onStatusChanged: {
            if (status === Image.Ready && root._pendingUrl !== "" && !transitionAnimation.running) {
                transitionAnimation.restart();
            }
        }
    }

    ClippingWrapperRectangle {
        id: wrapper
        anchors.fill: parent
        radius: Config.metrics.radius[200]
        color: Config.theme.backgroundSecondary
        layer.enabled: true
        visible: false

        Image {
            anchors.fill: parent
            source: root._activeUrl
            sourceSize.width: root._maxSize
            sourceSize.height: root._maxSize
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }

    MultiEffect {
        id: blurEffect
        source: wrapper
        anchors.fill: wrapper
        blurEnabled: blur > 0
        maskEnabled: blur > 0
        maskSource: wrapper
        blurMax: 18
        blur: 0.0
        brightness: 0.0
    }

    transform: [
        Scale {
            id: flipScale
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: 1.0
        }
    ]

    SequentialAnimation {
        id: transitionAnimation

        ParallelAnimation {
            NumberAnimation {
                target: flipScale
                property: "xScale"
                to: 0.0
                duration: 300
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: blurEffect
                property: "blur"
                to: 1.0
                duration: 250
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: blurEffect
                property: "brightness"
                to: 0.1
                duration: 300
                easing.type: Easing.InCubic
            }
        }

        PropertyAction {
            target: root
            property: "_activeUrl"
            value: root._pendingUrl
        }

        ParallelAnimation {
            NumberAnimation {
                target: flipScale
                property: "xScale"
                to: 1.0
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.12
            }
            NumberAnimation {
                target: blurEffect
                property: "blur"
                to: 0.0
                duration: 600
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: blurEffect
                property: "brightness"
                to: 0.0
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }
}
