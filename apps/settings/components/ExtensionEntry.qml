import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../shared/qml/controls" as LiquidControls

// A compact catalogue row, shared by downloadable apps and optional services.
Rectangle {
    id: entry
    required property var colors
    required property string title
    property string description: ""
    property string iconName: "grid"
    property color iconColor: "#5b7cfa"
    property string actionText: ""
    property bool actionEnabled: true
    property string actionObjectName: ""
    default property alias details: detailsColumn.data
    signal activated()

    implicitHeight: content.implicitHeight + 36
    radius: 16
    color: colors.card

    data: [ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 13
                color: entry.iconColor
                LiquidControls.VectorIcon {
                    anchors.centerIn: parent
                    size: 30
                    name: entry.iconName
                    color: "white"
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    Layout.fillWidth: true
                    text: entry.title
                    color: entry.colors.primaryText
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    text: entry.description
                    color: entry.colors.secondaryText
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }
            Button {
                id: action
                objectName: entry.actionObjectName
                text: entry.actionText
                enabled: entry.actionEnabled
                implicitWidth: Math.max(80, implicitContentWidth + 28)
                implicitHeight: 32
                focusPolicy: Qt.StrongFocus
                Accessible.name: entry.title + ": " + text
                onClicked: entry.activated()
                contentItem: Text {
                    text: action.text
                    color: entry.colors.accent
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: action.enabled ? 1 : 0.5
                }
                background: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(entry.colors.accent.r, entry.colors.accent.g, entry.colors.accent.b,
                        action.down ? 0.2 : action.hovered ? 0.14 : 0.09)
                    border.width: action.visualFocus ? 2 : 0
                    border.color: entry.colors.accent
                }
            }
        }
        ColumnLayout {
            id: detailsColumn
            Layout.fillWidth: true
            spacing: 8
        }
    }]
}
