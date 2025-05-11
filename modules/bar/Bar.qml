import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell
import QtQuick

Variants {
    model: Quickshell.screens

    StyledWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        name: "bar"

        exclusiveZone: BarConfig.sizes.exclusiveZone
        width: BarConfig.vertical ? BarConfig.sizes.totalHeight : -1
        height: BarConfig.vertical ? -1 : BarConfig.sizes.totalHeight

        anchors.top: true
        anchors.left: true

        Component.onCompleted: {
            if (BarConfig.vertical)
                win.anchors.bottom = true;
            else
                win.anchors.right = true;
            console.log(Players.list);
        }

        Connections {
            target: BarConfig

            function onVerticalChanged(): void {
                win.visible = false;
                if (BarConfig.vertical) {
                    win.anchors.right = false;
                    win.anchors.bottom = true;
                } else {
                    win.anchors.bottom = false;
                    win.anchors.right = true;
                }
                win.visible = true;
            }
        }

        Item {
            id: content

            anchors.fill: parent

            Preset {
                presetName: "pills"
                sourceComponent: Pills {
                    screen: win.modelData
                }
            }

            Preset {
                presetName: "panel"
                sourceComponent: Panel {
                    screen: win.modelData
                }
            }
        }

        LayerShadow {
            source: content
        }
    }

    component Preset: Loader {
        id: loader

        required property string presetName

        anchors.fill: parent
        asynchronous: true
        active: false
        opacity: 0

        states: State {
            name: "visible"
            when: BarConfig.preset.name === loader.presetName

            PropertyChanges {
                loader.opacity: 1
                loader.active: true
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "visible"

                SequentialAnimation {
                    PropertyAction {}
                    NumberAnimation {
                        property: "opacity"
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            },
            Transition {
                from: "visible"
                to: ""

                SequentialAnimation {
                    NumberAnimation {
                        property: "opacity"
                        duration: Appearance.anim.durations.large
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                    PropertyAction {}
                }
            }
        ]

        Connections {
            target: BarConfig

            function onVerticalChanged(): void {
                if (loader.state === "visible") {
                    loader.active = false;
                    loader.active = true;
                }
            }
        }
    }
}
