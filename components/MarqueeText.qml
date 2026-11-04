import QtQuick
import QtQuick.Effects

Item {
    id: root

    enum StringMode {
        Once,
        Loop
    }

    // Default config
    property string text: ""
    property font textFont: Qt.font({
        family: "BDO Grotesk",
        pixelSize: 13,
        weight: Font.DemiBold
    })
    property color textColor: "white"

    property int stringMode: MarqueeText.StringMode.Once
    property bool running: false
    property real edgePadding: 6
    property real loopGap: 28

    // Fade config
    property bool enableFade: true
    property real fadeWidth: 14

    // Animation config
    property int startDelay: 1000
    property real speed: 0.04
    property real minOverflow: 2.0
    property real tolerance: 0.5

    // Kinematics config
    property real maxAccelDist: 24.0
    property real accelDivisor: 3.0
    property real speedMultiplier: 0.5

    implicitHeight: _measurer.height

    // Hidden measurer for exact font metrics
    TextMetrics {
        id: _measurer
        text: root.text
        font: root.textFont
    }

    // Encapsulated logic and state tracking (Phase-Aware Engine)
    QtObject {
        id: internal

        readonly property real exactWidth: _measurer.advanceWidth
        readonly property real availableWidth: root.width - (root.edgePadding * 2)
        readonly property real rawOverflow: exactWidth - availableWidth

        readonly property real overflowDist: Math.max(0, rawOverflow)
        readonly property bool needsScroll: overflowDist > root.minOverflow
        readonly property real loopStride: exactWidth + root.loopGap

        property bool isLoopReset: false

        // Tracking coordinates for dynamic kinematic calculations
        property real lastAccelStart: 0
        property real lastAccelEnd: 0
        property real lastDecelStart: 0
        property real lastDecelEnd: 0
    }

    // Visual structure
    Item {
        id: _contentWrapper
        anchors.fill: parent
        layer.enabled: true
        clip: true

        Item {
            id: _track
            x: root.edgePadding
            width: internal.loopStride * 2
            height: parent.height

            Text {
                text: root.text
                font: root.textFont
                color: root.textColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                x: internal.loopStride
                text: root.text
                font: root.textFont
                color: root.textColor
                anchors.verticalCenter: parent.verticalCenter
                // Relies purely on needsScroll so it doesn't vanish instantly on hover out
                opacity: internal.needsScroll ? 1.0 : 0.0
            }
        }
    }

    // Gradient mask system
    Item {
        id: _fadeMaskSource
        anchors.fill: parent
        layer.enabled: true

        readonly property real safeRatio: Math.min(0.45, root.fadeWidth / Math.max(1.0, root.width))

        Rectangle {
            width: parent.width
            height: parent.height

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: _fadeMaskSource.safeRatio
                    color: "black"
                }
                GradientStop {
                    position: 1.0 - _fadeMaskSource.safeRatio
                    color: "black"
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: _contentWrapper
        maskEnabled: true
        maskSource: _fadeMaskSource
        maskThresholdMin: 0.4
        maskSpreadAtMin: 1.0
        visible: root.enableFade
    }

    // State management and resets
    function _resetAndCheckScroll() {
        _startDelay.stop();
        _masterAnim.stop();
        _track.x = root.edgePadding;
        internal.isLoopReset = false;

        if (root.running && internal.needsScroll) {
            _startDelay.restart();
        }
    }

    onTextChanged: Qt.callLater(_resetAndCheckScroll)

    onVisibleChanged: {
        if (!visible) {
            _startDelay.stop();
            _masterAnim.stop();
            _track.x = root.edgePadding;
            internal.isLoopReset = false;
        } else if (root.running && internal.needsScroll) {
            _startDelay.restart();
        }
    }

    onRunningChanged: {
        if (running) {
            _resetAndCheckScroll();
        } else {
            _startDelay.stop();
            _masterAnim.stop();
        }
    }

    onStringModeChanged: {
        if (root.running && internal.needsScroll && !_startDelay.running) {
            // Note: _masterAnim.stop() is now handled inside _runCycle to read state first
            _runCycle();
        }
    }

    // Phase-Aware Kinetic Engine
    function _runCycle() {
        if (!internal.needsScroll)
            return;
        const currentX = _track.x;
        const isLoop = root.stringMode === MarqueeText.StringMode.Loop;
        const targetX = isLoop ? (root.edgePadding - internal.loopStride) : (root.edgePadding - internal.overflowDist);

        const isOvershot = !isLoop && currentX <= targetX;
        const wasRunning = _masterAnim.running;

        _masterAnim.stop();

        // If switching to Once mode but already past the Once limit, stop dead to hold position
        if (isOvershot)
            return;
        const remainingDist = Math.abs(targetX - currentX);

        if (remainingDist < root.tolerance) {
            if (isLoop) {
                _track.x = root.edgePadding;
                internal.isLoopReset = true;
                _runCycle();
            }
            return;
        }

        // Dynamic acceleration logic
        let accelDist = 0;

        if (internal.isLoopReset) {
            // Constant velocity: No acceleration during loop wrap-around
            accelDist = 0;
        } else if (!wasRunning) {
            // Initial start or resume from stop: Full acceleration
            accelDist = root.maxAccelDist;
        } else {
            const decelTotal = internal.lastDecelStart - internal.lastDecelEnd;
            const accelTotal = internal.lastAccelStart - internal.lastAccelEnd;

            // Note: coordinates decrease as track moves left
            if (decelTotal > 0.1 && currentX <= internal.lastDecelStart && currentX > internal.lastDecelEnd) {
                // Interrupted during deceleration: Proportional recovery based on lost speed
                const progress = (internal.lastDecelStart - currentX) / decelTotal;
                accelDist = root.maxAccelDist * progress;
            } else if (accelTotal > 0.1 && currentX <= internal.lastAccelStart && currentX > internal.lastAccelEnd) {
                // Interrupted during acceleration: Fulfill the remaining required force
                const progress = (internal.lastAccelStart - currentX) / accelTotal;
                accelDist = root.maxAccelDist * (1.0 - progress);
            } else {
                // Cruising phase: Maintain momentum
                accelDist = 0;
            }
        }

        // Safety clamp ensures accel doesn't consume more than its allowed fraction of the trip
        accelDist = Math.min(accelDist, remainingDist / root.accelDivisor);

        const decelDist = isLoop ? 0 : Math.min(root.maxAccelDist, remainingDist / root.accelDivisor);
        const cruiseDist = remainingDist - accelDist - decelDist;

        // Save kinematics for the next potential interruption
        internal.lastAccelStart = currentX;
        internal.lastAccelEnd = currentX - accelDist;
        internal.lastDecelStart = currentX - accelDist - cruiseDist;
        internal.lastDecelEnd = targetX;

        const speedScaled = root.speed * root.speedMultiplier;
        _accelAnim.duration = accelDist > 0 ? accelDist / speedScaled : 0;
        _accelAnim.from = currentX;
        _accelAnim.to = internal.lastAccelEnd;

        _cruiseAnim.duration = cruiseDist > 0 ? cruiseDist / root.speed : 0;
        _cruiseAnim.from = internal.lastAccelEnd;
        _cruiseAnim.to = internal.lastDecelStart;

        _decelAnim.duration = decelDist > 0 ? decelDist / speedScaled : 0;
        _decelAnim.from = internal.lastDecelStart;
        _decelAnim.to = internal.lastDecelEnd;

        _masterAnim.restart();
    }

    Timer {
        id: _startDelay
        interval: root.startDelay
        onTriggered: root._runCycle()
    }

    SequentialAnimation {
        id: _masterAnim

        NumberAnimation {
            id: _accelAnim
            target: _track
            property: "x"
            easing.type: Easing.InSine
        }
        NumberAnimation {
            id: _cruiseAnim
            target: _track
            property: "x"
            easing.type: Easing.Linear
        }
        NumberAnimation {
            id: _decelAnim
            target: _track
            property: "x"
            easing.type: Easing.OutSine
        }

        ScriptAction {
            script: {
                if (root.stringMode === MarqueeText.StringMode.Loop) {
                    _track.x = root.edgePadding;
                    internal.isLoopReset = true;
                    root._runCycle();
                } else {
                    internal.isLoopReset = false;
                }
            }
        }
    }
}
