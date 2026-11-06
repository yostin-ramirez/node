import QtQuick
import qs.services
import qs.modules

// Mounts and unmounts modules based on NotchState.primaryScene.
// Decision logic lives entirely in NotchState — this component only reacts.
Item {
    id: root

    implicitHeight: currentLoader.item ? currentLoader.item.implicitHeight : Config.notch.height
    implicitWidth: currentLoader.item ? currentLoader.item.implicitWidth : Config.notch.width

    // Exposed to NotchBackground for bottom-edge content (e.g. progress bar)
    property alias bottomSlot: bottomSlotContainer

    // Module registry: maps scene name -> component factory
    // To add a new module: register it here and create its Module file
    readonly property var _registry: ({
        "media": mediaComponent,
        "none": null
    })

    Component {
        id: mediaComponent
        MediaModule {
            bottomTarget: bottomSlotContainer
        }
    }

    property string _loadedScene: ""

    Connections {
        target: NotchState
        function onPrimarySceneChanged() {
            root._switchTo(NotchState.primaryScene);
        }
    }

    Component.onCompleted: _switchTo(NotchState.primaryScene)

    function _switchTo(scene) {
        if (scene === _loadedScene)
            return;
        _loadedScene = scene;

        const component = _registry[scene] ?? null;
        nextLoader.sourceComponent = component;
        _transition.start();
    }

    // Holds the currently visible module
    Loader {
        id: currentLoader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomSlotContainer.top
        }
    }

    // Pre-renders incoming module before the swap
    Loader {
        id: nextLoader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomSlotContainer.top
        }
        opacity: 0
        scale: 0.96
    }

    // Reserved bottom-edge area (e.g. progress bar, flush with notch border)
    Item {
        id: bottomSlotContainer
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: childrenRect.height
    }

    SequentialAnimation {
        id: _transition

        ParallelAnimation {
            NumberAnimation {
                target: currentLoader
                property: "opacity"
                to: 0
                duration: 120
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: currentLoader
                property: "scale"
                to: 0.96
                duration: 120
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: nextLoader
                property: "opacity"
                to: 1
                duration: 160
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: nextLoader
                property: "scale"
                to: 1.0
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                currentLoader.sourceComponent = nextLoader.sourceComponent;
                currentLoader.opacity = 1;
                currentLoader.scale = 1;

                nextLoader.sourceComponent = null;
                nextLoader.opacity = 0;
                nextLoader.scale = 0.96;
            }
        }
    }
}
