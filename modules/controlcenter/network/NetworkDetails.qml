pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property var network: session.network.activeNetwork

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
                text: root.network?.isSecure ? "wifi_password" : Icons.getNetworkIcon(root.network?.strength ?? 0)
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.network?.ssid ?? ""
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Connection settings for this network")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: networkStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: networkStatus

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
                            text: qsTr("Connected")
                        }

                        StyledText {
                            text: root.network?.active ? qsTr("Yes") : qsTr("No")
                            color: root.network?.active ? Colours.palette.m3primary : Colours.palette.m3outline
                            font.weight: 500
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Network properties")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Information about this network")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: networkProps.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: networkProps

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.small / 2

                    StyledText {
                        text: qsTr("Signal strength")
                    }

                    StyledText {
                        text: qsTr("%1%").arg(root.network?.strength ?? 0)
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Frequency")
                    }

                    StyledText {
                        text: qsTr("%1 MHz").arg(root.network?.frequency ?? 0)
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("BSSID")
                    }

                    StyledText {
                        text: root.network?.bssid ?? ""
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }

                    StyledText {
                        Layout.topMargin: Appearance.spacing.normal
                        text: qsTr("Security")
                    }

                    StyledText {
                        text: root.network?.security || qsTr("Open")
                        color: Colours.palette.m3outline
                        font.pointSize: Appearance.font.size.small
                    }
                }
            }
        }
    }
}
