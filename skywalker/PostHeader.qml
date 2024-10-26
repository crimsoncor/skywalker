import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import skywalker

GridLayout {
    required property basicprofile author
    required property int postIndexedSecondsAgo
    required property int postThreadType

    id: postHeader
    columns: 2
    rowSpacing: 0

    SkyCleanedText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        plainText: postHeader.author.name
        font.bold: true
        color: guiSettings.textColor

        Accessible.ignored: true
    }
    Text {
        text: guiSettings.durationToString(postHeader.postIndexedSecondsAgo)
        font.pointSize: guiSettings.scaledFont(7/8)
        color: Material.color(Material.Grey)

        Accessible.ignored: true
    }

    Text {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        bottomPadding: 5
        elide: Text.ElideRight
        text: "@" + postHeader.author.handle
        font.pointSize: guiSettings.scaledFont(7/8)
        color: guiSettings.handleColor

        Accessible.ignored: true
    }

    Rectangle {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        Layout.preferredHeight: postHeader.author.labels ? contentLabels.height + 5 : 0
        color: "transparent"

        ContentLabels {
            id: contentLabels
            anchors.left: parent.left
            anchors.right: undefined
            contentLabels: postHeader.author.labels
            contentAuthorDid: postHeader.author.did
        }
    }

    GuiSettings {
        id: guiSettings
    }
}
