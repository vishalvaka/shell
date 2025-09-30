pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property bool smallWifiEnabled: width <= 540
    
    property string connectionStatus: ""
    property string connectionStatusType: "" // "success" or "error"
    property string dialogError: ""

    // Connection status signals
    Connections {
        target: Network
        
        function onConnectionSuccess(ssid: string): void {
            root.connectionStatus = qsTr("Connected to %1").arg(ssid);
            root.connectionStatusType = "success";
            root.dialogError = "";
            passwordDialogLoader.active = false; // Close dialog on success
            statusTimer.restart();
        }
        
        function onConnectionFailed(ssid: string, error: string): void {
            root.connectionStatus = error;
            root.connectionStatusType = "error";
            statusTimer.restart();
            
            // If dialog is open, show error in dialog instead of closing
            if (passwordDialogLoader.active && passwordDialogLoader.targetNetwork?.ssid === ssid) {
                root.dialogError = error;
            }
        }
    }
    
    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: {
            root.connectionStatus = "";
            root.connectionStatusType = "";
        }
    }

    // Password Dialog Overlay
    Loader {
        id: passwordDialogLoader
        
        property var targetNetwork: null
        
        anchors.fill: parent
        z: 1000
        active: false
        
        sourceComponent: Item {
            anchors.fill: parent
            
            MouseArea {
                anchors.fill: parent
                onClicked: passwordDialogLoader.active = false
            }
            
            StyledRect {
                anchors.centerIn: parent
                implicitWidth: Math.min(parent.width - Appearance.padding.large * 4, 400)
                implicitHeight: dialogContent.implicitHeight + Appearance.padding.large * 4
                
                radius: Appearance.rounding.normal
                color: Colours.palette.m3surfaceContainerHigh
                
                Elevation {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    level: 3
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {} // Prevent clicks from passing through
                }
                
                ColumnLayout {
                    id: dialogContent
                    
                    anchors.centerIn: parent
                    width: parent.width - Appearance.padding.large * 4
                    spacing: Appearance.spacing.large
                    
                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "wifi_password"
                        font.pointSize: Appearance.font.size.extraLarge * 2
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Enter WiFi Password")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: passwordDialogLoader.targetNetwork?.ssid ?? ""
                        color: Colours.palette.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                    }
                    
                    // Error display
                    Loader {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        active: root.dialogError !== ""
                        visible: active
                        
                        sourceComponent: StyledRect {
                            implicitHeight: errorText.implicitHeight + Appearance.padding.small * 2
                            implicitWidth: errorText.implicitWidth + Appearance.padding.normal * 2
                            radius: Appearance.rounding.small
                            color: Colours.palette.m3errorContainer
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacing.small
                                
                                MaterialIcon {
                                    text: "error"
                                    color: Colours.palette.m3onErrorContainer
                                    font.pointSize: Appearance.font.size.normal
                                }
                                
                                StyledText {
                                    id: errorText
                                    text: root.dialogError
                                    color: Colours.palette.m3onErrorContainer
                                    font.pointSize: Appearance.font.size.normal
                                }
                            }
                        }
                    }
                    
                    StyledTextField {
                        id: passwordField
                        
                        Layout.fillWidth: true
                        placeholderText: qsTr("Password")
                        echoMode: TextInput.Password
                        
                        Component.onCompleted: forceActiveFocus()
                        
                        onTextChanged: {
                            // Clear error when user starts typing
                            if (root.dialogError) {
                                root.dialogError = "";
                            }
                        }
                        
                        onAccepted: {
                            if (text.length > 0) {
                                Network.connectToNetwork(passwordDialogLoader.targetNetwork.ssid, text);
                            }
                        }
                        
                        Keys.onEscapePressed: {
                            root.dialogError = "";
                            passwordDialogLoader.active = false;
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal
                        
                        Item {
                            Layout.fillWidth: true
                        }
                        
                        StyledRect {
                            implicitWidth: cancelLabel.implicitWidth + Appearance.padding.large * 2
                            implicitHeight: cancelLabel.implicitHeight + Appearance.padding.normal * 2
                            radius: Appearance.rounding.small
                            color: "transparent"
                            
                            StateLayer {
                                color: Colours.palette.m3primary
                                
                                function onClicked(): void {
                                    root.dialogError = "";
                                    passwordDialogLoader.active = false;
                                }
                            }
                            
                            StyledText {
                                id: cancelLabel
                                anchors.centerIn: parent
                                text: qsTr("Cancel")
                                color: Colours.palette.m3primary
                            }
                        }
                        
                        StyledRect {
                            implicitWidth: connectLabel.implicitWidth + Appearance.padding.large * 2
                            implicitHeight: connectLabel.implicitHeight + Appearance.padding.normal * 2
                            radius: Appearance.rounding.small
                            color: Colours.palette.m3primary
                            
                            StateLayer {
                                color: Colours.palette.m3onPrimary
                                
                                function onClicked(): void {
                                    if (passwordField.text.length > 0) {
                                        root.dialogError = ""; // Clear any previous errors
                                        Network.connectToNetwork(passwordDialogLoader.targetNetwork.ssid, passwordField.text);
                                        // Don't close dialog - wait for success/error signal
                                    }
                                }
                            }
                            
                            StyledText {
                                id: connectLabel
                                anchors.centerIn: parent
                                text: qsTr("Connect")
                                color: Colours.palette.m3onPrimary
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
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
                toggled: Network.wifiEnabled
                icon: "power"
                accent: "Tertiary"

                function onClicked(): void {
                    Network.toggleWifi();
                }
            }

            ToggleButton {
                toggled: !root.session.network.activeNetwork
                icon: "settings"
                accent: "Primary"

                function onClicked(): void {
                    if (root.session.network.activeNetwork)
                        root.session.network.activeNetwork = null;
                    else {
                        root.session.network.activeNetwork = networkModel.values[0] ?? null;
                    }
                }
            }
        }
        
        // Connection Status Banner
        Loader {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.normal
            active: root.connectionStatus !== ""
            visible: active
            
            sourceComponent: StyledRect {
                implicitHeight: statusText.implicitHeight + Appearance.padding.normal * 2
                radius: Appearance.rounding.normal
                color: root.connectionStatusType === "success" 
                    ? Colours.palette.m3tertiaryContainer 
                    : Colours.palette.m3errorContainer
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal
                    
                    MaterialIcon {
                        text: root.connectionStatusType === "success" ? "check_circle" : "error"
                        color: root.connectionStatusType === "success" 
                            ? Colours.palette.m3onTertiaryContainer 
                            : Colours.palette.m3onErrorContainer
                    }
                    
                    StyledText {
                        id: statusText
                        Layout.fillWidth: true
                        text: root.connectionStatus
                        color: root.connectionStatusType === "success" 
                            ? Colours.palette.m3onTertiaryContainer 
                            : Colours.palette.m3onErrorContainer
                    }
                }
            }
        }

        // Saved Networks Section
        Loader {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.large
            active: Network.savedNetworks.length > 0
            visible: active
            
            sourceComponent: ColumnLayout {
                spacing: Appearance.spacing.small
                
                StyledText {
                    text: qsTr("Saved Networks (%1)").arg(Network.savedNetworks.length)
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }
                
                StyledListView {
                    id: savedView
                    
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 200)
                    clip: true
                    spacing: Appearance.spacing.small / 2
                    
                    model: ScriptModel {
                        values: [...Network.savedNetworks]
                    }
                    
                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: savedView
                    }
                    
                    delegate: StyledRect {
                        required property var modelData
                        
                        width: savedView.width
                        implicitHeight: savedInner.implicitHeight + Appearance.padding.normal * 2
                        
                        color: Colours.tPalette.m3surfaceContainerHigh
                        radius: Appearance.rounding.normal
                        
                        RowLayout {
                            id: savedInner
                            
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.normal
                            spacing: Appearance.spacing.normal
                            
                            MaterialIcon {
                                text: "wifi_lock"
                                color: Colours.palette.m3primary
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.ssid
                                elide: Text.ElideRight
                            }
                            
                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: connectSavedIcon.implicitHeight + Appearance.padding.smaller * 2
                                
                                radius: Appearance.rounding.full
                                color: Colours.palette.m3primaryContainer
                                
                                StateLayer {
                                    color: Colours.palette.m3onPrimaryContainer
                                    
                                    function onClicked(): void {
                                        Network.connectToNetwork(modelData.ssid, "");
                                    }
                                }
                                
                                MaterialIcon {
                                    id: connectSavedIcon
                                    anchors.centerIn: parent
                                    text: "link"
                                    color: Colours.palette.m3onPrimaryContainer
                                }
                            }
                            
                            StyledRect {
                                implicitWidth: implicitHeight
                                implicitHeight: forgetIcon.implicitHeight + Appearance.padding.smaller * 2
                                
                                radius: Appearance.rounding.full
                                color: "transparent"
                                
                                StateLayer {
                                    color: Colours.palette.m3error
                                    
                                    function onClicked(): void {
                                        Network.forgetNetwork(modelData.ssid);
                                    }
                                }
                                
                                MaterialIcon {
                                    id: forgetIcon
                                    anchors.centerIn: parent
                                    text: "delete"
                                    color: Colours.palette.m3error
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.topMargin: Appearance.spacing.large
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Available Networks (%1)").arg(Network.networks.length)
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Nearby WiFi networks")
                    color: Colours.palette.m3outline
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: scanIcon.implicitHeight + Appearance.padding.normal * 2

                radius: Network.scanning ? Appearance.rounding.normal : implicitHeight / 2 * Math.min(1, Appearance.rounding.scale)
                color: Network.scanning ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                StateLayer {
                    color: Network.scanning ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer

                    function onClicked(): void {
                        Network.rescanWifi();
                    }
                }

                MaterialIcon {
                    id: scanIcon

                    anchors.centerIn: parent
                    animate: true
                    text: "wifi_find"
                    color: Network.scanning ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                    fill: Network.scanning ? 1 : 0
                }

                Behavior on radius {
                    Anim {}
                }
            }
        }

        StyledListView {
            id: view

            model: ScriptModel {
                id: networkModel

                values: [...Network.networks].sort((a, b) => (b.active - a.active) || (b.strength - a.strength))
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacing.small / 2

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: view
            }

            delegate: StyledRect {
                id: networkItem

                required property var modelData
                readonly property bool connected: modelData.active
                readonly property bool isSaved: Network.isNetworkSaved(modelData.ssid)

                width: view.width
                implicitHeight: networkInner.implicitHeight + Appearance.padding.normal * 2

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.network.activeNetwork === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Appearance.rounding.normal

                StateLayer {
                    id: stateLayer

                    function onClicked(): void {
                        root.session.network.activeNetwork = networkItem.modelData;
                    }
                }

                RowLayout {
                    id: networkInner

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal

                    spacing: Appearance.spacing.normal

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: icon.implicitHeight + Appearance.padding.normal * 2

                        radius: Appearance.rounding.normal
                        color: networkItem.connected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                        StyledRect {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.alpha(networkItem.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface, stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0)
                        }

                        MaterialIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: networkItem.modelData.isSecure ? "wifi_password" : Icons.getNetworkIcon(networkItem.modelData.strength)
                            color: networkItem.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            font.pointSize: Appearance.font.size.large
                            fill: networkItem.connected ? 1 : 0

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
                            text: networkItem.modelData.ssid
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Signal: %1%").arg(networkItem.modelData.strength) + (networkItem.connected ? qsTr(" (Connected)") : "") + (networkItem.isSaved ? qsTr(" • Saved") : "") + (networkItem.modelData.isSecure ? qsTr(" • Secured") : "")
                            color: Colours.palette.m3outline
                            font.pointSize: Appearance.font.size.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledRect {
                        id: connectBtn

                        implicitWidth: implicitHeight
                        implicitHeight: connectIcon.implicitHeight + Appearance.padding.smaller * 2

                        radius: Appearance.rounding.full
                        color: Qt.alpha(Colours.palette.m3primaryContainer, networkItem.connected ? 1 : 0)

                        StateLayer {
                            color: networkItem.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                            function onClicked(): void {
                                if (networkItem.modelData.active) {
                                    Network.disconnectFromNetwork();
                                } else if (networkItem.isSaved) {
                                    // Network is saved, connect directly
                                    Network.connectToNetwork(networkItem.modelData.ssid, "");
                                } else if (networkItem.modelData.isSecure) {
                                    // Network requires password
                                    root.dialogError = ""; // Clear any previous errors
                                    passwordDialogLoader.targetNetwork = networkItem.modelData;
                                    passwordDialogLoader.active = true;
                                } else {
                                    // Open network, connect directly
                                    Network.connectToNetwork(networkItem.modelData.ssid, "");
                                }
                            }
                        }

                        MaterialIcon {
                            id: connectIcon

                            anchors.centerIn: parent
                            animate: true
                            text: networkItem.modelData.active ? "link_off" : "link"
                            color: networkItem.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }
                    }
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
