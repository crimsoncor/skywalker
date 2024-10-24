import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import skywalker

Dialog {
    required property bool suggestive
    required property bool nudity
    required property bool porn
    required property bool gore

    id: contentWarningDialog
    width: parent.width
    contentHeight: warningColumn.height
    title: qsTr("Adult content warning")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: parent
    Material.background: guiSettings.backgroundColor

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: warningColumn.height
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: warningColumn
            width: parent.width

            AccessibleCheckBox {
                checked: contentWarningDialog.suggestive
                text: qsTr("Sexually suggestive")
                onCheckedChanged: contentWarningDialog.suggestive = checked
            }
            AccessibleCheckBox {
                checked: contentWarningDialog.nudity
                text: qsTr("Non-sexual Nudity")
                onCheckedChanged: contentWarningDialog.nudity = checked
            }
            AccessibleCheckBox {
                checked: contentWarningDialog.porn
                text: qsTr("Adult Content, e.g. pornography")
                onCheckedChanged: contentWarningDialog.porn = checked
            }
            AccessibleCheckBox {
                checked: contentWarningDialog.gore
                text: qsTr("Graphic Media, e.g. violent/bloody")
                onCheckedChanged: contentWarningDialog.gore = checked
            }
        }
    }

    GuiSettings {
        id: guiSettings
    }
}
