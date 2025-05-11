pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import Qt.labs.platform

Singleton {
    id: root

    readonly property list<Connections> sortOrder: []
    readonly property list<MprisPlayer> list: [...Mpris.players.values].sort((a, b) => sortOrder.findIndex(c => c.identity === a.identity) - sortOrder.findIndex(c => c.identity === b.identity))
    readonly property MprisPlayer active: list[0] ?? null

    function moveToFront(identity: string): void {
        const index = sortOrder.findIndex(c => c.identity === identity);

        // Ignore if already current or not in list
        if (index < 0)
            return;

        // Move to front
        sortOrder.unshift(sortOrder.splice(index, 1)[0]);
    }

    onSortOrderChanged: store.setText(sortOrder.filter(c => c).map(c => c.identity).join("\n"))

    onListChanged: {
        // Destroy connections for players not in list
        for (const conn of sortOrder) {
            const identity = conn.identity;
            if (!list.some(p => p.identity === identity))
                conn.destroy();
        }

        // Add connections for players not already connected
        for (const player of list) {
            const identity = player.identity;
            console.log(identity, sortOrder.map(c => c.identity), sortOrder.some(c => c.identity === identity));
            if (!sortOrder.some(c => c.identity === identity)) {
                sortOrder.push(updateComp.createObject(root, {
                    target: player,
                    identity
                }));
                console.log("add new", identity, sortOrder.map(c => c.identity), sortOrder.some(c => c.identity === identity));
            }
        }
    }

    FileView {
        id: store

        path: `${StandardPaths.standardLocations(StandardPaths.GenericStateLocation)[0]}/caelestia/players.txt`
        onLoaded: {
            const identities = text().split("\n");
            for (const identity of identities) {
                const player = root.list.find(p => p.identity === identity);
                if (player && !root.sortOrder.some(c => c.identity === identity))
                    root.sortOrder.push(updateComp.createObject(root, {
                        target: player,
                        identity
                    }));
            }
        }
    }

    Component {
        id: updateComp

        Connections {
            required property string identity

            function onIsPlayingChanged(): void {
                root.moveToFront(identity);
            }
        }
    }

    IpcHandler {
        target: "mpris"

        function get(prop: string, index: int): string {
            const player = root.list[index];
            return player ? player[prop] ?? "Invalid property" : "Invalid index";
        }

        function toggle(index: int): void {
            const player = root.list[index];
            if (player && player.canTogglePlaying)
                player.togglePlaying();
        // console.log(root.sortOrder.map(c => c?.identity ?? "null"));
        }

        function list(): string {
            return root.list.map(p => p.identity).join("\n");
        }
    }
}
