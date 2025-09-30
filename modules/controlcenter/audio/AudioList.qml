pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.small

    RowLayout {
        spacing: Appearance.spacing.smaller

        StyledText {
            text: qsTr("Settings")
            font.pointSize: Appearance.font.size.large
            font.weight: 500
        }

        Item {
            Layout.fillWidth: true
        }

        ToggleButton {
            toggled: !root.session.audio.activeSink && !root.session.audio.activeSource
            icon: "settings"
            accent: "Primary"

            function onClicked(): void {
                if (root.session.audio.activeSink || root.session.audio.activeSource) {
                    root.session.audio.activeSink = null;
                    root.session.audio.activeSource = null;
                } else {
                    root.session.audio.activeSink = Audio.sinks[0] ?? null;
                }
            }
        }
    }

    // Output Devices (Sinks)
    RowLayout {
        Layout.topMargin: Appearance.spacing.large
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Output devices (%1)").arg(Audio.sinks.length)
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("All available audio output devices")
                color: Colours.palette.m3outline
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(implicitHeight, 200)
        spacing: Appearance.spacing.small / 2

        Repeater {
            model: Audio.sinks

            DeviceItem {
                required property var modelData
                
                device: modelData
                isDefault: modelData === Audio.sink
                isSink: true
                
                onClicked: {
                    root.session.audio.activeSink = modelData;
                    root.session.audio.activeSource = null;
                }
                
                onSetDefault: Audio.setAudioSink(modelData)
            }
        }
    }

    // Input Devices (Sources)
    RowLayout {
        Layout.topMargin: Appearance.spacing.large
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Input devices (%1)").arg(Audio.sources.length)
                font.pointSize: Appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("All available audio input devices")
                color: Colours.palette.m3outline
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.small / 2

        Repeater {
            model: Audio.sources

            DeviceItem {
                required property var modelData
                
                device: modelData
                isDefault: modelData === Audio.source
                isSink: false
                
                onClicked: {
                    root.session.audio.activeSource = modelData;
                    root.session.audio.activeSink = null;
                }
                
                onSetDefault: Audio.setAudioSource(modelData)
            }
        }
    }

    component DeviceItem: StyledRect {
        id: deviceItem
        
        required property var device
        required property bool isDefault
        required property bool isSink
        
        signal clicked()
        signal setDefault()

        Layout.fillWidth: true
        implicitHeight: deviceInner.implicitHeight + Appearance.padding.normal * 2

        color: Qt.alpha(Colours.tPalette.m3surfaceContainer, 
            (isSink && root.session.audio.activeSink === device) || 
            (!isSink && root.session.audio.activeSource === device) ? 
            Colours.tPalette.m3surfaceContainer.a : 0)
        radius: Appearance.rounding.normal

        StateLayer {
            id: deviceStateLayer

            function onClicked(): void {
                deviceItem.clicked();
            }
        }

        RowLayout {
            id: deviceInner

            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: deviceIcon.implicitHeight + Appearance.padding.normal * 2

                radius: Appearance.rounding.normal
                color: deviceItem.isDefault ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                StyledRect {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha(deviceItem.isDefault ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface, deviceStateLayer.pressed ? 0.1 : deviceStateLayer.containsMouse ? 0.08 : 0)
                }

                MaterialIcon {
                    id: deviceIcon

                    anchors.centerIn: parent
                    text: deviceItem.isSink ? "speaker" : "mic"
                    color: deviceItem.isDefault ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.large
                    fill: deviceItem.isDefault ? 1 : 0

                    Behavior on fill {
                        Anim {}
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: deviceItem.device.description || deviceItem.device.name || qsTr("Unknown Device")
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: (deviceItem.isDefault ? qsTr("(Default) ") : "") + qsTr("Volume: %1%").arg(Math.round((deviceItem.device.audio?.volume ?? 0) * 100))
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: defaultIcon.implicitHeight + Appearance.padding.smaller * 2

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primaryContainer, deviceItem.isDefault ? 1 : 0)

                StateLayer {
                    color: deviceItem.isDefault ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                    function onClicked(): void {
                        deviceItem.setDefault();
                    }
                }

                MaterialIcon {
                    id: defaultIcon

                    anchors.centerIn: parent
                    text: deviceItem.isDefault ? "check_circle" : "radio_button_unchecked"
                    color: deviceItem.isDefault ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }
        }
    }

    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon
        property string label
        property string accent: "Secondary"

        function onClicked(): void {
        }

        Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Appearance.padding.normal * 2 : toggled ? Appearance.padding.small * 2 : 0)
        implicitWidth: toggleBtnInner.implicitWidth + Appearance.padding.large * 2
        implicitHeight: toggleBtnIcon.implicitHeight + Appearance.padding.normal * 2

        radius: toggled || toggleStateLayer.pressed ? Appearance.rounding.small : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
        color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]

        StateLayer {
            id: toggleStateLayer

            color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]

            function onClicked(): void {
                toggleBtn.onClicked();
            }
        }

        RowLayout {
            id: toggleBtnInner

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            MaterialIcon {
                id: toggleBtnIcon

                visible: !!text
                fill: toggleBtn.toggled ? 1 : 0
                text: toggleBtn.icon
                color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                font.pointSize: Appearance.font.size.large

                Behavior on fill {
                    Anim {}
                }
            }

            Loader {
                asynchronous: true
                active: !!toggleBtn.label
                visible: active

                sourceComponent: StyledText {
                    text: toggleBtn.label
                    color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                }
            }
        }

        Behavior on radius {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}
