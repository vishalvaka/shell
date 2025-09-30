pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property var device: session.audio.activeSink || session.audio.activeSource
    readonly property bool isSink: session.audio.activeSink !== null

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: layout.height

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: root.isSink ? "speaker" : "mic"
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.device?.description || root.device?.name || qsTr("Unknown Device")
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Device status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Audio settings for this device")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceStatus

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.larger

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Volume")
                        }

                        StyledSlider {
                            from: 0
                            to: 1
                            value: root.device?.audio?.volume ?? 0
                            onMoved: {
                                if (root.device?.audio)
                                    root.device.audio.volume = value;
                            }
                        }

                        StyledText {
                            text: qsTr("%1%").arg(Math.round((root.device?.audio?.volume ?? 0) * 100))
                            color: Colours.palette.m3outline
                        }
                    }

                    Toggle {
                        label: qsTr("Muted")
                        checked: root.device?.audio?.muted ?? false
                        toggle.onToggled: {
                            if (root.device?.audio)
                                root.device.audio.muted = checked;
                        }
                    }

                    Toggle {
                        label: qsTr("Set as default")
                        checked: root.isSink ? (root.device === Audio.sink) : (root.device === Audio.source)
                        toggle.onToggled: {
                            if (root.isSink)
                                Audio.setAudioSink(root.device);
                            else
                                Audio.setAudioSource(root.device);
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Device information")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Information about this device")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceInfo.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceInfo

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: qsTr("Device name")
                    }

                    StyledText {
                        text: root.device?.name ?? qsTr("Unknown")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Description")
                    }

                    StyledText {
                        text: root.device?.description ?? qsTr("Unknown")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Type")
                    }

                    StyledText {
                        text: root.isSink ? qsTr("Output (Sink)") : qsTr("Input (Source)")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle

            cLayer: 2
        }
    }
}
