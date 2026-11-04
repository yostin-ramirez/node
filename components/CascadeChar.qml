import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Default config
    property string character: ""
    property int staggerDelay: 0
    property font fontConfiguration
    property color color: "white"

    property string _previousCharacter: ""
    property bool _isInitialized: false

    TextMetrics {
        id: metrics
        font: root.fontConfiguration
        text: root.character
    }

    width: metrics.advanceWidth
    height: metrics.height

    onCharacterChanged: {
        if (!_isInitialized) {
            activeText.text = character;
            _previousCharacter = character;
            _isInitialized = true;
            return;
        }

        if (character === _previousCharacter)
            return;

        fadingText.text = _previousCharacter;
        delayTimer.interval = root.staggerDelay;
        delayTimer.start();

        _previousCharacter = character;
    }

    // Stagger delay timer
    Timer {
        id: delayTimer
        repeat: false
        onTriggered: {
            activeText.text = root.character;
            transitionAnimation.restart();
        }
    }

    Text {
        id: fadingText
        font: root.fontConfiguration
        color: root.color
        anchors.centerIn: parent
        visible: false
    }

    Text {
        id: activeText
        font: root.fontConfiguration
        color: root.color
        anchors.centerIn: parent
        opacity: 1.0

        transform: Translate {
            id: activeTranslate
            y: 0
        }
    }

    MultiEffect {
        id: fadingEffect
        source: fadingText
        anchors.fill: fadingText
        visible: opacity > 0
        blurEnabled: blur > 0
        blurMax: 16
        blur: 0.0
        opacity: 0.0
    }

    ParallelAnimation {
        id: transitionAnimation

        NumberAnimation {
            target: fadingEffect
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 300
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: fadingEffect
            property: "blur"
            from: 0.0
            to: 1.0
            duration: 300
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: activeText
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: activeTranslate
            property: "y"
            from: 15
            to: 0
            duration: 500
            easing.type: Easing.OutBack
            easing.overshoot: 1.5
        }
    }
}
