import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

Column {
    required property string postUri
    required property string postText
    required property list<imageview> postImages
    required property date postDateTime
    property var postExternal // externalview (var allows NULL)
    property var postRecord // recordview
    property var postRecordWithMedia // record_with_media_view
    property bool detailedView: false
    property int maxTextLines: 1000

    id: postBody

    Text {
        id: bodyText
        width: parent.width
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: maxTextLines
        elide: Text.ElideRight
        textFormat: Text.StyledText
        color: Material.foreground
        text: postText
        bottomPadding: postImages.length > 0 || postExternal || postRecord ? 5 : 0

        onLinkActivated: (link) => {
            if (link.startsWith("did:"))
                console.debug("TODO MENTION", link)
            else
                Qt.openUrlExternally(link)
        }
    }

    Component {
        id: dateTimeComp
        Text {
            width: parent.width
            topPadding: 10
            Layout.fillWidth: true
            elide: Text.ElideRight
            color: Material.color(Material.Grey)
            text: postDateTime.toLocaleString(Qt.locale(), Locale.LongFormat)
            font.pointSize: root.scaledFont(7/8)
        }
    }

    Component.onCompleted: {
        if (!postBody.visible)
            return

        if (postImages.length > 0) {
            let qmlFile = `ImagePreview${(postImages.length)}.qml`
            let component = Qt.createComponent(qmlFile)
            component.createObject(postBody, {images: postImages})
        }

        if (postExternal) {
            let component = Qt.createComponent("ExternalView.qml")
            component.createObject(postBody, {postExternal: postBody.postExternal})
        }

        if (postRecord) {
            let component = Qt.createComponent("RecordView.qml")
            component.createObject(postBody, {record: postRecord})
        }

        if (postRecordWithMedia) {
            let component = Qt.createComponent("RecordWithMediaView.qml")
            component.createObject(postBody, {record: postRecordWithMedia})
        }

        if (detailedView)
            dateTimeComp.createObject(postBody)
    }
}
