pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "volume_up"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Audio settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Output device")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Default audio output settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: outputSettings.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: outputSettings

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
                    text: qsTr("Current output device")
                }

                StyledText {
                    text: Audio.sink?.description || Audio.sink?.name || qsTr("None")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Output volume")
                }

                StyledSlider {
                    from: 0
                    to: 1
                    value: Audio.volume
                    onMoved: Audio.setVolume(value)
                }
            }

            Toggle {
                label: qsTr("Muted")
                checked: Audio.muted
                toggle.onToggled: {
                    if (Audio.sink?.audio)
                        Audio.sink.audio.muted = checked;
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Input device")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Default audio input settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: inputSettings.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: inputSettings

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
                    text: qsTr("Current input device")
                }

                StyledText {
                    text: Audio.source?.description || Audio.source?.name || qsTr("None")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.small
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Input volume")
                }

                StyledSlider {
                    from: 0
                    to: 1
                    value: Audio.sourceVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }

            Toggle {
                label: qsTr("Muted")
                checked: Audio.sourceMuted
                toggle.onToggled: {
                    if (Audio.source?.audio)
                        Audio.source.audio.muted = checked;
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
