import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Default config
    property string titleText: ""
    property string artistText: ""
    property string icon: ""
    property color iconColor: "white"
    property color textColor: "white"
    property font textFont: Qt.font({
        family: "BDO Grotesk",
        pixelSize: 13,
        weight: Font.DemiBold
    })
    property int spacing: 2

    // Controls visibility + marquee start/stop
    property bool active: false

    // Passed down to MarqueeText — determines scroll behavior
    property int triggerMode: MarqueeText.StringMode.Once

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    visible: active || _transition.running || fadingEffect.opacity > 0

    // Mirror active changes to marquee running state
    onActiveChanged: {
        marquee.running = active;
        _transition.stop();
        _transition.toState = active ? 1.0 : 0.0;
        _transition.start();
    }

    Row {
        id: contentRow
        anchors.fill: parent
        spacing: root.spacing
        visible: false

        Text {
            id: sourceIcon
            text: root.icon
            color: root.iconColor
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        MarqueeText {
            id: marquee
            width: parent.width - sourceIcon.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter

            text: root.titleText + " \u2022 " + root.artistText
            textFont: root.textFont
            textColor: root.textColor
            stringMode: root.triggerMode
            // running is driven by onActiveChanged above
        }
    }

    MultiEffect {
        id: fadingEffect
        source: contentRow
        anchors.fill: contentRow
        visible: opacity > 0
        blurEnabled: blur > 0
        blurMax: 24
        blur: 0.0
        opacity: 0.0
    }

    ParallelAnimation {
        id: _transition
        property real toState: 0.0

        NumberAnimation {
            target: fadingEffect
            property: "opacity"
            to: _transition.toState
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: fadingEffect
            property: "blur"
            to: 1.0 - _transition.toState
            duration: 350
            easing.type: Easing.OutQuad
        }
    }
}
