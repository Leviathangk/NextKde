import "../../shared/qml/i18n"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components" as Controls

ColumnLayout {
    id: page
    property var bridge: null
    property var colors
    property var resources: ({})
    property string errorText: ""
    property bool snapshotReceived: false
    readonly property bool compatible: !!bridge && typeof bridge.initializeSpatialService === "function"
    readonly property bool checking: !snapshotReceived || !!resources.checking
    readonly property bool available: compatible && resources.available !== false
    spacing: 12

    function refresh() { if (compatible) bridge.wallpaperSnapshot() }
    Component.onCompleted: {
        if (compatible) bridge.inspectSpatialService()
        refresh()
    }
    Connections {
        target: page.bridge
        ignoreUnknownSignals: true
        function onWallpaperSnapshotChanged(state) {
            page.resources = state.spatialResources || ({})
            page.snapshotReceived = !!state.spatialResources
            page.errorText = page.resources.error || ""
        }
    }
    Timer {
        interval: 1000
        running: page.visible && page.compatible
        repeat: true
        onTriggered: page.refresh()
    }

    Controls.ExtensionEntry {
        Layout.fillWidth: true
        colors: page.colors
        title: I18n.tr("Spatial wallpaper")
        description: I18n.tr("Add depth and motion to your wallpaper")
        iconName: "wallpaper"
        actionObjectName: "spatialServiceAction"
        actionText: !page.available ? I18n.tr("Unavailable")
            : page.resources.busy ? I18n.tr("Preparing…")
            : page.checking ? I18n.tr("Checking…")
            : page.resources.enabled ? I18n.tr("Disable")
            : page.resources.ready ? I18n.tr("Enable") : I18n.tr("Get")
        actionEnabled: page.available && !page.resources.busy && !page.checking
        onActivated: {
            if (page.resources.enabled) page.bridge.disableSpatialService()
            else page.bridge.initializeSpatialService()
        }

        Text {
            objectName: "spatialServiceStatus"
            Layout.fillWidth: true
            text: !page.compatible ? I18n.tr("The Settings bridge has not been built")
                : page.resources.available === false
                    ? I18n.tr("This build does not include the spatial wallpaper component")
                : page.resources.busy
                    ? (page.resources.stage || I18n.tr("Preparing…"))
                        + (Number(page.resources.progress) >= 0
                            ? " · " + Math.round(Number(page.resources.progress) * 100) + "%" : "")
                : page.checking ? I18n.tr("Checking resources…")
                : page.resources.enabled ? I18n.tr("Enabled")
                : page.resources.ready ? I18n.tr("Ready to enable")
                : I18n.tr("Required resources are downloaded on first enablement")
            color: page.colors.secondaryText
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
        ProgressBar {
            id: downloadProgress
            objectName: "spatialServiceProgress"
            Layout.fillWidth: true
            visible: !!page.resources.busy
            indeterminate: !(Number(page.resources.progress) >= 0)
            value: Math.max(0, Math.min(1, Number(page.resources.progress) || 0))
            implicitHeight: 4
            background: Rectangle {
                radius: 2
                color: Qt.rgba(page.colors.accent.r, page.colors.accent.g, page.colors.accent.b, 0.1)
            }
            contentItem: Item {
                Rectangle {
                    width: parent.width * (page.resources.progress >= 0 ? downloadProgress.position : 0.3)
                    height: parent.height
                    radius: 2
                    color: page.colors.accent
                    SequentialAnimation on opacity {
                        running: page.resources.busy && !(Number(page.resources.progress) >= 0)
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.4; to: 1; duration: 650 }
                        NumberAnimation { from: 1; to: 0.4; duration: 650 }
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: !!page.resources.ready || Number(page.resources.generatedBytes) > 0
            text: I18n.tr("Cache: ") + (Number(page.resources.generatedBytes || 0) / 1073741824).toFixed(2)
                + I18n.tr(" / 2 GB · oldest entries are pruned automatically")
            color: page.colors.secondaryText
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
        Text {
            objectName: "spatialServiceError"
            Layout.fillWidth: true
            visible: page.errorText.length > 0
            text: page.errorText
            wrapMode: Text.Wrap
            color: page.colors.primaryText
            font.pixelSize: 12
        }
    }
}
