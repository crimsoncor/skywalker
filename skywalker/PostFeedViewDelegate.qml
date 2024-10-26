pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import skywalker

Rectangle {
    readonly property int margin: 10
    readonly property int threadStyle: SkyRoot.skywalker().getUserSettings().threadStyle
    readonly property string threadColor: SkyRoot.skywalker().getUserSettings().threadColor

    required property basicprofile author
    required property string postUri
    required property string postCid
    required property string postText
    required property string postPlainText
    required property list<language> postLanguages
    required property date postIndexedDateTime
    required property basicprofile postRepostedByAuthor
    required property list<imageview> postImages
    required property var postVideo // videoView
    required property var postExternal // externalview (var allows NULL)
    required property var postRecord // recordview
    required property var postRecordWithMedia // record_with_media_view
    required property int postType // QEnums::PostType
    required property int postThreadType // QEnums::ThreadPostType flags
    required property bool postIsPlaceHolder
    required property int postGapId;
    required property bool postHiddenPosts;
    required property bool postNotFound;
    required property bool postBlocked;
    required property bool postNotSupported;
    required property string postUnsupportedType;
    required property bool postIsReply
    required property bool postParentInThread
    required property basicprofile postReplyToAuthor
    required property string postReplyRootAuthorDid
    required property string postReplyRootUri
    required property string postReplyRootCid
    required property int postReplyCount
    required property int postRepostCount
    required property int postLikeCount
    required property int postQuoteCount
    required property string postRepostUri
    required property string postLikeUri
    required property bool postLikeTransient
    required property bool postThreadMuted
    required property bool postReplyDisabled
    required property bool postEmbeddingDisabled
    required property bool postViewerStatePinned
    required property string postThreadgateUri
    required property int postReplyRestriction // QEnums::ReplyRestriction flags
    required property list<listviewbasic> postReplyRestrictionLists
    required property list<string> postHiddenReplies
    required property bool postIsHiddenReply
    required property bool postBookmarked
    required property bool postBookmarkNotFound
    required property list<contentlabel> postLabels
    required property int postContentVisibility // QEnums::PostContentVisibility
    required property string postContentWarning
    required property int postMutedReason // QEnums::MutedPostReason
    required property string postHighlightColor
    required property bool postIsPinned
    required property bool postLocallyDeleted
    required property bool endOfFeed

    property int prevY: 0
    property bool isAnchorItem: false
    property bool onScreen: false

    signal calibratedPosition(int dy)
    signal showHiddenReplies

    id: postEntry
    height: grid.height
    color: postThreadType & QEnums.THREAD_ENTRY ? guiSettings.postHighLightColor : guiSettings.backgroundColor
    border.width: postThreadType & QEnums.THREAD_ENTRY ? 1 : 0
    border.color: guiSettings.borderColor

    Accessible.role: Accessible.Button
    Accessible.name: getSpeech()
    Accessible.onPressAction: performAccessiblePressAction()

    onIsAnchorItemChanged: prevY = y

    // New items added at the top of the list sometimes push all items below downwards,
    // causing the list to scroll. To prevent that, we detect the downward movement and
    // scroll back (ideally Qt should not do push down)
    onYChanged: {
        checkOnScreen()

        if (!isAnchorItem)
            return

        const dy = y - prevY

        if (dy != 0) {
            prevY = y
            calibratedPosition(dy)
        }
    }

    onOnScreenChanged: {
        if (!onScreen)
            cover()
    }

    function cover() {
        postBody.movedOffScreen()
    }

    GridLayout {
        id: grid
        columns: 2
        width: parent.width
        rowSpacing: 0

        // Instead of using row spacing, these empty rectangles are used for white space.
        // This way we can color the background for threads.
        Rectangle {
            id: topLeftSpace
            Layout.leftMargin: 8 + (avatarImg.width - width) / 2
            Layout.preferredWidth: postEntry.threadStyle === QEnums.THREAD_STYLE_BAR ? avatarImg.width : guiSettings.threadLineWidth
            Layout.preferredHeight: postEntry.margin * (!postEntry.postParentInThread && (postEntry.postType === QEnums.POST_REPLY || postEntry.postType === QEnums.POST_LAST_REPLY) ? 2 : 1)

            color: {
                switch (postEntry.postType) {
                case QEnums.POST_ROOT:
                    return postEntry.postIsReply ? guiSettings.threadStartColor(postEntry.threadColor) : "transparent"
                case QEnums.POST_REPLY:
                case QEnums.POST_LAST_REPLY:
                    return !postEntry.postParentInThread ? "transparent" : guiSettings.threadMidColor(postEntry.threadColor)
                case QEnums.POST_THREAD: {
                    if (postEntry.postThreadType & QEnums.THREAD_FIRST_DIRECT_CHILD) {
                        return guiSettings.threadStartColor(postEntry.threadColor)
                    } else if ((postEntry.postThreadType & QEnums.THREAD_DIRECT_CHILD) ||
                               (postEntry.postThreadType & QEnums.THREAD_ENTRY)){
                        return (postEntry.postThreadType & QEnums.THREAD_TOP) ? "transparent" : guiSettings.threadEntryColor(postEntry.threadColor)
                    } else if (postEntry.postThreadType & QEnums.THREAD_TOP) {
                        return "transparent"
                    } else if (postEntry.postThreadType & QEnums.THREAD_PARENT) {
                        return guiSettings.threadStartColor(postEntry.threadColor)
                    }

                    return guiSettings.threadMidColor(postEntry.threadColor)
                }
                default:
                    return "transparent"
                }
            }

            opacity: avatar.opacity

            Rectangle {
                y: postEntry.margin - (height / 2)
                width: parent.width
                height: 6
                color: guiSettings.threadMidColor(postEntry.threadColor)
                visible: !postEntry.postParentInThread && (postEntry.postType === QEnums.POST_REPLY || postEntry.postType === QEnums.POST_LAST_REPLY)
            }
        }
        Rectangle {
            Layout.preferredWidth: parent.width - guiSettings.threadColumnWidth - postEntry.margin * 2
            Layout.preferredHeight: topLeftSpace.height
            color: "transparent"
        }

        // Pinned post
        Loader {
            Layout.preferredWidth: guiSettings.threadColumnWidth
            Layout.fillHeight: true
            active: postEntry.postIsPinned && !postEntry.postLocallyDeleted
            visible: status == Loader.Ready
            sourceComponent: Rectangle {
                width: parent.width
                height: parent.height
                color: guiSettings.backgroundColor

                SkySvg {
                    anchors.right: parent.right
                    width: 18
                    height: width
                    color: Material.color(Material.Grey)
                    svg: SvgFilled.pin
                }
            }
        }
        Loader {
            Layout.fillWidth: true
            active: postEntry.postIsPinned && !postEntry.postLocallyDeleted
            visible: status == Loader.Ready
            sourceComponent: AccessibleText {
                width: parent.width
                elide: Text.ElideRight
                text: qsTr("Pinned post")
                color: Material.color(Material.Grey)
                font.bold: true
                font.pointSize: guiSettings.scaledFont(7/8)
            }
        }

        // Repost information
        Loader {
            Layout.preferredWidth: guiSettings.threadColumnWidth
            Layout.fillHeight: true
            active: !postEntry.postRepostedByAuthor.isNull() && !postEntry.postGapId && !postEntry.postLocallyDeleted
            visible: status == Loader.Ready
            sourceComponent: Rectangle {
                width: parent.width
                height: parent.height
                color: guiSettings.backgroundColor

                SkySvg {
                    anchors.right: parent.right
                    width: 18
                    height: width
                    color: Material.color(Material.Grey)
                    svg: SvgOutline.repost
                }
            }
        }
        Loader {
            Layout.fillWidth: true
            active: !postEntry.postRepostedByAuthor.isNull() && !postEntry.postGapId && !postEntry.postLocallyDeleted
            visible: status == Loader.Ready
            sourceComponent: SkyCleanedText {
                id: repostedByText
                width: parent.width
                elide: Text.ElideRight
                plainText: qsTr(`Reposted by ${postEntry.postRepostedByAuthor.name}`)
                color: Material.color(Material.Grey)
                font.bold: true
                font.pointSize: guiSettings.scaledFont(7/8)
                Accessible.ignored: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: SkyRoot.skywalker().getDetailedProfile(postEntry.postRepostedByAuthor.did)
                }
            }
        }

        // Author and content
        Rectangle {
            id: avatar
            Layout.preferredWidth: guiSettings.threadColumnWidth
            Layout.fillHeight: true
            color: "transparent"
            opacity: 0.9

            Rectangle {
                x: avatarImg.x + (avatarImg.width - width) / 2
                y: ((postEntry.postType === QEnums.POST_ROOT && !postEntry.postIsReply) || (postEntry.postThreadType & QEnums.THREAD_TOP)) ? avatarImg.y + avatarImg.height / 2 : 0
                width: postEntry.threadStyle === QEnums.THREAD_STYLE_LINE ? guiSettings.threadLineWidth : avatarImg.width
                height: ((postEntry.postType === QEnums.POST_LAST_REPLY) || (postEntry.postThreadType & QEnums.THREAD_LEAF)) && postEntry.postReplyCount === 0 ? avatarImg.y + avatarImg.height / 2 - y : parent.height - y

                // Gradient is used display thread context.
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: {
                            switch (postEntry.postType) {
                            case QEnums.POST_ROOT:
                                return guiSettings.threadStartColor(postEntry.threadColor)
                            case QEnums.POST_REPLY:
                            case QEnums.POST_LAST_REPLY:
                                return guiSettings.threadMidColor(postEntry.threadColor)
                            case QEnums.POST_THREAD: {
                                if (postEntry.postThreadType & QEnums.THREAD_ENTRY) {
                                    return guiSettings.threadEntryColor(postEntry.threadColor)
                                } else if ((postEntry.postThreadType & QEnums.THREAD_PARENT) ||
                                        (postEntry.postThreadType & QEnums.THREAD_DIRECT_CHILD)) {
                                    return guiSettings.threadStartColor(postEntry.threadColor)
                                }

                                return guiSettings.threadMidColor(postEntry.threadColor)
                            }
                            default:
                                return guiSettings.backgroundColor
                            }
                        }
                    }
                    GradientStop {
                        position: 1.0
                        color: {
                            switch (postEntry.postType) {
                            case QEnums.POST_STANDALONE:
                                return guiSettings.backgroundColor
                            case QEnums.POST_LAST_REPLY:
                                return guiSettings.threadEndColor(postEntry.threadColor)
                            case QEnums.POST_THREAD: {
                                if (postEntry.postThreadType & QEnums.THREAD_ENTRY) {
                                    return guiSettings.threadEntryColor(postEntry.threadColor)
                                } else if (postEntry.postThreadType & QEnums.THREAD_PARENT) {
                                    return guiSettings.threadStartColor(postEntry.threadColor)
                                } else if (postEntry.postThreadType & QEnums.THREAD_LEAF) {
                                    return guiSettings.threadEndColor(postEntry.threadColor)
                                }

                                return guiSettings.threadMidColor(postEntry.threadColor)
                            }
                            default:
                                return guiSettings.threadMidColor(postEntry.threadColor)
                            }
                        }
                    }
                }
            }

            Avatar {
                id: avatarImg
                x: avatar.x + 8
                y: postHeader.y + 5 // For some reason "avatar.y + 5" does not work when it is a repost
                width: parent.width - 13
                author: postEntry.author
                visible: !postEntry.postIsPlaceHolder && !postEntry.postLocallyDeleted

                onClicked: SkyRoot.skywalker().getDetailedProfile(author.did)

                Accessible.role: Accessible.Button
                Accessible.name: qsTr(`show profile of ${author.name}`)
                Accessible.onPressAction: clicked()
            }
        }
        Column {
            id: postColumn
            // Change from width to Layout.preferredWidth seems to solve the issue
            // where posts sometimes are too wide (like landscape mode) but makes
            // things very slow :-(
            Layout.preferredWidth: parent.width - guiSettings.threadColumnWidth - postEntry.margin * 2
            visible: !postEntry.postIsPlaceHolder && !postEntry.postLocallyDeleted

            PostHeader {
                id: postHeader
                width: parent.width
                author: postEntry.author
                postThreadType: postEntry.postThreadType
                postIndexedSecondsAgo: (new Date() - postEntry.postIndexedDateTime) / 1000
            }

            // Reply to
            Loader {
                width: parent.width
                active: postEntry.postIsReply && (!postEntry.postParentInThread || postEntry.postType === QEnums.POST_ROOT) && postEntry.postType !== QEnums.POST_THREAD
                visible: status == Loader.Ready
                sourceComponent: ReplyToRow {
                    width: parent.width
                    text: qsTr(`Reply to ${postEntry.postReplyToAuthor.name}`)
                }
            }

            // Reply hidden by user
            Loader {
                width: parent.width
                active: postEntry.postIsHiddenReply && postEntry.isUserDid(postEntry.postReplyRootAuthorDid)
                visible: status == Loader.Ready
                sourceComponent: ReplyToRow {
                    width: parent.width
                    text: qsTr("Reply hidden by you")
                    svg: SvgOutline.hideVisibility
                }
            }

            PostBody {
                id: postBody
                width: parent.width
                postAuthor: postEntry.author
                postText: postEntry.postText
                postPlainText: postEntry.postPlainText
                postImages: postEntry.postImages
                postLanguageLabels: postEntry.postLanguages
                postContentLabels: postEntry.postLabels
                postContentVisibility: postEntry.postContentVisibility
                postContentWarning: postEntry.postContentWarning
                postMuted: postEntry.postMutedReason
                postVideo: postEntry.postVideo
                postExternal: postEntry.postExternal
                postRecord: postEntry.postRecord
                postRecordWithMedia: postEntry.postRecordWithMedia
                postDateTime: postEntry.postIndexedDateTime
                detailedView: postEntry.postThreadType & QEnums.THREAD_ENTRY
                bodyBackgroundColor: postEntry.color.toString()
                postHighlightColor: postEntry.postHighlightColor
            }

            // Reposts and likes in detailed view of post entry in thread view
            Loader {
                width: parent.width
                active: postEntry.postThreadType & QEnums.THREAD_ENTRY
                visible: status == Loader.Ready
                sourceComponent: Flow {
                    width: parent.width
                    topPadding: 10
                    bottomPadding: 5
                    spacing: 10

                    StatAuthors {
                        atUri: postEntry.postUri
                        count: postEntry.postRepostCount
                        nameSingular: qsTr("repost")
                        namePlural: qsTr("reposts")
                        authorListType: QEnums.AUTHOR_LIST_REPOSTS
                        authorListHeader: qsTr("Reposted by")
                    }
                    StatQuotes {
                        atUri: postEntry.postUri
                        count: postEntry.postQuoteCount
                    }
                    StatAuthors {
                        atUri: postEntry.postUri
                        count: postEntry.postLikeCount
                        nameSingular: qsTr("like")
                        namePlural: qsTr("likes")
                        authorListType: QEnums.AUTHOR_LIST_LIKES
                        authorListHeader: qsTr("Liked by")
                    }
                }
            }

            // Stats
            PostStats {
                width: parent.width
                topPadding: 10
                replyCount: postEntry.postReplyCount
                repostCount: postEntry.postRepostCount + postEntry.postQuoteCount
                likeCount: postEntry.postLikeCount
                repostUri: postEntry.postRepostUri
                likeUri: postEntry.postLikeUri
                likeTransient: postEntry.postLikeTransient
                threadMuted: postEntry.postThreadMuted
                replyDisabled: postEntry.postReplyDisabled
                embeddingDisabled: postEntry.postEmbeddingDisabled
                viewerStatePinned: postEntry.postViewerStatePinned
                replyRestriction: postEntry.postReplyRestriction
                isHiddenReply: postEntry.postIsHiddenReply
                isReply: postEntry.postIsReply
                replyRootAuthorDid: postEntry.postReplyRootAuthorDid
                replyRootUri: postEntry.postReplyRootUri
                authorIsUser: postEntry.isUser(postEntry.author)
                isBookmarked: postEntry.postBookmarked
                bookmarkNotFound: postEntry.postBookmarkNotFound
                record: postEntry.postRecord
                recordWithMedia: postEntry.postRecordWithMedia

                onReply: {
                    const lang = postEntry.postLanguages.length > 0 ? postEntry.postLanguages[0].shortCode : ""
                    SkyRoot.root.composeReply(postEntry.postUri, postEntry.postCid, postEntry.postText, postEntry.postIndexedDateTime,
                                      postEntry.author, postEntry.postReplyRootUri, postEntry.postReplyRootCid, lang)
                }

                onRepost: {
                    SkyRoot.root.repost(postEntry.postRepostUri, postEntry.postUri, postEntry.postCid, postEntry.postText,
                                postEntry.postIndexedDateTime, postEntry.author, postEntry.postEmbeddingDisabled)
                }

                onLike: SkyRoot.root.like(postEntry.postLikeUri, postEntry.postUri, postEntry.postCid)

                onBookmark: {
                    if (postEntry.isBookmarked) {
                        SkyRoot.skywalker().bookmarks.removeBookmark(postEntry.postUri)
                    }
                    else {
                        const bookmarked = SkyRoot.skywalker().bookmarks.addBookmark(postEntry.postUri)

                        if (!bookmarked)
                            SkyRoot.skywalker().showStatusMessage(qsTr("Your bookmarks are full!"), QEnums.STATUS_LEVEL_ERROR)
                    }
                }

                onShare: SkyRoot.skywalker().sharePost(postEntry.postUri)
                onMuteThread: SkyRoot.root.muteThread(postEntry.postIsReply ? postEntry.postReplyRootUri : postEntry.postUri, postEntry.postThreadMuted)
                onThreadgate: SkyRoot.root.gateRestrictions(postEntry.postThreadgateUri, postEntry.postIsReply ? postEntry.postReplyRootUri : postEntry.postUri, postEntry.postIsReply ?postEntry. postReplyRootCid : postEntry.postCid, postEntry.postUri, postEntry.postReplyRestriction, postEntry.postReplyRestrictionLists, postEntry.postHiddenReplies)
                onHideReply: SkyRoot.root.hidePostReply(postEntry.postThreadgateUri, postEntry.postReplyRootUri, postEntry.postReplyRootCid, postEntry.postUri, postEntry.postReplyRestriction, postEntry.postReplyRestrictionLists, postEntry.postHiddenReplies)
                onDeletePost: postEntry.confirmDelete()
                onCopyPostText: SkyRoot.skywalker().copyPostTextToClipboard(postEntry.postPlainText)
                onReportPost: SkyRoot.root.reportPost(postEntry.postUri, postEntry.postCid, postEntry.postText, postEntry.postIndexedDateTime, postEntry.author)
                onTranslatePost: SkyRoot.root.translateText(postEntry.postPlainText)
                onDetachQuote: (uri, detach) => SkyRoot.root.detachQuote(uri, postEntry.postUri, postEntry.postCid, detach)
                onPin: SkyRoot.root.pinPost(postEntry.postUri, postEntry.postCid)
                onUnpin: SkyRoot.root.unpinPost(postEntry.postCid)
            }
        }

        // Gap place holder
        Loader {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            active: postEntry.postGapId > 0
            visible: status == Loader.Ready
            sourceComponent: Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: guiSettings.linkColor
                text: qsTr("Show more posts")

                MouseArea {
                    anchors.fill: parent
                    onClicked: postEntry.getGapPosts()
                }
            }
        }

        // Hidden posts
        Loader {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            active: postEntry.postHiddenPosts
            visible: status == Loader.Ready
            sourceComponent: Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: guiSettings.linkColor
                text: qsTr("Show hidden replies")

                MouseArea {
                    anchors.fill: parent
                    onClicked: postEntry.showHiddenReplies()
                }
            }
        }

        // Place holder for NOT FOUND, BLOCKED, NOT SUPPORTED, DELETED posts
        Loader {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            active: postEntry.postNotFound || postEntry.postBlocked || postEntry.postNotSupported || postEntry.postLocallyDeleted
            visible: status == Loader.Ready
            sourceComponent: Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: guiSettings.textColor
                text: {
                    if (postEntry.postNotFound)
                        return qsTr("🗑 Not found")
                    else if (postEntry.postBlocked)
                        return qsTr("🚫 Blocked")
                    else if (postEntry.postNotSupported)
                        return qsTr("⚠️ Not supported")
                    else if (postEntry.postLocallyDeleted)
                        return qsTr("🗑 Deleted")
                    else
                        return "⚠️ Error"
                }
            }
        }

        Loader {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            active: postEntry.postNotSupported
            visible: status == Loader.Ready
            sourceComponent: Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Material.color(Material.Grey)
                font.pointSize: guiSettings.scaledFont(7/8)
                text: postEntry.postUnsupportedType
            }
        }

        // Instead of using row spacing, these empty rectangles are used for white space.
        // This way we can color the background for threads.
        Rectangle {
            Layout.preferredWidth: guiSettings.threadColumnWidth
            Layout.preferredHeight: postEntry.margin
            color: "transparent"

            Rectangle {
                x: 8 + (avatarImg.width - width) / 2
                width: postEntry.threadStyle === QEnums.THREAD_STYLE_BAR ? avatarImg.width : guiSettings.threadLineWidth
                height: parent.height
                opacity: avatar.opacity
                visible: !((postEntry.postType === QEnums.POST_LAST_REPLY) || (postEntry.postThreadType & QEnums.THREAD_LEAF))

                color: {
                    switch (postEntry.postType) {
                    case QEnums.POST_ROOT:
                    case QEnums.POST_REPLY:
                        return guiSettings.threadMidColor(postEntry.threadColor)
                    case QEnums.POST_THREAD: {
                        if (postEntry.postThreadType & QEnums.THREAD_ENTRY)  {
                            return guiSettings.threadEntryColor(postEntry.threadColor)
                        }
                        if (postEntry.postThreadType & QEnums.THREAD_LEAF) {
                            return guiSettings.backgroundColor
                        } else if (postEntry.postThreadType & QEnums.THREAD_PARENT)  {
                            return guiSettings.threadStartColor(postEntry.threadColor)
                        }

                        return guiSettings.threadMidColor(postEntry.threadColor)
                    }
                    default:
                        return guiSettings.backgroundColor
                    }
                }
            }
        }
        Rectangle {
            Layout.preferredWidth: parent.width - guiSettings.threadColumnWidth - postEntry.margin * 2
            Layout.preferredHeight: postEntry.margin
            color: "transparent"
        }

        // Post/Thread separator
        Rectangle {
            Layout.preferredWidth: parent.width
            Layout.columnSpan: 2
            Layout.preferredHeight: 1
            color: guiSettings.separatorColor
            visible: [QEnums.POST_STANDALONE, QEnums.POST_LAST_REPLY].includes(postEntry.postType) ||
                (postEntry.postThreadType & QEnums.THREAD_LEAF)
        }

        // End of feed indication
        Loader {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            active: postEntry.endOfFeed
            visible: status == Loader.Ready
            sourceComponent: Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 10
                elide: Text.ElideRight
                color: guiSettings.textColor
                text: qsTr("End of feed")
                font.italic: true
            }
        }
    }

    MouseArea {
        z: -2 // Let other mouse areas, e.g. images, get on top, -2 to allow records on top
        anchors.fill: parent
        enabled: !(postEntry.postThreadType & QEnums.THREAD_ENTRY) && !postEntry.postBookmarkNotFound
        onClicked: postEntry.openPostThread()
    }

    UnicodeFonts {
        id: unicodeFonts
    }

    AccessibilityUtils {
        id: accessibilityUtils
    }

    GuiSettings {
        id: guiSettings
    }

    function confirmDelete() {
        guiSettings.askYesNoQuestion(
                    postEntry,
                    qsTr("Do you really want to delete your post?"),
                    () => root.deletePost(postUri, postCid))
    }

    function openPostThread() {
        if (!(postThreadType & QEnums.THREAD_ENTRY) && !postBookmarkNotFound)
        {
            if (postUri)
                SkyRoot.skywalker().getPostThread(postUri)
        }
    }

    function getGapPosts() {
        if (!SkyRoot.skywalker().getTimelineInProgress)
            SkyRoot.skywalker().getTimelineForGap(postGapId, 3, true)
    }

    function performAccessiblePressAction() {
        if (postLocallyDeleted)
            return

        if (postIsPlaceHolder) {
            if (postGapId > 0)
                getGapPosts()

            return
        }

        if (postBody.postVisible())
            openPostThread()
    }

    function getSpeech() {
        if (postLocallyDeleted)
            return qsTr("deleted post")

        if (postIsPlaceHolder) {
            if (postGapId > 0)
                return qsTr("show more more posts")

            return accessibilityUtils.getPostNotAvailableSpeech(
                    postNotFound, postBlocked, postNotSupported)
        }

        if (!postBody.postVisible())
            return getHiddenPostSpeech()

        return accessibilityUtils.getPostSpeech(postIndexedDateTime, author, postPlainText,
                postImages, postExternal, postRecord, postRecordWithMedia,
                postRepostedByAuthor, postIsReply, postReplyToAuthor)
    }

    function getHiddenPostSpeech() {
        if (postContentVisibility === QEnums.CONTENT_VISIBILITY_HIDE_POST)
            return postContentWarning

        if (postBody.mutePost)
            return postBody.getMuteText()

        return postContentWarning
    }

    function isUserDid(did) {
        return SkyRoot.skywalker().getUserDid() === did
    }

    function isUser(author) {
        return isUserDid(author.did)
    }

    function checkOnScreen() {
        const headerHeight = ListView.view.headerItem ? ListView.view.headerItem.height : 0
        const topY = ListView.view.contentY + headerHeight
        onScreen = (y + height > topY) && (y < ListView.view.contentY + ListView.view.height)
    }

    Component.onCompleted: {
        ListView.view.enableOnScreenCheck = true
        checkOnScreen()
    }
}
