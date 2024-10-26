pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import skywalker

Column {
    required property basicprofile postAuthor
    required property string postText
    required property list<imageview> postImages
    required property date postDateTime
    required property list<language> postLanguageLabels
    required property list<contentlabel> postContentLabels
    required property int postContentVisibility // QEnums::PostContentVisibility
    required property string postContentWarning
    required property int postMuted // QEnums::MutedPostReason
    property string postPlainText
    property var postVideo // videoView
    property var postExternal // externalview (var allows NULL)
    property var postRecord // recordview
    property var postRecordWithMedia // record_with_media_view
    property bool detailedView: false
    property int maxTextLines: 1000
    property string bodyBackgroundColor: guiSettings.backgroundColor
    property bool showWarnedPost: false
    property bool mutePost: postMuted !== QEnums.MUTED_POST_NONE
    property bool attachmentsInitialized: false
    property string postHighlightColor: "transparent"
    property bool isDraft: false

    id: postBody

    SkyCleanedText {
        id: bodyText
        width: parent.width
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        initialShowMaxLineCount: Math.min(postBody.maxTextLines, 25)
        maximumLineCount: postBody.maxTextLines
        ellipsisBackgroundColor: postBody.bodyBackgroundColor
        elide: Text.ElideRight
        textFormat: Text.RichText
        color: guiSettings.textColor
        font.pointSize: postBody.getPostFontSize()
        plainText: postBody.postText
        bottomPadding: postBody.postImages.length > 0 || postBody.postVideo || postBody.postExternal || postBody.postRecord || postBody.postRecordWithMedia ? 5 : 0
        visible: postBody.postVisible() && postBody.postText

        onLinkActivated: (link) => SkyRoot.root.openLink(link)

        Accessible.ignored: true

        Rectangle {
            anchors.fill: parent
            z: parent.z - 1
            radius: 5
            color: postBody.postHighlightColor
            opacity: guiSettings.focusHighlightOpacity
        }
    }

    Loader {
        width: parent.width
        active: !postBody.postVisible()
        visible: status == Loader.Ready
        sourceComponent: Row {
            width: parent.width
            spacing: 10

            SkySvg {
                id: imgIcon
                width: 30
                height: width
                color: Material.color(Material.Grey)
                svg: getIcon()

                function getIcon() {
                    if (!postBody.mutePost)
                        return SvgOutline.hideVisibility

                    switch (postMuted) {
                    case QEnums.MUTED_POST_AUTHOR:
                        return SvgOutline.mute
                    case QEnums.MUTED_POST_WORDS:
                        return SvgOutline.mutedWords
                    }

                    return SvgOutline.hideVisibility
                }
            }

            // The content warning is shown when the post is not muted
            Text {
                id: warnText
                width: parent.width
                Layout.fillWidth: true
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                textFormat: Text.RichText
                color: Material.color(Material.Grey)
                text: postBody.postContentWarning + `<br><a href=\"show\" style=\"color: ${guiSettings.linkColor};\">` + qsTr("Show post") + "</a>"
                visible: postBody.postContentVisibility === QEnums.CONTENT_VISIBILITY_WARN_POST && !postBody.showWarnedPost && !postBody.mutePost
                onLinkActivated: {
                    postBody.showWarnedPost = true

                    if (postBody.postVisible())
                        postBody.showPostAttachements()
                }
            }

            // If the post is muted, then this takes precendence over the content warning
            Text {
                id: mutedText
                width: parent.width
                Layout.fillWidth: true
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                textFormat: Text.RichText
                color: Material.color(Material.Grey)
                text: postBody.getMuteText() + `<br><a href=\"show\" style=\"color: ${guiSettings.linkColor};\">` + qsTr("Show post") + "</a>"
                visible: postBody.mutePost && postBody.postContentVisibility !== QEnums.CONTENT_VISIBILITY_HIDE_POST
                onLinkActivated: {
                    postBody.mutePost = false

                    // The post may still not be visible due to content filtering
                    if (postBody.postVisible())
                        postBody.showPostAttachements()
                }
            }

            // If a post is hidden then this text will show no matter whether the post is muted
            Text {
                id: hideText
                width: parent.width
                Layout.fillWidth: true
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                textFormat: Text.RichText
                color: Material.color(Material.Grey)
                text: postBody.postContentWarning
                visible: postBody.postContentVisibility === QEnums.CONTENT_VISIBILITY_HIDE_POST
            }
        }
    }

    Loader {
        id: languageLabelsLoader
        anchors.right: parent.right
        visible: status == Loader.Ready
    }

    Loader {
        id: mediaLoader
        width: parent.width
        visible: status == Loader.Ready
    }

    Loader {
        id: contentLabelsLoader
        anchors.right: parent.right
        visible: status == Loader.Ready
    }

    Loader {
        id: recordLoader
        width: parent.width
        visible: status == Loader.Ready
    }

    Loader {
        id: dateTimeLoader
        width: parent.width
        active: postBody.detailedView
        visible: status == Loader.Ready
        sourceComponent: Text {
            width: parent.width
            topPadding: 10
            Layout.fillWidth: true
            elide: Text.ElideRight
            color: Material.color(Material.Grey)
            text: postBody.postDateTime.toLocaleString(Qt.locale(), Locale.ShortFormat)
            font.pointSize: guiSettings.scaledFont(7/8)
        }
    }

    GuiSettings {
        id: guiSettings
    }

    function movedOffScreen() {
        if (postVideo && mediaLoader.item)
            mediaLoader.item.pause()

        if (postRecordWithMedia && recordLoader.item)
            recordLoader.item.movedOffScreen()
    }

    function postVisible() {
        if (mutePost)
            return false

        return ![QEnums.CONTENT_VISIBILITY_HIDE_POST,
                 QEnums.CONTENT_VISIBILITY_WARN_POST].includes(postContentVisibility) ||
               showWarnedPost
    }

    function getMuteText() {
        switch (postMuted) {
        case QEnums.MUTED_POST_AUTHOR:
            return qsTr("You muted this account")
        case QEnums.MUTED_POST_WORDS:
            return qsTr("Post has muted words")
        }

        return qsTr("Muted post")
    }

    function getPostFontSize() {
        if (!SkyRoot.root.getSkywalker().getUserSettings().giantEmojis)
            return guiSettings.scaledFont(1)

        return onlyEmojisPost() ?
                    guiSettings.scaledFont(unicodeFonts.graphemeLength(postPlainText) === 1 ? 9 : 3) :
                    guiSettings.scaledFont(1)
    }

    function onlyEmojisPost() {
        if (!postPlainText)
            return false

        if (unicodeFonts.graphemeLength(postPlainText) > 5)
            return false

        return unicodeFonts.onlyEmojis(postPlainText)
    }

    function mustShowLangaugess() {
        return SkyRoot.root.getSkywalker().getUserSettings().getShowLanguageTags()
    }

    function showPostAttachements() {
        if (postLanguageLabels.length > 0 && mustShowLangaugess()) {
            languageLabelsLoader.setSource("LanguageLabels.qml", {
                                               languageLabels: postLanguageLabels,
                                               parentWidth: parent.width })
        }

        if (postImages.length > 0) {
            let qmlFile = `ImagePreview${(postImages.length)}.qml`
            mediaLoader.setSource(qmlFile, {
                                      images: postImages,
                                      contentVisibility: postContentVisibility,
                                      contentWarning: postContentWarning })
        }
        else if (postVideo) {
            if (isDraft) {
                mediaLoader.setSource("VideoThumbnail.qml", {
                                        width: Math.min(180 * 1.777, postBody.width),
                                        height: 180,
                                        videoSource: postBody.postVideo.playlistUrl });
            }
            else {
                mediaLoader.setSource("VideoView.qml", {
                                          videoView: postBody.postVideo,
                                          contentVisibility: postContentVisibility,
                                          contentWarning: postContentWarning,
                                          backgroundColor: bodyBackgroundColor })
            }
        }
        else if (postExternal) {
            mediaLoader.setSource("ExternalView.qml", {
                                        postExternal: postBody.postExternal,
                                        contentVisibility: postContentVisibility,
                                        contentWarning: postContentWarning })
        }

        if (postContentLabels.length > 0) {
            contentLabelsLoader.setSource("ContentLabels.qml", {
                                        contentLabels: postContentLabels,
                                        contentAuthorDid: postAuthor.did,
                                        parentWidth: parent.width})
        }

        if (postRecord)
            recordLoader.setSource("RecordView.qml", {record: postRecord})
        else if (postRecordWithMedia) {
            recordLoader.setSource("RecordWithMediaView.qml", {
                                                record: postRecordWithMedia,
                                                contentVisibility: postContentVisibility,
                                                contentWarning: postContentWarning,
                                                backgroundColor: bodyBackgroundColor })
        }
    }

    onPostRecordChanged: {
        if (postRecord)
            recordLoader.setSource("RecordView.qml", {record: postRecord})
    }

    onPostRecordWithMediaChanged: {
        if (postRecordWithMedia) {
            recordLoader.setSource("RecordWithMediaView.qml", {
                                                record: postRecordWithMedia,
                                                contentVisibility: postContentVisibility,
                                                contentWarning: postContentWarning,
                                                backgroundColor: bodyBackgroundColor})
        }
    }

    onVisibleChanged: {
        if (postBody.visible && !postBody.attachmentsInitialized)
            initAttachments()
    }

    function initAttachments() {
        if (postVisible())
            showPostAttachements()

        postBody.attachmentsInitialized = true
    }

    Component.onCompleted: {
        if (!postBody.visible)
            return

        initAttachments()
    }
}
