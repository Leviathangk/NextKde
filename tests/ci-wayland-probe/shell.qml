import QtQuick
import Quickshell

ShellRoot {
    PanelWindow {
        implicitWidth: 160
        implicitHeight: 80
        color: "#385b80"
    }
    Timer {
        interval: 2000
        running: true
        onTriggered: {
            console.log("CI_WAYLAND_MINIMAL_FINISHED")
            Qt.quit()
        }
    }
}
