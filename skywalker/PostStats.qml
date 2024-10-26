pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import skywalker

Item {
    required property int replyCount
    required property int repostCount
    required property int likeCount
    required property string repostUri
    required property string likeUri
    required property bool likeTransient
    required property bool threadMuted
    required property bool replyDisabled
    required property bool embeddingDisabled
    required property bool viewerStatePinned
    required property int replyRestriction // QEnums::ReplyRestriction flags
    required property bool isHiddenReply
    required property bool isReply
    required property string replyRootAuthorDid
    required property string replyRootUri
    required property bool authorIsUser
    required property bool isBookmarked
    required property bool bookmarkNotFound
    property var record: null // recordview
    property var recordWithMedia: null // record_with_media_view
    property int topPadding: 0

    signal reply()
    signal repost()
    signal like()
    signal muteThread()
    signal bookmark()
    signal share()
    signal threadgate()
    signal hideReply()
    signal deletePost()
    signal copyPostText()
    signal reportPost()
    signal translatePost()
    signal detachQuote(string uri, bool detach)
    signal pin()
    signal unpin()

    id: postStats
    height: replyIcon.height + topPadding

    StatIcon {
        id: replyIcon
        y: postStats.topPadding
        width: parent.width / 4
        iconColor: enabled ? guiSettings.statsColor : guiSettings.disabledColor
        svg: SvgOutline.reply
        statistic: postStats.replyCount
        visible: !postStats.bookmarkNotFound
        enabled: !postStats.replyDisabled
        onClicked: postStats.reply()

        Accessible.name: (postStats.replyDisabled ? qsTr("reply not allowed") : qsTr("reply")) + postStats.statSpeech(postStats.replyCount, "reply", "replies")
    }
    StatIcon {
        id: repostIcon
        y: postStats.topPadding
        anchors.left: replyIcon.right
        width: parent.width / 4
        iconColor: postStats.repostUri ? guiSettings.likeColor : guiSettings.statsColor
        svg: SvgOutline.repost
        statistic: postStats.repostCount
        visible: !postStats.bookmarkNotFound
        onClicked: postStats.repost()

        Accessible.name: qsTr("repost") + postStats.statSpeech(postStats.repostCount, "repost", "reposts")
    }
    StatIcon {
        id: likeIcon
        y: postStats.topPadding
        anchors.left: repostIcon.right
        width: parent.width / 4
        iconColor: postStats.likeUri ? guiSettings.likeColor : guiSettings.statsColor
        svg: postStats.likeUri ? SvgFilled.like : SvgOutline.like
        statistic: postStats.likeCount
        visible: !postStats.bookmarkNotFound
        onClicked: postStats.like()

        Accessible.name: qsTr("like") + postStats.statSpeech(postStats.likeCount, "like", "likes")

        BlinkingOpacity {
            target: likeIcon
            running: postStats.likeTransient
        }
    }
    StatIcon {
        id: bookmarkIcon
        y: postStats.topPadding
        anchors.left: likeIcon.right
        width: parent.width / 8
        iconColor: postStats.isBookmarked ? guiSettings.buttonColor : guiSettings.statsColor
        svg: postStats.isBookmarked ? SvgFilled.bookmark : SvgOutline.bookmark
        onClicked: postStats.bookmark()

        Accessible.name: postStats.isBookmarked ? qsTr("remove bookmark") : qsTr("bookmark")
    }
    StatIcon {
        id: moreIcon
        y: postStats.topPadding
        anchors.left: bookmarkIcon.right
        width: parent.width / 8
        svg: SvgOutline.moreVert
        visible: !postStats.bookmarkNotFound
        onClicked: moreMenuLoader.open()

        Accessible.name: qsTr("more options")

        // PostStats is part of list item delegates.
        // Dynamicly loading the menu on demand improves list scrolling performance
        Loader {
            id: moreMenuLoader
            active: false

            function open() {
                active = true
            }

            onStatusChanged: {
                if (status == Loader.Ready)
                    item.open()
            }

            sourceComponent: Menu {
                id: moreMenu
                modal: true

                onAboutToShow: SkyRoot.root.enablePopupShield(true)
                onAboutToHide: { SkyRoot.root.enablePopupShield(false); parent.active = false }

                CloseMenuItem {
                    text: qsTr("<b>Post</b>")
                    Accessible.name: qsTr("close more options menu")
                }
                AccessibleMenuItem {
                    text: qsTr("Translate")
                    onTriggered: postStats.translatePost()

                    MenuItemSvg { svg: SvgOutline.googleTranslate }
                }

                AccessibleMenuItem {
                    text: qsTr("Copy post text")
                    enabled: !postStats.embeddingDisabled
                    onTriggered: postStats.copyPostText()

                    MenuItemSvg { svg: SvgOutline.copy }
                }
                AccessibleMenuItem {
                    text: qsTr("Share")
                    enabled: !postStats.embeddingDisabled
                    onTriggered: postStats.share()

                    MenuItemSvg { svg: SvgOutline.share }
                }
                AccessibleMenuItem {
                    text: postStats.threadMuted ? qsTr("Unmute thread") : qsTr("Mute thread")
                    visible: !postStats.isReply || postStats.replyRootUri
                    onTriggered: postStats.muteThread()

                    MenuItemSvg { svg: postStats.threadMuted ? SvgOutline.notifications : SvgOutline.notificationsOff }
                }

                AccessibleMenuItem {
                    text: postStats.isHiddenReply ? qsTr("Unhide reply") : qsTr("Hide reply")
                    visible: postStats.isReply && !postStats.authorIsUser && postStats.isThreadFromUser()
                    onTriggered: postStats.hideReply()

                    MenuItemSvg { svg: postStats.isHiddenReply ? SvgOutline.visibility : SvgOutline.hideVisibility }
                }

                AccessibleMenuItem {
                    text: qsTr("Restrictions")
                    visible: postStats.authorIsUser
                    onTriggered: postStats.threadgate()

                    MenuItemSvg { svg: postStats.replyRestriction !== QEnums.REPLY_RESTRICTION_NONE ? SvgOutline.replyRestrictions : SvgOutline.noReplyRestrictions }
                }

                AccessibleMenuItem {
                    text: postStats.recordIsDetached() ? qsTr("Re-attach quote") : qsTr("Detach quote")
                    visible: postStats.hasOwnRecord()
                    onTriggered: postStats.detachQuote(postStats.getRecordPostUri(), !postStats.recordIsDetached())

                    MenuItemSvg { svg: postStats.recordIsDetached() ? SvgOutline.attach : SvgOutline.detach }
                }

                AccessibleMenuItem {
                    text: postStats.viewerStatePinned ? qsTr("Unpin from profile") : qsTr("Pin to profile")
                    visible: postStats.authorIsUser
                    onTriggered: {
                        if (postStats.viewerStatePinned)
                            postStats.unpin()
                        else
                            postStats.pin()
                    }

                    MenuItemSvg { svg: postStats.viewerStatePinned ? SvgFilled.unpin : SvgFilled.pin }
                }

                AccessibleMenuItem {
                    text: qsTr("Delete")
                    visible: postStats.authorIsUser
                    onTriggered: postStats.deletePost()

                    MenuItemSvg { svg: SvgOutline.delete }
                }
                AccessibleMenuItem {
                    text: qsTr("Report post")
                    visible: !postStats.authorIsUser
                    onTriggered: postStats.reportPost()

                    MenuItemSvg { svg: SvgOutline.report }
                }
            }
        }
    }

    AccessibilityUtils {
        id: accessibilityUtils
    }

    GuiSettings {
        id: guiSettings
    }

    function getRecordPostUri() {
        if (record)
            return record.detached ? record.detachedPostUri : record.postUri

        if (recordWithMedia)
            return recordWithMedia.record.detached ? recordWithMedia.record.detachedPostUri : recordWithMedia.record.postUri

        return ""
    }

    function recordIsDetached() {
        if (record)
            return record.detached

        if (recordWithMedia)
            return recordWithMedia.record.detached

        return false
    }

    function hasOwnRecord() {
        if (record)
            return record.detached ? isUserDid(record.detachedByDid) : isUserDid(record.author.did)

        if (recordWithMedia)
            return recordWithMedia.record.detached ? isUserDid(recordWithMedia.record.detachedByDid)  : isUserDid(recordWithMedia.record.author.did)

        return false
    }

    function isThreadFromUser() {
        if (!isReply)
            return authorIsUser

        return isUserDid(replyRootAuthorDid)
    }

    function isUserDid(did) {
        return SkyRoot.skywalker().getUserDid() === did
    }

    function statSpeech(stat, textSingular, textPlural) {
        return accessibilityUtils.statSpeech(stat, textSingular, textPlural)
    }
}
