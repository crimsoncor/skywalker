// TODO: causes crash, see addPost, pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Window 2.2
import skywalker

SkyPage {
    required property var skywalker
    property string initialText
    property string initialImage
    property string initialVideo: ""
    property int margin: 15

    readonly property int maxPostLength: 300
    readonly property int maxThreadPosts: 99
    readonly property int minPostSplitLineLength: 30
    readonly property int maxImages: 4 // per post
    property bool pickingImage: false

    // Reply restrictions (on post thread)
    property bool restrictReply: false
    property bool allowReplyMentioned: false
    property bool allowReplyFollowing: false
    property list<int> allowListIndexes: [0, 1, 2]
    property list<bool> allowLists: [false, false, false]
    property list<string> allowListUrisFromDraft: []
    property int restrictionsListModelId: -1
    property bool allowQuoting: true

    // Reply-to (first post)
    property basicprofile replyToAuthor
    property string replyToPostUri: ""
    property string replyToPostCid: ""
    property string replyRootPostUri: ""
    property string replyRootPostCid: ""
    property string replyToPostText
    property date replyToPostDateTime
    property string replyToLanguage

    // Quote post (for first post only)
    property bool openedAsQuotePost: false
    property basicprofile quoteAuthor
    property string quoteUri: ""
    property string quoteCid: ""
    property string quoteText
    property date quoteDateTime

    property basicprofile nullAuthor
    property generatorview nullFeed
    property listview nullList
    property tenorgif nullGif

    readonly property string userDid: skywalker.getUserDid()
    property bool requireAltText: skywalker.getUserSettings().getRequireAltText(userDid)
    property bool threadAutoNumber: skywalker.getUserSettings().getThreadAutoNumber()
    property string threadPrefix: skywalker.getUserSettings().getThreadPrefix()
    property bool threadAutoSplit: skywalker.getUserSettings().getThreadAutoSplit()

    property int currentPostIndex: 0

    // Current post of a thread being sent
    property int sendingThreadPost: -1
    property string threadRootUri
    property string threadRootCid

    // Can be different from threadRoot if the thread is a reply to an existing post
    property string threadFirstPostUri
    property string threadFirstPostCid
    property bool threadGateCreated: false
    property list<string> postedUris: []

    property bool isAnniversary: skywalker.getAnniversary().isAnniversary()

    // Cache
    property list<string> tmpImages: []
    property list<string> tmpVideos: []

    signal closed

    id: page
    width: parent.width
    height: parent.height
    contentHeight: flick.height
    topPadding: 0
    bottomPadding: 10

    header: Rectangle {
        width: parent.width
        height: guiSettings.headerHeight
        z: guiSettings.headerZLevel
        color: guiSettings.headerColor

        SvgButton {
            id: cancelButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            svg: SvgOutline.cancel
            accessibleName: qsTr("cancel posting")
            onClicked: page.cancel()
        }

        Avatar {
            anchors.centerIn: parent
            height: parent.height - 10
            width: height
            author: SkyRoot.skywalker().user
            onClicked: SkyRoot.skywalker().showStatusMessage(qsTr("Yes, you're gorgeous!"), QEnums.STATUS_LEVEL_INFO)
            onPressAndHold: SkyRoot.skywalker().showStatusMessage(qsTr("Yes, you're really gorgeous!"), QEnums.STATUS_LEVEL_INFO)

            Accessible.role: Accessible.Button
            Accessible.name: qsTr("your avatar")
            Accessible.onPressAction: clicked()
        }

        SkyButton {
            property bool isPosting: false

            id: postButton
            anchors.right: moreOptions.left
            anchors.verticalCenter: parent.verticalCenter
            text: page.replyToPostUri ? qsTr("Reply", "verb on post composition") : qsTr("Post", "verb on post composition")
            enabled: !isPosting && page.postsAreValid() && page.hasFullContent() && page.checkAltText()
            onClicked: sendPost()
            Accessible.name: page.replyToPostUri ? qsTr("send reply") : qsTr("send post")

            function sendPost() {
                postButton.isPosting = true
                threadPosts.copyPostItemsToPostList()

                if (threadPosts.count === 1) {
                    page.sendSinglePost(threadPosts.postList[0],
                                   page.replyToPostUri, page.replyToPostCid,
                                   page.replyRootPostUri, page.replyRootPostCid, 0, 1)
                }
                else {
                    page.sendThreadPosts(0, page.replyToPostUri, page.replyToPostCid,
                                    page.replyRootPostUri, page.replyRootPostCid)
                }
            }
        }

        SvgButton {
            id: moreOptions
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            svg: SvgOutline.moreVert
            accessibleName: qsTr("post options")
            onClicked: moreMenu.open()

            Menu {
                id: moreMenu
                width: Math.max(altItem.width, numberPrefixItem.width)
                modal: true

                onAboutToShow: SkyRoot.root.enablePopupShield(true)
                onAboutToHide: SkyRoot.root.enablePopupShield(false)

                CloseMenuItem {
                    text: qsTr("<b>Options</b>")
                    Accessible.name: qsTr("close options menu")
                }
                AccessibleMenuItem {
                    id: altItem
                    text: qsTr("Require ALT text")
                    checkable: true
                    checked: SkyRoot.skywalker().getUserSettings().getRequireAltText(page.userDid)

                    onToggled:{
                        page.requireAltText = checked
                        SkyRoot.skywalker().getUserSettings().setRequireAltText(page.userDid, checked)
                    }
                }
                AccessibleMenuItem {
                    id: autoNumberItem
                    text: qsTr("Auto number")
                    checkable: true
                    checked: SkyRoot.skywalker().getUserSettings().getThreadAutoNumber()

                    onToggled: {
                        page.threadAutoNumber = checked
                        SkyRoot.skywalker().getUserSettings().setThreadAutoNumber(checked)
                    }
                }
                AccessibleMenuItem {
                    id: numberPrefixItem
                    contentItem: AccessibleText {
                        textFormat: Text.RichText
                        text: qsTr(`Number prefix: ${(page.threadPrefix ? unicodeFonts.toCleanedHtml(page.threadPrefix) : qsTr("<i>&lt;none&gt;</i>"))}`)
                    }
                    enabled: autoNumberItem.checked
                    onTriggered: page.editThreadPrefix()
                }
                AccessibleMenuItem {
                    text: qsTr("Auto split")
                    checkable: true
                    checked: SkyRoot.skywalker().getUserSettings().getThreadAutoSplit()

                    onToggled: {
                        page.threadAutoSplit = checked
                        SkyRoot.skywalker.getUserSettings().setThreadAutoSplit(checked)
                    }
                }
                AccessibleMenuItem {
                    text: qsTr("Merge posts")
                    enabled: threadPosts.count > 1
                    onTriggered: threadColumn.mergePosts()
                }
                AccessibleMenuItem {
                    text: qsTr("Video limits")
                    onTriggered: {
                        busyIndicator.running = true
                        postUtils.getVideoUploadLimits()
                    }
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: page.width
        contentHeight: threadColumn.y + threadColumn.height
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        onHeightChanged: {
            let postItem = page.currentPostItem()

            if (!postItem)
                return

            let postText = postItem.getPostText()
            postText.ensureVisible(postText.cursorRectangle)
        }

        // Reply-to
        Rectangle {
            radius: 10
            anchors.fill: replyToColumn
            border.width: 1
            border.color: guiSettings.borderColor
            color: guiSettings.postHighLightColor
            visible: replyToColumn.visible
        }
        QuotePost {
            id: replyToColumn
            y: 10
            width: parent.width - 2 * page.margin
            anchors.horizontalCenter: parent.horizontalCenter
            author: page.replyToAuthor
            postText: page.replyToPostText
            postDateTime: page.replyToPostDateTime
            ellipsisBackgroundColor: guiSettings.postHighLightColor
            visible: page.replyToPostUri
        }

        Column {
            id: threadColumn
            y: replyToColumn.y + (replyToColumn.visible ? replyToColumn.height + 5 : 0)
            width: parent.width

            Repeater {
                property list<ComposePostItem> postList: [
                    ComposePostItem {
                        text: page.initialText ? page.initialText : ""
                        images: page.initialImage ? [page.initialImage] : []
                        altTexts: page.initialImage ? [""] : []
                        memeTopTexts: page.initialImage ? [""] : []
                        memeBottomTexts: page.initialImage ? [""] : []
                        quoteAuthor: page.quoteAuthor
                        quoteUri: page.quoteUri
                        quoteCid: page.quoteCid
                        quoteText: page.quoteText
                        quoteDateTime: page.quoteDateTime
                        language: page.replyToLanguage ? page.replyToLanguage : languageUtils.defaultPostLanguage
                        video: ""
                        videoAltText: ""
                    }
                ]

                id: threadPosts
                width: parent.width
                model: 1

                Item {
                    required property int index
                    property string text
                    property list<string> images
                    property list<string> altTexts
                    property list<string> memeTopTexts
                    property list<string> memeBottomTexts
                    property basicprofile quoteAuthor
                    property string quoteUri
                    property string quoteCid
                    property string quoteText
                    property date quoteDateTime
                    property bool quoteFixed: false
                    property generatorview quoteFeed
                    property listview quoteList
                    property bool cwSuggestive: false
                    property bool cwNudity: false
                    property bool cwPorn: false
                    property bool cwGore: false
                    property string language
                    property string video
                    property string videoAltText
                    property int videoNewHeight
                    property int videoStartMs
                    property int videoEndMs

                    function copyToPostList() {
                        threadPosts.postList[index].text = text
                        threadPosts.postList[index].images = images
                        threadPosts.postList[index].altTexts = altTexts
                        threadPosts.postList[index].memeTopTexts = memeTopTexts
                        threadPosts.postList[index].memeBottomTexts = memeBottomTexts
                        threadPosts.postList[index].quoteAuthor = quoteAuthor
                        threadPosts.postList[index].quoteUri = quoteUri
                        threadPosts.postList[index].quoteCid = quoteCid
                        threadPosts.postList[index].quoteText = quoteText
                        threadPosts.postList[index].quoteDateTime = quoteDateTime
                        threadPosts.postList[index].quoteFixed = quoteFixed
                        threadPosts.postList[index].quoteFeed = quoteFeed
                        threadPosts.postList[index].quoteList = quoteList
                        threadPosts.postList[index].gif = gifAttachment.gif
                        threadPosts.postList[index].card = linkCard.card
                        threadPosts.postList[index].cwSuggestive = cwSuggestive
                        threadPosts.postList[index].cwNudity = cwNudity
                        threadPosts.postList[index].cwPorn = cwPorn
                        threadPosts.postList[index].cwGore = cwGore
                        threadPosts.postList[index].language = language
                        threadPosts.postList[index].video = video
                        threadPosts.postList[index].videoAltText = videoAltText
                        threadPosts.postList[index].videoNewHeight = videoNewHeight
                        threadPosts.postList[index].videoStartMs = videoStartMs
                        threadPosts.postList[index].videoEndMs = videoEndMs
                    }

                    function copyFromPostList() {
                        images = threadPosts.postList[index].images
                        altTexts = threadPosts.postList[index].altTexts
                        memeTopTexts = threadPosts.postList[index].memeTopTexts
                        memeBottomTexts = threadPosts.postList[index].memeBottomTexts
                        quoteAuthor = threadPosts.postList[index].quoteAuthor
                        quoteUri = threadPosts.postList[index].quoteUri
                        quoteCid = threadPosts.postList[index].quoteCid
                        quoteText = threadPosts.postList[index].quoteText
                        quoteDateTime = threadPosts.postList[index].quoteDateTime
                        quoteFixed = threadPosts.postList[index].quoteFixed
                        quoteFeed = threadPosts.postList[index].quoteFeed
                        quoteList = threadPosts.postList[index].quoteList
                        linkCard.card = threadPosts.postList[index].card

                        if (!threadPosts.postList[index].gif.isNull())
                            gifAttachment.show(threadPosts.postList[index].gif)
                        else
                            gifAttachment.hide()

                        cwSuggestive = threadPosts.postList[index].cwSuggestive
                        cwNudity = threadPosts.postList[index].cwNudity
                        cwPorn = threadPosts.postList[index].cwPorn
                        cwGore = threadPosts.postList[index].cwGore
                        language = threadPosts.postList[index].language
                        video = threadPosts.postList[index].video
                        videoAltText = threadPosts.postList[index].videoAltText
                        videoNewHeight = threadPosts.postList[index].videoNewHeight
                        videoStartMs = threadPosts.postList[index].videoStartMs
                        videoEndMs = threadPosts.postList[index].videoEndMs

                        // Set text last as it will trigger link extractions which
                        // will check if a link card is already in place.
                        text = threadPosts.postList[index].text
                    }

                    function getPostText() { return postText }
                    function getImageScroller() { return imageScroller }
                    function getGifAttachment() { return gifAttachment }
                    function getLinkCard() { return linkCard }

                    function hasAttachment() {
                        return imageScroller.images.length > 0 ||
                                Boolean(videoAttachement.video) ||
                                !gifAttachment.gif.isNull() ||
                                linkCard.card ||
                                quoteFixed
                    }

                    function calcHeight() {
                        if (quoteColumn.visible)
                            return quoteColumn.y + quoteColumn.height

                        if (quoteFeedColumn.visible)
                            return quoteFeedColumn.y + quoteFeedColumn.height

                        if (quoteListColumn.visible)
                            return quoteListColumn.y + quoteListColumn.height

                        return quoteColumn.y
                    }

                    function hasContent() {
                        return postText.graphemeLength > 0 || hasAttachment()
                    }

                    function isValid() {
                        return postText.graphemeLength <= postText.maxLength
                    }

                    function fixQuoteLink(fix) {
                        quoteFixed = fix

                        if (!fix) {
                            quoteUri = ""
                            quoteList = page.nullList
                            quoteFeed = page.nullFeed
                        }
                    }

                    id: postItem
                    width: parent.width
                    height: calcHeight()
                    opacity: index === page.currentPostIndex ? 1.0 : 0.6

                    SeparatorLine {
                        id: separatorLine
                        visible: postItem.index > 0
                    }

                    SkyFormattedTextEdit {
                        property bool splitting: false

                        id: postText
                        anchors.top: separatorLine.bottom
                        width: parent.width
                        leftPadding: page.margin
                        rightPadding: page.margin
                        topPadding: 0
                        bottomPadding: 0
                        parentPage: page
                        parentFlick: flick
                        placeholderText: postItem.index === 0 ? qsTr("Say something nice") : qsTr(`Add post ${(postItem.index + 1)}`)
                        initialText: postItem.text
                        maxLength: page.maxPostLength - postCountText.size()
                        fontSelectorCombo: fontSelector

                        onTextChanged: {
                            postItem.text = text

                            if (page.threadAutoSplit && graphemeLength > maxLength && !splitting) {
                                console.debug("SPLIT:", postItem.index)

                                // Avoid to re-split when the post count text becomes visible or longer
                                const maxPartLength = page.maxPostLength - postCountText.maxSize()
                                const parts = unicodeFonts.splitText(text, maxPartLength, page.minPostSplitLineLength, 2)

                                if (parts.length > 1) {
                                    const moveCursor = cursorPosition > parts[0].length && postItem.index === page.currentPostIndex
                                    const oldCursorPosition = cursorPosition

                                    splitting = true
                                    text = parts[0].trim()

                                    if (!moveCursor && postItem.index === page.currentPostIndex)
                                        cursorPosition = oldCursorPosition

                                    splitting = false

                                    if (postItem.index === threadPosts.count - 1 || threadPosts.itemAt(postItem.index + 1).hasAttachment()) {
                                        threadColumn.addPost(postItem.index, parts[1], moveCursor)
                                    }
                                    else {
                                        // Prepend excess text to next post
                                        let nextPostText = threadPosts.itemAt(postItem.index + 1).getPostText()
                                        const newText = joinPosts(parts[1], nextPostText.text)
                                        const newCursorPosition = moveCursor ? oldCursorPosition - parts[0].length : -1

                                        setPostTextTimer.startSetText(newText, postItem.index + 1, newCursorPosition)

                                        if (moveCursor)
                                            currentPostIndex = postItem.index + 1
                                    }
                                }
                            }
                        }

                        onFocusChanged: {
                            if (focus)
                                page.currentPostIndex = postItem.index
                        }

                        onFirstWebLinkChanged: {
                            if (gifAttachment.visible)
                                return

                            if (linkCard.card && linkCard.card.link === firstWebLink)
                                return

                            if (linkCard.linkFixed)
                                return

                            linkCard.hide()

                            if (firstWebLink) {
                                linkCardTimer.startForLink(index, firstWebLink)
                            } else {
                                linkCardTimer.stop()
                            }
                        }

                        onCursorInFirstWebLinkChanged: {
                            if (!cursorInFirstWebLink && linkCard.card)
                                linkCard.linkFixed = true
                        }

                        onFirstPostLinkChanged: {
                            if (page.openedAsQuotePost && postItem.index === 0)
                                return

                            if (postItem.quoteFixed)
                                return

                            postItem.quoteList = page.nullList
                            postItem.quoteFeed = page.nullFeed
                            postItem.quoteUri = ""

                            if (firstPostLink)
                                postUtils.getQuotePost(firstPostLink)
                        }

                        onCursorInFirstPostLinkChanged: {
                            if (!cursorInFirstPostLink && postItem.quoteUri)
                                postItem.fixQuoteLink(true)
                        }

                        onFirstFeedLinkChanged: {
                            if (page.openedAsQuotePost && postItem.index === 0)
                                return

                            if (postItem.quoteFixed)
                                return

                            postItem.quoteList = page.nullList
                            postItem.quoteFeed = page.nullFeed

                            if (firstPostLink)
                                return

                            if (firstFeedLink)
                                postUtils.getQuoteFeed(firstFeedLink)
                        }

                        onCursorInFirstFeedLinkChanged: {
                            if (!cursorInFirstFeedLink && !postItem.quoteFeed.isNull())
                                postItem.fixQuoteLink(true)
                        }

                        onFirstListLinkChanged: {
                            if (page.openedAsQuotePost && postItem.index === 0)
                                return

                            if (postItem.quoteFixed)
                                return

                            postItem.quoteList = page.nullList

                            if (firstPostLink || firstFeedLink)
                                return

                            if (firstListLink)
                                postUtils.getQuoteList(firstListLink)
                        }

                        onCursorInFirstListLinkChanged: {
                            if (!cursorInFirstListLink && !postItem.quoteList.isNull())
                                postItem.fixQuoteLink(true)
                        }
                    }

                    SvgButton {
                        y: postText.y - 6
                        x: parent.width - width - 10
                        z: 10
                        width: 34
                        height: width
                        svg: SvgOutline.remove
                        accessibleName: qsTr("remove post")
                        visible: !postItem.hasContent() && threadPosts.count > 1 && (postItem.index > 0 || !page.replyToPostUri)

                        onClicked: threadColumn.removePost(postItem.index)
                    }

                    AccessibleText {
                        id: postCountText
                        width: page.width
                        leftPadding: page.margin
                        rightPadding: page.margin
                        anchors.top: postText.bottom
                        textFormat: Text.RichText
                        text: page.getPostCountText(postItem.index, threadPosts.count)
                        visible: threadPosts.count > 1 && page.threadAutoNumber

                        function size() {
                            // +1 for newline
                            return visible ? text.length + 1 : 0
                        }

                        function maxSize() {
                            if (!page.threadAutoNumber)
                                return 0

                            const countText = getPostCountText(page.maxThreadPosts, page.maxThreadPosts)
                            return countText.length + 1
                        }
                    }

                    // Image attachments
                    ImageScroller {
                        property alias images: postItem.images
                        property alias altTexts: postItem.altTexts
                        property alias memeTopTexts: postItem.memeTopTexts
                        property alias memeBottomTexts: postItem.memeBottomTexts

                        id: imageScroller
                        width: page.width
                        anchors.top: postCountText.visible ? postCountText.bottom : postText.bottom
                        horizontalPadding: page.margin
                        requireAltText: page.requireAltText
                        postUtils: page.getPostUtils()
                        visible: !linkCard.visible && !gifAttachment.visible
                    }

                    VideoAttachment {
                        property alias video: postItem.video
                        property alias altText: postItem.videoAltText
                        property alias startMs: postItem.videoStartMs
                        property alias endMs: postItem.videoEndMs
                        property alias newHeight: postItem.videoNewHeight

                        id: videoAttachement
                        x: page.margin
                        width: Math.min(height * 1.777, page.width - 2 * page.margin)
                        height: visible ? 180 : 0
                        anchors.top: imageScroller.bottom
                        anchors.topMargin: visible ? 10 : 0
                        videoSource: video
                        videoStartMs: startMs
                        videoEndMs: endMs
                        requireAltText: page.requireAltText
                        visible: Boolean(video) && !linkCard.visible && !linkCard.visible

                        onEdit: page.editVideo(video, startMs, endMs, newHeight)
                    }

                    // GIF attachment
                    AnimatedImage {
                        property tenorgif gif

                        id: gifAttachment
                        x: page.margin
                        width: Math.min(gif ? gif.smallSize.width : 1, page.width - 2 * page.margin)
                        anchors.top: videoAttachement.bottom
                        anchors.topMargin: !gif.isNull() ? 10 : 0
                        fillMode: Image.PreserveAspectFit
                        source: !gif.isNull() ? gif.smallUrl : ""
                        visible: !gif.isNull()

                        onGifChanged: threadPosts.postList[postItem.index].gif = gif

                        Accessible.role: Accessible.StaticText
                        Accessible.name: qsTr("GIF image")

                        function show(gif) {
                            gifAttachment.gif = gif
                            linkCard.hide()
                        }

                        function hide() {
                            gifAttachment.gif = page.nullGif
                        }

                        SvgButton {
                            x: parent.width - width
                            width: 34
                            height: width
                            svg: SvgOutline.close
                            accessibleName: qsTr("remove GIF image")
                            onClicked: gifAttachment.hide()
                        }
                    }

                    // Link card attachment
                    LinkCardView {
                        property var card: null
                        property bool linkFixed: false

                        id: linkCard
                        x: page.margin
                        width: page.width - 2 * page.margin
                        height: card ? columnHeight : 0
                        anchors.top: gifAttachment.bottom
                        anchors.topMargin: card ? 10 : 0
                        uri: card ? card.link : ""
                        title: card ? card.title : ""
                        description: card ? card.description : ""
                        thumbUrl: card ? card.thumb : ""
                        contentVisibility: QEnums.CONTENT_VISIBILITY_SHOW
                        contentWarning: ""
                        visible: card

                        onCardChanged: threadPosts.postList[postItem.index].card = card

                        Accessible.role: Accessible.StaticText
                        Accessible.name: getSpeech()

                        function getSpeech() {
                            if (!card)
                                return ""

                            const hostname = new URL(card.link).hostname
                            return qsTr("link card: ") + card.title + "\n\nfrom: " + hostname + "\n\n" + card.description
                        }

                        function show(card) {
                            linkCard.card = card
                            gifAttachment.hide()
                        }

                        function hide() {
                            linkCard.card = null
                            linkCard.linkFixed = false
                        }

                        SvgButton {
                            x: parent.width - width
                            width: 34
                            height: width
                            svg: SvgOutline.close
                            accessibleName: qsTr("remove link card")
                            onClicked: linkCard.hide()
                        }
                    }

                    // Quote post
                    Rectangle {
                        radius: 10
                        anchors.fill: quoteColumn
                        border.width: 1
                        border.color: guiSettings.borderColor
                        color: guiSettings.postHighLightColor
                        visible: quoteColumn.visible
                    }
                    QuotePost {
                        id: quoteColumn
                        width: parent.width - 2 * page.margin
                        anchors.top: linkCard.bottom
                        anchors.topMargin: visible ? 5 : 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        author: postItem.quoteAuthor
                        postText: postItem.quoteText
                        postDateTime: postItem.quoteDateTime
                        ellipsisBackgroundColor: guiSettings.postHighLightColor
                        showCloseButton: postItem.quoteFixed
                        visible: postItem.quoteUri

                        onCloseClicked: {
                            postItem.fixQuoteLink(false)
                            postItem.getPostText().forceActiveFocus()
                        }
                    }

                    // Quote feed
                    Rectangle {
                        radius: 10
                        anchors.fill: quoteFeedColumn
                        border.width: 1
                        border.color: guiSettings.borderColor
                        color: guiSettings.postHighLightColor
                        visible: quoteFeedColumn.visible
                    }
                    QuoteFeed {
                        id: quoteFeedColumn
                        width: parent.width - 2 * page.margin
                        anchors.top: linkCard.bottom
                        anchors.topMargin: visible ? 5 : 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        feed: postItem.quoteFeed
                        showCloseButton: postItem.quoteFixed
                        visible: !postItem.quoteFeed.isNull()

                        onCloseClicked: {
                            postItem.fixQuoteLink(false)
                            postItem.getPostText().forceActiveFocus()
                        }
                    }

                    // Quote list
                    Rectangle {
                        radius: 10
                        anchors.fill: quoteListColumn
                        border.width: 1
                        border.color: guiSettings.borderColor
                        color: guiSettings.postHighLightColor
                        visible: quoteListColumn.visible
                    }
                    QuoteList {
                        id: quoteListColumn
                        width: parent.width - 2 * page.margin
                        anchors.top: linkCard.bottom
                        anchors.topMargin: visible ? 5 : 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        list: postItem.quoteList
                        showCloseButton: postItem.quoteFixed
                        visible: !postItem.quoteList.isNull()

                        onCloseClicked: {
                            postItem.fixQuoteLink(false)
                            postItem.getPostText().forceActiveFocus()
                        }
                    }
                }

                function newComposePostItem() {
                    let component = Qt.createComponent("ComposePostItem.qml")
                    return component.createObject(page)
                }

                function copyPostItemsToPostList() {
                    for (let i = 0; i < count; ++i) {
                        let item = itemAt(i)
                        item.copyToPostList()
                    }
                }

                function copyPostListToPostItems() {
                    for (let i = 0; i < count; ++i) {
                        let item = itemAt(i)
                        item.copyFromPostList()
                    }
                }
            }

            function removePost(index) {
                console.debug("REMOVE POST:", index)

                if (threadPosts.count === 1) {
                    console.warn("Cannot remove last post")
                    return
                }

                let item = threadPosts.itemAt(index)
                item.images.forEach((value, index, array) => { postUtils.dropPhoto(value); })

                if (Boolean(item.video))
                    postUtils.dropVideo(item.video)

                threadPosts.copyPostItemsToPostList()

                if (index === 0 && page.openedAsQuotePost) {
                    page.openedAsQuotePost = false
                }

                if (page.currentPostIndex === threadPosts.count - 1)
                    page.currentPostIndex -= 1

                threadPosts.model = 0
                threadPosts.postList.splice(index, 1)
                threadPosts.model = threadPosts.postList.length

                threadPosts.copyPostListToPostItems()
                moveFocusToCurrent()
                console.debug("REMOVED POST:", index)
            }

            function addPost(index, text = "", focus = true) {
                console.debug("ADD POST:", index, "current:", page.currentPostIndex)

                if (threadPosts.count >= page.maxThreadPosts) {
                    console.warn("Maximum posts reached:", threadPosts.count)
                    return
                }

                const postItem = threadPosts.itemAt(page.currentPostIndex);
                const oldCursorPosition = postItem.getPostText().cursorPosition
                const lang = postItem.language

                threadPosts.copyPostItemsToPostList()
                threadPosts.model = 0 // TODO this causes a crash when ComponentBehavior = Bound

                let newItem = threadPosts.newComposePostItem()
                newItem.language = lang
                threadPosts.postList.splice(index + 1, 0, newItem)
                threadPosts.model = threadPosts.postList.length
                threadPosts.copyPostListToPostItems()

                if (page.currentPostIndex === index && focus) {
                    page.currentPostIndex += 1
                    focusTimer.start()
                }
                else {
                    setCursorTimer.startSetCursor(currentPostIndex, oldCursorPosition)
                }

                if (text)
                    setPostTextTimer.startSetText(text, index + 1)

                console.debug("ADDED POST:", index)
            }

            function mergePosts() {
                for (let i = 0; i < threadPosts.count; ++i) {
                    let item = threadPosts.itemAt(i)

                    if (item.hasAttachment())
                        continue

                    let postText = item.getPostText()
                    if (postText.text.length === postText.maxLength)
                        continue

                    i = mergePostsAt(i)
                }
            }

            function mergePostsAt(index) {
                if (index === threadPosts.count - 1)
                    return index

                let text = threadPosts.itemAt(index).getPostText().text
                let endIndex = index + 1

                while (endIndex < threadPosts.count) {
                    let nextPost = threadPosts.itemAt(endIndex)

                    if (nextPost.hasAttachment())
                        break

                    text = page.joinPosts(text, nextPost.getPostText().text)
                    ++endIndex
                }

                if (endIndex === index + 1)
                    return index

                const maxLength = threadPosts.itemAt(endIndex - 1).getPostText().maxLength

                for (let i = index + 1; i < endIndex; ++i)
                    threadColumn.removePost(index + 1)

                const parts = unicodeFonts.splitText(text, maxLength, page.minPostSplitLineLengths)
                threadPosts.itemAt(index).getPostText().text = parts[0].trim()

                for (let j = 1; j < parts.length; ++j) {
                    threadColumn.addPost(index + j - 1, "", false)
                    threadPosts.itemAt(index + j).getPostText().text = parts[j].trim()
                }

                return index + parts.length - 1
            }

            function moveFocusToCurrent() {
                let postText = page.currentPostItem().getPostText()
                postText.cursorPosition = postText.text.length
                focusTimer.start()
            }
        }

        Rectangle {
            anchors.left: threadColumn.left
            anchors.top: parent.top
            anchors.bottom: threadColumn.bottom
            width: page.margin - 5
            opacity: 0.9
            visible: threadPosts.count > 1

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: guiSettings.threadStartColor(SkyRoot.skywalker().getUserSettings().threadColor)
                }
                GradientStop {
                    position: 1.0
                    color: guiSettings.threadMidColor(SkyRoot.skywalker().getUserSettings().threadColor)
                }
            }
        }
    }

    Text {
        id: draftsLink
        anchors.centerIn: parent
        font.pointSize: guiSettings.scaledFont(9/8)
        textFormat: Text.RichText
        text: qsTr(`<a href=\"drafts\" style=\"color: ${guiSettings.linkColor}\">Drafts</a>`)
        visible: threadPosts.count === 1 && !page.hasFullContent() && !page.replyToPostUri && !page.openedAsQuotePost && draftPosts.hasDrafts
        onLinkActivated: page.showDraftPosts()

        Accessible.role: Accessible.Link
        Accessible.name: unicodeFonts.toPlainText(text)
        Accessible.onPressAction: page.showDraftPosts()
    }

    Text {
        anchors.top: draftsLink.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        font.pointSize: guiSettings.scaledFont(9/8)
        textFormat: Text.RichText
        text: qsTr(`<a href=\"card\" style=\"color: ${guiSettings.linkColor}\">Add anniversary card</a>`)
        visible: page.isAnniversary && threadPosts.count === 1 && !page.hasFullContent() && !page.replyToPostUri && !page.openedAsQuotePost
        onLinkActivated: page.addAnniversaryCard()

        Accessible.role: Accessible.Link
        Accessible.name: unicodeFonts.toPlainText(text)
        Accessible.onPressAction: page.addAnniversaryCard()
    }

    footer: Rectangle {
        id: textFooter
        width: page.width
        height: getFooterHeight()
        z: guiSettings.footerZLevel
        color: guiSettings.footerColor

        function getFooterHeight() {
            return guiSettings.footerHeight + (page.replyToPostUri ? 0 : restrictionRow.height + footerSeparator.height)
        }

        Rectangle {
            id: footerSeparator
            width: parent.width
            height: page.replyToPostUri ? 0 : 1
            color: guiSettings.separatorColor
            visible: !page.replyToPostUri
        }

        Rectangle {
            id: restrictionRow
            anchors.top: footerSeparator.top
            width: parent.width
            height: page.replyToPostUri ? 0 : restrictionText.height + 10
            color: "transparent"
            visible: !page.replyToPostUri

            Accessible.role: Accessible.Link
            Accessible.name: getRestrictionsSpeech()
            Accessible.onPressAction: page.addReplyRestrictions()

            function getRestrictionsSpeech() {
                const speech = unicodeFonts.toPlainText(restrictionText.text)
                return qsTr(`${speech}, press to change reply restrictions`)
            }

            SkySvg {
                id: restrictionIcon
                x: 10
                y: height + 3
                width: 20
                height: 20
                color: guiSettings.linkColor
                svg: page.restrictReply ? SvgOutline.replyRestrictions : SvgOutline.noReplyRestrictions

                Accessible.ignored: true
            }
            Text {
                id: restrictionText
                y: 5
                anchors.left: restrictionIcon.right
                anchors.right: parent.right
                leftPadding: 5
                color: guiSettings.linkColor
                font.italic: true
                font.pointSize: guiSettings.scaledFont(7/8)
                wrapMode: Text.Wrap
                text: getRestrictionText()

                Accessible.ignored: true

                function getRestrictionText() {
                    const replyRestricionText = getReplyRestrictionText()

                    if (page.allowQuoting)
                        return replyRestricionText + " " + qsTr("Quoting allowed.")

                    return replyRestricionText + " " + qsTr("Quoting disabled.")
                }

                function getReplyRestrictionText() {
                    if (!page.restrictReply)
                        return qsTr("Everyone can reply.")

                    let restrictionList = []

                    if (allowReplyMentioned && allowReplyFollowing)
                        restrictionList.push(qsTr("mentioned and followed users"))
                    else if (allowReplyMentioned)
                        restrictionList.push(qsTr("mentioned users"))
                    else if (allowReplyFollowing)
                        restrictionList.push(qsTr("followed users"))

                    let listNames = []

                    for (let i = 0; i < allowLists.length; ++i) {
                        if (allowLists[i]) {
                            let model = skywalker.getListListModel(restrictionsListModelId)
                            const listView = model.getEntry(allowListIndexes[i])
                            const listName = unicodeFonts.toCleanedHtml(listView.name)
                            listNames.push(`<b>${listName}</b>`)
                        }
                    }

                    if (listNames.length === 0)
                        listNames = allowListUrisFromDraft

                    if (listNames.length > 0) {
                        const names = guiSettings.toWordSequence(listNames)
                        restrictionList.push(qsTr(`members of ${names}`))
                    }

                    if (restrictionList.length === 0)
                        return qsTr("Replies disabled.")

                    const restrictedListText = guiSettings.toWordSequence(restrictionList)
                    return qsTr(`Only ${restrictedListText} can reply.`)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: page.addReplyRestrictions()
            }
        }

        TextLengthBar {
            anchors.top: restrictionRow.bottom
            textField: page.currentPostItem() ? page.currentPostItem().getPostText() : null
        }

        SvgTransparentButton {
            id: addImage
            x: 10
            y: height + 5 + restrictionRow.height + footerSeparator.height
            accessibleName: qsTr("add picture")
            svg: SvgOutline.addImage
            enabled: page.canAddImage()

            onClicked: {
                const pickVideo = page.canAddVideo()

                if (Qt.platform.os === "android") {
                    page.pickingImage = postUtils.pickPhoto(pickVideo)
                } else {
                    fileDialog.pick(pickVideo)
                }
            }
        }

        AddGifButton {
            id: addGif
            x: addImage.x + addImage.width + 3
            y: height + 5 + restrictionRow.height + footerSeparator.height
            enabled: page.canAddGif()

            onSelectedGif: (gif) => page.currentPostItem().getGifAttachment().show(gif)
        }

        FontComboBox {
            id: fontSelector
            x: addGif.x + addGif.width + 8
            y: 5 + restrictionRow.height + footerSeparator.height + 6
            popup.height: Math.min(page.height - 20, popup.contentHeight)
            focusPolicy: Qt.NoFocus
        }

        LanguageComboBox {
            id: languageSelector
            allLanguages: languageUtils.languages
            usedLanguages: languageUtils.usedLanguages
            anchors.left: fontSelector.right
            anchors.leftMargin: 8
            y: 5 + restrictionRow.height + footerSeparator.height + 6
            popup.x: Math.max(-x, Math.min(0, page.width - popup.width - x))
            popup.height: Math.min(page.height - 20, popup.contentHeight)
            currentIndex: find(page.currentPostLanguage())
            reversedColors: languageUtils.isDefaultPostLanguageSet && currentValue === languageUtils.defaultPostLanguage
            focusPolicy: Qt.NoFocus

            onActivated: (index) => {
                page.currentPostItem().language = valueAt(index)
                console.debug("ACTIVATED LANG:", valueAt(index))

                if (!languageUtils.getDefaultLanguageNoticeSeen()) {
                    guiSettings.notice(page,
                        qsTr("To set this language as default for your posts, you can press and hold the language button for a second."))
                    languageUtils.setDefaultLanguageNoticeSeen(true)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: languageSelector.popup.open()
                onPressAndHold: {
                    if (languageUtils.isDefaultPostLanguageSet && languageSelector.currentValue === languageUtils.defaultPostLanguage)
                        languageUtils.defaultPostLanguage = ""
                    else
                        languageUtils.defaultPostLanguage = languageSelector.currentValue
                }
            }
        }

        SvgTransparentButton {
            id: contentWarningIcon
            anchors.left: languageSelector.right
            anchors.leftMargin: 8
            y: height + 5 + restrictionRow.height + footerSeparator.height
            accessibleName: qsTr("add content warning")
            svg: page.hasContentWarning() ? SvgOutline.hideVisibility : SvgOutline.visibility
            visible: page.hasImageContent()
            onClicked: page.addContentWarning()
        }

        SvgButton {
            id: addPost
            y: 5 + restrictionRow.height + footerSeparator.height
            width: 34
            height: 34
            anchors.rightMargin: 10
            anchors.right: parent.right
            svg: SvgOutline.add
            accessibleName: qsTr("add post")
            enabled: page.hasFullContent() && threadPosts.count < page.maxThreadPosts
            focusPolicy: Qt.NoFocus
            onClicked: {
                Qt.inputMethod.commit()
                threadColumn.addPost(currentPostIndex)
            }
        }
    }

    StatusPopup {
        id: statusPopup
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: false
    }

    ImageFileDialog {
        id: fileDialog
        onImageSelected: (fileUri) => page.photoPicked(fileUri)
        onVideoSelected: (fileUri) => page.videoPicked(fileUri)
    }

    LinkCardReader {
        property list<var> linksToGet: []

        id: linkCardReader

        onLinkCard: (card) => {
                        busyIndicator.running = false
                        console.debug("Got card:", card.link, card.title, card.thumb)
                        console.debug(card.description)
                        linkCardTimer.immediateGetInProgress = false

                        let postItem = threadPosts.itemAt(linkCardTimer.postIndex)

                        if (postItem) {
                            postItem.getLinkCard().show(card)
                            let postText = postItem.getPostText()

                            if (!postText.cursorInFirstWebLink)
                                postItem.getLinkCard().linkFixed = true
                            else
                                postText.cutLinkIfJustAdded(postText.firstWebLink, () => postItem.getLinkCard().linkFixed = true)
                        }

                        getNextLink()
                    }

        onLinkCardFailed: {
            busyIndicator.running = false
            console.debug("Failed to get link card")
            linkCardTimer.immediateGetInProgress = false
            getNextLink()
        }

        function getLink(postIndex, webLink) {
            if (!linkCardTimer.immediateGetInProgress) {
                linkCardTimer.getLinkImmediate(postIndex, webLink)
            }
            else {
                linksToGet.push([postIndex, webLink])
            }
        }

        function getNextLink() {
            if (linksToGet.length > 0) {
                const link = linksToGet.pop()
                getLink(link[0], link[1])
            }
        }
    }

    Timer {
        property int postIndex
        property string webLink
        property bool immediateGetInProgress: false

        id: linkCardTimer
        interval: 1000
        onTriggered: {
            busyIndicator.running = true
            linkCardReader.getLinkCard(webLink)
        }

        function startForLink(postIndex, webLink) {
            if (immediateGetInProgress) {
                console.debug("Immedate get in progress:", webLink)
                return
            }

            linkCardTimer.postIndex = postIndex
            linkCardTimer.webLink = webLink
            start()
        }

        function getLinkImmediate(postIndex, webLink) {
            stop()
            linkCardTimer.postIndex = postIndex
            linkCardTimer.webLink = webLink
            immediateGetInProgress = true
            linkCardReader.getLinkCard(webLink)
        }
    }

    PostUtils {
        property var callbackCanUploadVideo: () => {}
        property var callbackCannotUploadVideo: (error) => {}

        id: postUtils
        skywalker: page.skywalker

        onPostOk: (uri, cid) => {
            page.postedUris.push(uri)

            if (!page.allowQuoting)
                postUtils.addPostgate(uri, true, [])

            if (page.sendingThreadPost > -1)
                page.sendNextThreadPost(uri, cid)
            else if (page.restrictReply)
                postUtils.addThreadgate(uri, cid, page.allowReplyMentioned, page.allowReplyFollowing, page.getReplyRestrictionListUris())
            else      
                postDone()
        }

        onPostFailed: (error) => page.postFailed(error)

        onThreadgateOk: {
            page.threadGateCreated = true

            if (page.sendingThreadPost > -1)
                page.sendNextThreadPost(page.threadFirstPostUri, page.threadFirstPostCid)
            else
                page.postDone()
        }

        onThreadgateFailed: (error) => page.postFailed(error)

        onPostgateFailed: (error) => statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)

        onPostProgress: (msg) => page.postProgress(msg)

        onPhotoPicked: (imgSource, gifTempFileName) => {
            page.pickingImage = false
            page.photoPicked(imgSource, gifTempFileName)
            page.currentPostItem().getPostText().forceActiveFocus()
        }

        onVideoPicked: (videoUrl) => {
            page.pickingImage = false
            page.editVideo(videoUrl)
        }

        onVideoPickedFailed: (error) => {
            page.pickingImage = false
            statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)
            page.currentPostItem().getPostText().forceActiveFocus()
        }

        onPhotoPickFailed: (error) => {
            page.pickingImage = false
            statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)
            page.currentPostItem().getPostText().forceActiveFocus()
        }

        onPhotoPickCanceled: {
            page.pickingImage = false
            page.currentPostItem().getPostText().forceActiveFocus()
        }

        onQuotePost: (uri, cid, text, author, timestamp) => {
            let postItem = page.currentPostItem()
            let postText = postItem.getPostText()

            if (!postText.firstPostLink)
                return

            postItem.quoteList = page.nullList
            postItem.quoteFeed = page.nullFeed
            postItem.quoteUri = uri
            postItem.quoteCid = cid
            postItem.quoteText = text
            postItem.quoteAuthor = author
            postItem.quoteDateTime = timestamp

            if (!postText.cursorInFirstPostLink)
                postItem.fixQuoteLink(true)
            else
                postText.cutLinkIfJustAdded(postText.firstPostLink, () => postItem.fixQuoteLink(true))
        }

        onQuoteFeed: (feed) => {
            let postItem = page.currentPostItem()
            let postText = postItem.getPostText()

            if (!postText.firstFeedLink)
                return

            if (postText.firstPostLink)
                return

            postItem.quoteList = page.nullList
            postItem.quoteFeed = feed

            if (!postText.cursorInFirstFeedLink)
                postItem.fixQuoteLink(true)
            else
                postText.cutLinkIfJustAdded(postText.firstFeedLink, () => postItem.fixQuoteLink(true))
        }

        onQuoteList: (list) => {
            let postItem = page.currentPostItem()
            let postText = postItem.getPostText()

            if (!postText.firstListLink)
                return

            if (postText.firstPostLink || postText.firstFeedLink)
                return

            postItem.quoteList = list

            if (!postText.cursorInFirstListLink)
                postItem.fixQuoteLink(true)
            else
                postText.cutLinkIfJustAdded(postText.firstListLink, () => postItem.fixQuoteLink(true))
        }

        onVideoUploadLimits: (limits) => {
            busyIndicator.running = false
            page.showVideoUploadLimits(limits)
        }

        function checkVideoLimits(cbOk, cbFailed) {
            callbackCanUploadVideo = cbOk
            callbackCannotUploadVideo = cbFailed
            checkVideoUploadLimits()
        }

        onCheckVideoLimitsOk: {
            callbackCanUploadVideo()
            callbackCanUploadVideo = () => {}
            callbackCannotUploadVideo = (error) => {}
        }

        onCheckVideoLimitsFailed: (error) => {
            callbackCannotUploadVideo(error)
            callbackCanUploadVideo = () => {}
            callbackCannotUploadVideo = (error) => {}
        }
    }

    VideoUtils {
        property var callbackOk: (videoSource) => {}
        property var callbackFailed: (error) => {}

        id: videoUtils

        onTranscodingOk: (inputFileName, outputFileName) => {
            const source = "file://" + outputFileName
            page.tmpVideos.push(source)
            callbackOk(source)
            callbackOk = (videoSource) => {}
            callbackFailed = (error) => {}
        }

        onTranscodingFailed: (inputFileName, error) => {
            callbackFailed(error)
            callbackOk = (videoSource) => {}
            callbackFailed = (error) => {}
        }

        function transcode(videoSource, newHeight, startMs, endMs, cbOk, cbFailed) {
            callbackOk = cbOk
            callbackFailed = cbFailed
            const fileName = videoSource.slice(7)
            transcodeVideo(fileName, newHeight, startMs, endMs, cbOk)
            postProgress(qsTr("Transcoding video"))
        }
    }

    GifToVideoConverter {
        property var progressDialog

        id: gifToVideoConverter

        onConversionOk: (videoFileName) => {
            progressDialog.destroy()
            page.tmpVideos.push("file://" + videoFileName)
            page.editVideo(`file://${videoFileName}`)
        }

        onConversionFailed: (error) => {
            progressDialog.destroy()
            statusPopup.show(qsTr(`GIF conversion failed: ${error}`), QEnums.STATUS_LEVEL_ERROR)
        }

        onConversionProgress: (progress) => {
            if (progressDialog)
                progressDialog.setProgress(progress)
        }

        function start(gifFileName) {
            progressDialog = guiSettings.showProgress(page, qsTr("Converting GIF to Video"), () => doCancel())
            gifToVideoConverter.convert(gifFileName)
        }

        function doCancel() {
            gifToVideoConverter.cancel()
            let postItem = page.currentPostItem()

            if (postItem)
                postItem.getPostText().forceActiveFocus()
        }
    }

    DraftPosts {
        id: draftPosts
        skywalker: page.skywalker
        storageType: DraftPosts.STORAGE_FILE

        onSaveDraftPostOk: {
            statusPopup.show(qsTr("Saved post as draft"), QEnums.STATUS_LEVEL_INFO)
            page.closed()
        }

        onSaveDraftPostFailed: (error) => statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)
        onUploadingImage: (seq) => statusPopup.show(qsTr(`Uploading image #${seq}`), QEnums.STATUS_LEVEL_INFO)
        onLoadDraftPostsFailed: (error) => statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)
    }

    UnicodeFonts {
        id: unicodeFonts
    }

    LanguageUtils {
        id: languageUtils
        skywalker: page.skywalker
    }

    Tenor {
        id: tenor
        skywalker: page.skywalker
    }

    MemeMaker {
        id: memeMaker
    }

    Timer {
        property string text
        property int index
        property int cursorPosition

        id: setPostTextTimer
        interval: 0
        onTriggered: {
            let postText = threadPosts.itemAt(index).getPostText()

            if (cursorPosition > -1)
                setCursorTimer.startSetCursor(index, cursorPosition)

            postText.text = text
        }

        function startSetText(text, index, cursorPosition = -1) {
            setPostTextTimer.text = text
            setPostTextTimer.index = index
            setPostTextTimer.cursorPosition = cursorPosition
            start()
        }
    }

    Timer {
        property int index
        property int cursorPosition

        id: setCursorTimer
        interval: 0
        onTriggered: {
            let postText = threadPosts.itemAt(index).getPostText()
            postText.cursorPosition = cursorPosition
            postText.forceActiveFocus()
        }

        function startSetCursor(index, cursorPosition) {
            setCursorTimer.index = index
            setCursorTimer.cursorPosition = cursorPosition
            start()
        }
    }

    Timer {
        id: focusTimer
        interval: 200
        onTriggered: {
            let postText = page.currentPostItem().getPostText()

            if (!postText.text.startsWith("\n#")) // hashtag post
                postText.cursorPosition = postText.text.length

            if (Boolean(page.initialVideo)) {
                page.editVideo(page.initialVideo)
            }
            else {
                postText.ensureVisible(Qt.rect(0, 0, postText.width, postText.height))
                postText.forceActiveFocus()
            }
        }
    }

    GuiSettings {
        id: guiSettings
    }

    function getPostUtils() {
        return postUtils
    }

    function currentPostItem() {
        // Checking threadPosts.count here makes this function re-evaluate when count changes
        if (threadPosts.count === 0)
            console.debug("No thread posts available yet")

        return threadPosts.itemAt(currentPostIndex)
    }

    function postFailed(error) {
        busyIndicator.running = false
        statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)

        // Delete posts already posted (in a thread, or on failed thread gate creation)
        postUtils.batchDeletePosts(postedUris)

        // Clear all state so user can try to post again
        sendingThreadPost = -1
        threadRootUri = ""
        threadRootCid = ""
        threadFirstPostUri = ""
        threadFirstPostCid = ""
        threadGateCreated = false
        postedUris = []

        postButton.isPosting = false
    }

    function postProgress(msg) {
        busyIndicator.running = true

        if (sendingThreadPost < 0)
            statusPopup.show(msg, QEnums.STATUS_LEVEL_INFO, 300)
        else
            statusPopup.show(qsTr(`Post ${(sendingThreadPost + 1)}: ${msg}`), QEnums.STATUS_LEVEL_INFO, 300)
    }

    function checkAltText() {
        if (!requireAltText)
            return true

        for (let postIndex = 0; postIndex < threadPosts.count; ++postIndex) {
            const postItem = threadPosts.itemAt(postIndex)

            if (Boolean(postItem.video) && !Boolean(postItem.videoAltText))
                return false

            for (let i = 0; i < postItem.images.length; ++i) {
                if (i >= postItem.altTexts.length || postItem.altTexts[i].length === 0)
                    return false
            }
        }

        return true
    }

    // "file://" or "image://" source
    function photoPicked(source, gifTempFileName = "", altText = "") {
        if (gifTempFileName)
            page.tmpVideos.push("file://" + gifTempFileName)

        if (!canAddVideo()) {
            photoPickedContinued(source, altText)
            return
        }

        let gifFileName = gifTempFileName

        if (source.startsWith("file://") && source.endsWith(".gif"))
            gifFileName = source.slice(7)

        if (!gifFileName) {
            photoPickedContinued(source, altText)
            return
        }

        guiSettings.askConvertGif(
            page,
            "file://" + gifFileName,
            () => gifToVideoConverter.start(gifFileName),
            () => photoPickedContinued(source, altText))
    }

    function photoPickedContinued(source, altText = "") {
        console.debug("IMAGE:", source)
        let postItem = currentPostItem()

        if (!postItem)
            return

        postItem.altTexts.push(altText)
        postItem.images.push(source)
        postItem.memeTopTexts.push("")
        postItem.memeBottomTexts.push("")
        let scrollBar = postItem.getImageScroller().ScrollBar.horizontal
        scrollBar.position = 1.0 - scrollBar.size
        postItem.getPostText().forceActiveFocus()
    }

    function videoPicked(source, altText = "") {
        console.debug("VIDEO:", source)
        let postItem = currentPostItem()

        if (!postItem)
            return

        postItem.video = source
        postItem.videoAltText = altText
    }

    function addSharedText(text) {
        if (text) {
            let postItem = currentPostItem()

            if (!postItem)
                return

            postItem.getPostText().append(text)
        }
    }

    function addSharedPhoto(source, text) {
        let postItem = currentPostItem()

        if (!postItem)
            return

        if (!canAddImage()) {
            statusPopup.show(qsTr("Cannot add an image to this post."), QEnums.STATUS_LEVEL_INFO, 30)
            postUtils.dropPhoto(source)
            return
        }

        photoPicked(source)
        addSharedText(text)
    }

    function addSharedVideo(source, text) {
        let postItem = currentPostItem()

        if (!postItem)
            return

        if (!canAddVideo()) {
            statusPopup.show(qsTr("Cannot add video to this post."), QEnums.STATUS_LEVEL_INFO, 30)
            postUtils.dropVideo(source)
            return
        }

        addSharedText(text)
        editVideo(source)
    }

    function postDone() {
        busyIndicator.running = false
        page.closed()
    }

    function postsAreValid() {
        for (let i = 0; i < threadPosts.count; ++ i) {
            const postItem = threadPosts.itemAt(i)

            if (!postItem.isValid())
                return false
        }

        return true
    }

    function hasFullContent() {
        for (let i = 0; i < threadPosts.count; ++ i) {
            const postItem = threadPosts.itemAt(i)

            if (!postItem.hasContent())
                return false
        }

        return threadPosts.count > 0
    }

    function hasPartialContent() {
        for (let i = 0; i < threadPosts.count; ++ i) {
            const postItem = threadPosts.itemAt(i)

            if (postItem.hasContent())
                return true
        }

        return false
    }

    function joinPosts(text1, text2) {
        const joinStr = (/\s/.test(text1.slice(-1)) || /\s/.test(text2.charAt(0))) ? "" : " "
        const newText = text1 + joinStr + text2
        return newText
    }

    function cancel() {
        if (!hasPartialContent()) {
            page.closed()
            return
        }

        if (draftPosts.canSaveDraft()) {
            guiSettings.askDiscardSaveQuestion(
                    page,
                    qsTr("Do you want to discard your post or save it as draft?"),
                    () => page.closed(),
                    () => page.saveDraftPost())
        }
        else {
            guiSettings.askYesNoQuestion(
                    page,
                    qsTr("Do you want to to discard your post?<br>You cannot save more drafts."),
                    () => page.closed())
        }
    }

    function getPostCountText(postIndex, postCount) {
        return `${unicodeFonts.toCleanedHtml(threadPrefix)}${(postIndex + 1)}/${postCount}`
    }

    function editThreadPrefix() {
        let component = Qt.createComponent("EditThreadPrefix.qml")
        let dialog = component.createObject(page, { prefix: threadPrefix })

        dialog.onAccepted.connect(() => {
            threadPrefix = dialog.getPrefix()
            skywalker.getUserSettings().setThreadPrefix(threadPrefix)
            dialog.destroy()
        })

        dialog.onRejected.connect(() => dialog.destroy())
        dialog.open()
    }

    function getImagesToSend(postItem) {
        let images = []

        for (let i = 0; i < postItem.images.length; ++i) {
            if (postItem.imageHasMeme(i)) {
                if (!memeMaker.setOrigImage(postItem.images[i])) {
                    console.warn("Cannot load image:", postItem.images[i])
                    images.push(postItem.images[i])
                    continue
                }

                memeMaker.topText = postItem.memeTopTexts[i]
                memeMaker.bottomText = postItem.memeBottomTexts[i]
                images.push(memeMaker.memeImgSource)
                page.tmpImages.push(memeMaker.memeImgSource)
                memeMaker.releaseMemeOwnership()
            }
            else {
                images.push(postItem.images[i])
            }
        }

        return images
    }

    function sendSinglePost(postItem, parentUri, parentCid, rootUri, rootCid, postIndex, postCount) {
        const qUri = postItem.getQuoteUri()
        const qCid = postItem.getQuoteCid()
        const labels = postItem.getContentLabels()

        let postText = postItem.text

        if (threadAutoNumber && postCount > 1)
            postText += `\n${getPostCountText(postIndex, postCount)}`

        if (postItem.card) {
            postUtils.post(postText,
                           postItem.card,
                           parentUri, parentCid,
                           rootUri, rootCid,
                           qUri, qCid, labels, postItem.language)
        } else if (!postItem.gif.isNull()) {
            tenor.registerShare(postItem.gif)

            let gifCard = linkCardReader.makeLinkCard(
                    postItem.gif.getUrlForPosting(),
                    `${postItem.gif.description} (via Tenor)\nPosted from Skywalker ${guiSettings.skywalkerHandle}`,
                    qsTr("This GIF has been posted from Skywalker for Android. " +
                         "Get Skywalker from Google Play.") +
                         (`<br>Bluesky: ${guiSettings.skywalkerHandle}`),
                    postItem.gif.imageUrl)

            postUtils.post(postText, gifCard,
                           parentUri, parentCid,
                           rootUri, rootCid,
                           qUri, qCid, labels, postItem.language)
        } else if (Boolean(postItem.video)) {
            postUtils.checkVideoLimits(
                () => videoUtils.transcode(postItem.video, postItem.videoNewHeight,
                        postItem.videoStartMs, postItem.videoEndMs,
                        (transcodedVideo) => {
                            postUtils.postVideo(postText, transcodedVideo, postItem.videoAltText,
                            parentUri, parentCid,
                            rootUri, rootCid,
                            qUri, qCid, labels, postItem.language) },
                        (error) => postFailed(error)),
                (error) => postFailed(error))
        } else {
            const images = getImagesToSend(postItem)
            postUtils.post(postText, images, postItem.altTexts,
                           parentUri, parentCid,
                           rootUri, rootCid,
                           qUri, qCid, labels, postItem.language);
        }

        postUtils.cacheTags(postItem.text)
        languageUtils.addUsedPostLanguage(postItem.language)
    }

    function sendThreadPosts(postIndex, parentUri, parentCid, rootUri, rootCid) {
        if (postIndex >= threadPosts.postList.length) {
            console.debug("Done posting thread")
            postDone()
            return
        }

        console.debug(`Send thread post ${postIndex}`)
        sendingThreadPost = postIndex
        let postItem = threadPosts.postList[postIndex]
        sendSinglePost(postItem, parentUri, parentCid, rootUri, rootCid, postIndex, threadPosts.count)
    }

    function sendNextThreadPost(prevUri, prevCid) {
        if (sendingThreadPost === 0) {
            threadFirstPostUri = prevUri
            threadFirstPostCid = prevCid

            if (restrictReply && !threadGateCreated) {
                postUtils.addThreadgate(prevUri, prevCid, allowReplyMentioned, allowReplyFollowing,
                                        getReplyRestrictionListUris())
                return
            }

            if (replyRootPostUri) {
                threadRootUri = replyRootPostUri
                threadRootCid = replyRootPostCid
            }
            else if (replyToPostUri) {
                threadRootUri = replyToPostUri
                threadRootCid = replyToPostCid
            }
            else {
                threadRootUri = prevUri
                threadRootCid = prevCid
            }
        }

        sendThreadPosts(sendingThreadPost + 1, prevUri, prevCid, threadRootUri, threadRootCid)
    }

    function saveDraftPost() {
        threadPosts.copyPostItemsToPostList()
        const postItem = threadPosts.postList[0]
        const qUri = postItem.getQuoteUri()
        const qCid = postItem.getQuoteCid()
        const labels = postItem.getContentLabels()

        const draft = draftPosts.createDraft(postItem.text,
                                 postItem.images, postItem.altTexts,
                                 postItem.memeTopTexts, postItem.memeBottomTexts,
                                 postItem.video, postItem.videoAltText,
                                 postItem.videoStartMs, postItem.videoEndMs, postItem.videoNewHeight,
                                 replyToPostUri, replyToPostCid,
                                 replyRootPostUri, replyRootPostCid,
                                 replyToAuthor, unicodeFonts.toPlainText(replyToPostText),
                                 replyToPostDateTime,
                                 qUri, qCid, postItem.quoteAuthor, unicodeFonts.toPlainText(postItem.quoteText),
                                 postItem.quoteDateTime, postItem.quoteFixed,
                                 postItem.quoteFeed, postItem.quoteList,
                                 postItem.gif, postItem.card, labels, postItem.language,
                                 restrictReply, allowReplyMentioned, allowReplyFollowing,
                                 getReplyRestrictionListUris(), !allowQuoting)

        let draftItemList = []

        for (let i = 1; i < threadPosts.postList.length; ++i) {
            const threadItem = threadPosts.postList[i]
            const qUriItem = threadItem.getQuoteUri()
            const qCidItem = threadItem.getQuoteCid()
            const labelsItem = threadItem.getContentLabels()

            const draftItem = draftPosts.createDraft(threadItem.text,
                                     threadItem.images, threadItem.altTexts,
                                     threadItem.memeTopTexts, threadItem.memeBottomTexts,
                                     threadItem.video, threadItem.videoAltText,
                                     threadItem.videoStartMs, threadItem.videoEndMs, threadItem.videoNewHeight,
                                     "", "",
                                     "", "",
                                     nullAuthor, "",
                                     new Date(),
                                     qUriItem, qCidItem, threadItem.quoteAuthor, unicodeFonts.toPlainText(threadItem.quoteText),
                                     threadItem.quoteDateTime, threadItem.quoteFixed,
                                     threadItem.quoteFeed, threadItem.quoteList,
                                     threadItem.gif, threadItem.card, labelsItem, threadItem.language,
                                     false, false, false,
                                     [], false)

            draftItemList.push(draftItem)
            postUtils.cacheTags(threadItem.text)
            languageUtils.addUsedPostLanguage(threadItem.language)
        }

        draftPosts.saveDraftPost(draft, draftItemList)
        postUtils.cacheTags(postItem.text)
        languageUtils.addUsedPostLanguage(postItem.language)
    }

    function showDraftPosts() {
        let component = Qt.createComponent("DraftPostsView.qml")
        let draftsPage = component.createObject(page, { model: draftPosts.getDraftPostsModel() })
        draftsPage.onClosed.connect(() => root.popStack())
        draftsPage.onSelected.connect((index) => {
            const draftDataList = draftPosts.getDraftPostData(index)
            setDraftPost(draftDataList)
            draftPosts.removeDraftPost(index)
            root.popStack()
        })
        draftsPage.onDeleted.connect((index) => draftPosts.removeDraftPost(index))

        root.pushStack(draftsPage)
    }

    function addAnniversaryCard() {
        let component = Qt.createComponent("AnniversaryCardMaker.qml")
        let cardPage = component.createObject(page)
        cardPage.onCanceled.connect(() => root.popStack())
        cardPage.onAddCard.connect((source, years) => {
            page.photoPicked(source, "", qsTr(`Bluesky anniversary card sent with ${guiSettings.skywalkerHandle}`))
            page.addSharedText(qsTr(`Today is my ${years} year Bluesky anniversary 🥳`))
            root.popStack()
        })
        root.pushStack(cardPage)
    }

    function setDraftPost(draftDataList) {
        for (let j = 0; j < draftDataList.length; ++j) {
            const draftData = draftDataList[j]
            let postItem = threadPosts.newComposePostItem()
            postItem.text = draftData.text

            for (let i = 0; i < draftData.images.length; ++i) {
                postItem.images.push(draftData.images[i].fullSizeUrl)
                postItem.altTexts.push(draftData.images[i].alt)
                postItem.memeTopTexts.push(draftData.images[i].memeTopText)
                postItem.memeBottomTexts.push(draftData.images[i].memeBottomText)
            }

            if (!draftData.video.isNull())
            {
                postItem.video = draftData.video.playlistUrl
                postItem.videoAltText = draftData.video.alt
                postItem.videoStartMs = draftData.video.startMs
                postItem.videoEndMs = draftData.video.endMs
                postItem.videoNewHeight = draftData.video.newHeight
            }

            if (j === 0) {
                replyToAuthor = draftData.replyToAuthor
                replyToPostUri = draftData.replyToUri
                replyToPostCid = draftData.replyToCid
                replyRootPostUri = draftData.replyRootUri
                replyRootPostCid = draftData.replyRootCid
                replyToPostText = draftData.replyToText
                replyToPostDateTime = draftData.replyToDateTime

                openedAsQuotePost = draftData.openAsQuotePost

                restrictReply = draftData.restrictReplies
                allowReplyMentioned = draftData.allowMention
                allowReplyFollowing = draftData.allowFollowing
                allowListUrisFromDraft = draftData.allowLists
                allowListIndexes = [0, 1, 2]
                allowLists = [false, false, false]
                allowQuoting = !draftData.embeddingDisabled
            }

            postItem.quoteUri = draftData.quoteUri
            postItem.quoteCid = draftData.quoteCid
            postItem.quoteAuthor = draftData.quoteAuthor
            postItem.quoteText = draftData.quoteText
            postItem.quoteDateTime = draftData.quoteDateTime
            postItem.quoteFixed = draftData.quoteFixed
            postItem.quoteFeed = draftData.quoteFeed
            postItem.quoteList = draftData.quoteList

            postItem.gif = draftData.gif

            if (draftData.externalLink)
                linkCardReader.getLink(j, draftData.externalLink)

            postItem.setContentWarnings(draftData.labels)
            postItem.language = draftData.language

            console.debug("ADD DRAFT:", j)
            if (j > 0)
                threadPosts.postList.push(postItem)
            else
                threadPosts.postList[0] = postItem
            console.debug("ADDED DRAFT:", j)
        }

        threadPosts.model = draftDataList.length
        threadPosts.copyPostListToPostItems()
    }

    function addReplyRestrictions() {
        if (restrictionsListModelId < 0) {
            restrictionsListModelId = skywalker.createListListModel(QEnums.LIST_TYPE_ALL, QEnums.LIST_PURPOSE_CURATE, userDid)
            skywalker.getListList(restrictionsListModelId)
        }

        let component = Qt.createComponent("AddReplyRestrictions.qml")
        let restrictionsPage = component.createObject(page, {
                rootUri: "",
                postUri: "",
                restrictReply: page.restrictReply,
                allowMentioned: page.allowReplyMentioned,
                allowFollowing: page.allowReplyFollowing,
                allowLists: page.allowLists,
                allowListIndexes: page.allowListIndexes,
                allowListUrisFromDraft: page.allowListUrisFromDraft,
                listModelId: page.restrictionsListModelId,
                allowQuoting: page.allowQuoting
        })
        restrictionsPage.onAccepted.connect(() => {
                page.restrictReply = restrictionsPage.restrictReply
                page.allowReplyMentioned = restrictionsPage.allowMentioned
                page.allowReplyFollowing = restrictionsPage.allowFollowing
                page.allowLists = restrictionsPage.allowLists
                page.allowListIndexes = restrictionsPage.allowListIndexes
                page.allowQuoting = restrictionsPage.allowQuoting
                allowListUrisFromDraft = []
                restrictionsPage.destroy()
        })
        restrictionsPage.onRejected.connect(() => restrictionsPage.destroy())
        restrictionsPage.open()
    }

    function getReplyRestrictionListUris() {
        if (allowListUrisFromDraft.length > 0)
            return allowListUrisFromDraft

        return root.getReplyRestrictionListUris(restrictionsListModelId, allowLists, allowListIndexes)
    }

    function addContentWarning() {
        let postItem = currentPostItem()

        if (!postItem)
            return

        let component = Qt.createComponent("AddContentWarning.qml")
        let cwPage = component.createObject(page, {
                suggestive: postItem.cwSuggestive,
                nudity: postItem.cwNudity,
                porn: postItem.cwPorn,
                gore: postItem.cwGore
        })
        cwPage.onAccepted.connect(() => {
                postItem.cwSuggestive = cwPage.suggestive
                postItem.cwNudity = cwPage.nudity
                postItem.cwPorn = cwPage.porn
                postItem.cwGore = cwPage.gore
                cwPage.destroy()
        })
        cwPage.onRejected.connect(() => cwPage.destroy())
        cwPage.open()
    }

    function hasImageContent() {
        let postItem = currentPostItem()

        if (!postItem)
            return false

        return !postItem.getGifAttachment().gif.isNull() ||
                (postItem.getLinkCard().card && postItem.getLinkCard().card.thumb) ||
                postItem.images.length > 0 ||
                Boolean(postItem.video)
    }

    function canAddImage() {
        const postItem = currentPostItem()

        if (!postItem)
            return false

        return postItem.images.length < maxImages &&
                postItem.video.length === 0 &&
                threadPosts.postList[currentPostIndex].gif.isNull() &&
                !threadPosts.postList[currentPostIndex].card &&
                !pickingImage
    }

    function canAddVideo() {
        const postItem = currentPostItem()

        if (!postItem)
            return false

        return canAddImage() && postItem.images.length === 0
    }

    function canAddGif() {
        const postItem = currentPostItem()

        if (!postItem)
            return false

        return threadPosts.postList[currentPostIndex].gif.isNull() &&
                !threadPosts.postList[currentPostIndex].card &&
                postItem.images.length === 0 &&
                postItem.video.length === 0
    }

    function currentPostLanguage() {
        const postItem = currentPostItem()

        if (!postItem)
            return languageUtils.defaultPostLanguage

        return postItem.language ? postItem.language : languageUtils.defaultPostLanguage
    }

    function hasContentWarning() {
        const postItem = currentPostItem()

        if (!postItem)
            return false

        return hasImageContent() && (postItem.cwSuggestive || postItem.cwNudity || postItem.cwPorn || postItem.cwGore)
    }

    function editVideo(videoSource, startMs = 0, endMs = 0, newHeight = 0) {
        console.debug("Edit video, start:", startMs, "end:", endMs, "height:", newHeight)
        let component = Qt.createComponent("VideoEditor.qml")
        let videoPage = component.createObject(page, {
                videoSource: videoSource,
                startMs: startMs,
                endMs: endMs,
                newHeight: newHeight
        })
        videoPage.onVideoEdited.connect((newHeight, startMs, endMs) => {
            const postItem = currentPostItem()
            let altText = ""

            if (postItem) {
                postItem.videoNewHeight = newHeight
                postItem.videoStartMs = startMs
                postItem.videoEndMs = endMs
                altText = postItem.videoAltText
            }

            page.videoPicked(videoSource, altText)
            root.popStack()
            currentPostItem().getPostText().forceActiveFocus()
        })
        videoPage.onCancel.connect(() => {
            root.popStack()
            currentPostItem().getPostText().forceActiveFocus()
        })
        root.pushStack(videoPage)
    }

    function showVideoUploadLimits(limits) {
        let component = Qt.createComponent("VideoUploadLimits.qml")
        let limitsPage = component.createObject(page, { limits: limits })
        limitsPage.onAccepted.connect(() => limitsPage.destroy())
        limitsPage.open()
    }

    VirtualKeyboardPageResizer {
        id: virtualKeyboardPageResizer
    }

    Component.onDestruction: {
        for (let i = 0; i < threadPosts.count; ++i) {
            let postItem = threadPosts.itemAt(i)
            postItem.images.forEach((value, index, array) => { postUtils.dropPhoto(value); })

            if (Boolean(postItem.video))
                postUtils.dropVideo(postItem.video)
        }

        page.tmpImages.forEach((value, index, array) => { postUtils.dropPhoto(value); })
        page.tmpVideos.forEach((value, index, array) => { postUtils.dropVideo(value); })

        if (initialImage)
            getPostUtils().dropPhoto(initialImage)

        if (initialVideo)
            postUtils.dropVideo(initialVideo)

        if (restrictionsListModelId >= 0)
            skywalker.removeListListModel(restrictionsListModelId)

        draftPosts.removeDraftPostsModel()
    }

    Component.onCompleted: {
        // Save the full page height now. Later when the Android keyboard pops up,
        // the page height sometimes changes by itself, but not always...
        virtualKeyboardPageResizer.fullPageHeight = parent.height

        // Wait a bit for the window to render.
        // Then make sue the text field is in the visible area.
        focusTimer.start()

        threadPosts.copyPostListToPostItems()
        draftPosts.loadDraftPosts()
    }
}
