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
        text: "wifi"
        font.pointSize: Appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("WiFi settings")
        font.pointSize: Appearance.font.size.large
        font.bold: true
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("WiFi status")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("General WiFi settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: wifiStatus.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: wifiStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.larger

            Toggle {
                label: qsTr("WiFi Enabled")
                checked: Network.wifiEnabled
                toggle.onToggled: Network.enableWifi(checked)
            }
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.large
        text: qsTr("Connection information")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Information about active connection")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: connectionInfo.implicitHeight + Appearance.padding.large * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: connectionInfo

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Appearance.padding.large

            spacing: Appearance.spacing.small / 2

            StyledText {
                text: qsTr("Active network")
            }

            StyledText {
                text: Network.active?.ssid ?? qsTr("Not connected")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Signal strength")
            }

            StyledText {
                text: Network.active ? qsTr("%1%").arg(Network.active.strength) : qsTr("N/A")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                text: qsTr("Frequency")
            }

            StyledText {
                text: Network.active ? qsTr("%1 MHz").arg(Network.active.frequency) : qsTr("N/A")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.small
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
