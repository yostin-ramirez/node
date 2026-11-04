import QtQuick

Item {
    id: root

    // Default config
    property var service: null
    property var levels: service ? service.audioLevels : []

    property int barCount: 6
    property color barColor: "white"
    property int barWidth: 2
    property int maxBarHeight: 24
    property real barSpacing: 1.6
    property real barSensitivity: 0.8

    implicitWidth: (barWidth * barCount) + (barSpacing * (Math.max(0, barCount - 1)))
    implicitHeight: maxBarHeight

    anchors {
        leftMargin: 2
        rightMargin: 4
    }

    // Set bars to service
    Component.onCompleted: {
        if (service) {
            service.setupBars(root.barCount);
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.barSpacing

        Repeater {
            // Evaluates only when the array length changes, not on value updates
            model: root.barCount

            Rectangle {
                width: root.barWidth
                radius: root.barWidth / 2
                color: root.barColor
                anchors.verticalCenter: parent.verticalCenter

                // Height re-evaluates automatically when root.levels reference changes
                height: {
                    const val = root.levels[index];
                    const h = (val !== undefined ? val : 0) * root.maxBarHeight * root.barSensitivity;
                    return h < 2 ? 2 : h; // Faster than Math.max
                }
            }
        }
    }
}
