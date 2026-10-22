import QtQuick
import QtTest
import "../.." as Settings
import "../../../../shared/qml/i18n"

TestCase {
    name: "SpatialServices"
    when: windowShown
    visible: true
    width: 760
    height: 300
    QtObject {
        id: bridge
        property int starts: 0
        property int stops: 0
        signal wallpaperSnapshotChanged(var state)
        function wallpaperSnapshot() {}
        function inspectSpatialService() {}
        function initializeSpatialService() { starts++ }
        function disableSpatialService() { stops++ }
    }
    Component {
        id: factory
        Settings.ServicesSettingsPage {
            width: 700
            height: implicitHeight
            colors: ({card: "#222222", primaryText: "#ffffff", secondaryText: "#aaaaaa", accent: Qt.rgba(10/255, 132/255, 1, 1)})
        }
    }
    function init() {
        bridge.starts = 0
        bridge.stops = 0
        I18n.language = "en"
    }
    function snapshot(state) { bridge.wallpaperSnapshotChanged({spatialResources: state}) }

    function test_action_waits_for_backend() {
        const page = createTemporaryObject(factory, this, {bridge: bridge})
        verify(page)
        const action = findChild(page, "spatialServiceAction")
        verify(action)
        compare(action.enabled, false) // no snapshot yet
        snapshot({available: true, enabled: false, ready: false})
        compare(action.text, "Get")
        verify(action.enabled)
        verify(waitForRendering(page))
        mouseClick(action, action.width / 2, action.height / 2)
        compare(bridge.starts, 1)
        compare(action.text, "Get") // no optimistic completion
        snapshot({available: true, enabled: false, busy: true, progress: 0.5})
        compare(action.enabled, false)
        compare(findChild(page, "spatialServiceProgress").value, 0.5)
        verify(waitForRendering(page))
        mouseClick(action, action.width / 2, action.height / 2)
        compare(bridge.starts, 1)
        snapshot({available: true, enabled: true, ready: true})
        compare(action.text, "Disable")
        action.forceActiveFocus()
        keyClick(Qt.Key_Space)
        compare(bridge.stops, 1)
        snapshot({available: true, enabled: false, ready: true})
        compare(action.text, "Enable")
        verify(waitForRendering(page))
        mouseClick(action, action.width / 2, action.height / 2)
        compare(bridge.starts, 2)
    }
    function test_unavailable_and_retry() {
        const page = createTemporaryObject(factory, this, {bridge: bridge})
        const action = findChild(page, "spatialServiceAction")
        snapshot({available: false})
        compare(action.enabled, false)
        compare(action.text, "Unavailable")
        snapshot({available: true, checking: true})
        compare(action.enabled, false)
        snapshot({available: true, enabled: false, error: "Download failed"})
        compare(findChild(page, "spatialServiceError").text, "Download failed")
        verify(action.enabled)
        verify(waitForRendering(page))
        mouseClick(action, action.width / 2, action.height / 2)
        compare(bridge.starts, 1)
        snapshot({available: true, busy: true, progress: -1})
        verify(findChild(page, "spatialServiceProgress").indeterminate)
        compare(findChild(page, "spatialServiceError").visible, false)
    }
    function test_no_bridge() {
        const page = createTemporaryObject(factory, this)
        compare(findChild(page, "spatialServiceAction").enabled, false)
        compare(findChild(page, "spatialServiceAction").text, "Unavailable")
    }
    function test_appearance_data() {
        return [
            {tag: "light", language: "en", width: 700, colors: {card: "#ffffff", primaryText: "#1c1c1e", secondaryText: "#6d6d72", accent: Qt.rgba(0, 122/255, 1, 1)}},
            {tag: "dark", language: "zh-CN", width: 700, colors: {card: "#222222", primaryText: "#ffffff", secondaryText: "#aaaaaa", accent: Qt.rgba(10/255, 132/255, 1, 1)}},
            {tag: "narrow", language: "en", width: 420, colors: {card: "#ffffff", primaryText: "#1c1c1e", secondaryText: "#6d6d72", accent: Qt.rgba(0, 122/255, 1, 1)}}
        ]
    }
    function test_appearance(data) {
        I18n.language = data.language
        const page = createTemporaryObject(factory, this, {bridge: bridge, colors: data.colors, width: data.width})
        snapshot({available: true, enabled: false, ready: false})
        verify(waitForRendering(page))
        const action = findChild(page, "spatialServiceAction")
        const corner = action.mapToItem(page, action.width, action.height)
        verify(corner.x <= page.width)
        verify(corner.y <= page.height)
        verify(grabImage(page).save("extensions-" + data.tag + ".png"))
    }
}
