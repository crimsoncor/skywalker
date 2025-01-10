import QtQuick
import QtQuick.Controls
import skywalker

SkyPage {
    required property var chat
    required property convoview convo
    property bool isSending: false
    property int maxInputTextHeight
    readonly property int maxMessageLength: 1000
    readonly property int margin: 10
    property var skywalker: root.getSkywalker()
    property int textInputToolbarHeight: (keyboardHandler.keyboardVisible || !guiSettings.isAndroid) ? 24 : 0
    property int quotedContentHeight: quoteColumn.visible ? quoteColumn.height : 0
    property int lastIndex: -1

    signal closed

    id: page

    header: MessagesListHeader {
        convo: page.convo
        onBack: page.closed()
    }

    // Needed for SkyFormattedTextEdit
    footer: Rectangle {
        height: 0
        color: "transparent"
    }

    onHeightChanged: {
        // When the Android keyboard is visible the height sometimes shrinks to
        // the size of the visible window. I don't why that happens. Would be nice
        // if could do so from the start. But shrinking the height on the keyboard event
        // cause the whole screen to move up into the void????
        page.header.y = 0
    }

    SkyListView {
        id: messagesView
        width: parent.width
        height: parent.height - y - flick.height - newMessageText.padding - newMessageText.bottomPadding - keyboardHandler.keyboardHeight
        model: chat.getMessageListModel(convo.id)
        boundsMovement: Flickable.StopAtBounds
        clip: true

        onHeightChanged: moveToEnd()

        delegate: MessageViewDelegate {
            required property int index

            viewWidth: messagesView.width
            convo: page.convo
            onDeleteMessage: (messageId) => page.deleteMessage(messageId)
            onReportMessage: (msg) => page.reportDirectMessage(msg)
            onOpeningEmbed: page.lastIndex = index
        }

        FlickableRefresher {
            inProgress: chat.getMessagesInProgress
            topOvershootFun: () => chat.getMessagesNextPage(convo.id)
        }

        EmptyListIndication {
            y: parent.headerItem ? parent.headerItem.height : 0
            svg: SvgOutline.noDirectMessages
            text: qsTr("None")
            list: messagesView
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: chat.getMessagesInProgress
        }

        function moveToEnd() {
            positionViewAtEnd()

            // positionViewAtEnd not always gets completely to the end...
            // This seems to fix it...
            contentY = Math.max(originY, originY + contentHeight - height)
        }
    }

    Flickable {
        property bool contentYUpdating: false

        id: flick
        width: parent.width
        height: Math.min(newMessageText.height - newMessageText.padding - newMessageText.bottomPadding, maxInputTextHeight)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: newMessageText.bottomPadding + keyboardHandler.keyboardHeight
        clip: true
        contentWidth: parent.width
        contentHeight: newMessageText.contentHeight + page.margin
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        onHeightChanged: newMessageText.ensureVisible(newMessageText.cursorRectangle)

        onContentYChanged: {
            if (contentYUpdating)
                return

            contentYUpdating = true
            newMessageText.ensureVisible(newMessageText.cursorRectangle)
            contentYUpdating = false
        }

        // After dragging the cursor may have moved outside the visible flick area.
        onDragEnded: newMessageText.resetCursorPosition()

        // HACK: to keep margin between the top of the Android keyboard and the bottom
        // of the text input we add extra padding.
        SkyFormattedTextEdit {
            property basicprofile quoteAuthor
            property string quoteUri: ""
            property string quoteCid: ""
            property string quoteText
            property date quoteDateTime
            property bool quoteFixed: false
            property generatorview nullFeed
            property generatorview quoteFeed

            id: newMessageText
            x: page.margin
            width: parent.width - sendButton.width - 3 * page.margin
            padding: page.margin
            bottomPadding: 2 * page.margin + textInputToolbarHeight + quotedContentHeight
            parentPage: page
            parentFlick: flick
            color: guiSettings.messageNewTextColor
            placeholderText: qsTr("Say something nice")
            maxLength: page.maxMessageLength
            enableLinkShortening: false
            fontSelectorCombo: fontSelector

            onFirstPostLinkChanged: {
                if (quoteFixed)
                    return

                quoteUri = ""
                quoteFeed = nullFeed

                if (firstPostLink)
                    postUtils.getQuotePost(firstPostLink)
            }

            onCursorInFirstPostLinkChanged: {
                if (!cursorInFirstPostLink && quoteUri)
                    fixQuoteLink(true)
            }

            onFirstFeedLinkChanged: {
                quoteFeed = nullFeed

                if (firstPostLink)
                    return

                if (firstFeedLink)
                    postUtils.getQuoteFeed(firstFeedLink)
            }

            function getQuoteUri() {
                if (quoteUri)
                    return quoteUri

                return quoteFeed.uri
            }

            function getQuoteCid() {
                if (quoteCid)
                    return quoteCid

                return quoteFeed.cid
            }

            function fixQuoteLink(fix) {
                quoteFixed = fix

                if (!fix)
                    quoteUri = ""
            }

            function reset() {
                clear()
                fixQuoteLink(false)
            }
        }
    }

    SvgTransparentButton {
        id: sendButton
        anchors.right: parent.right
        anchors.rightMargin: page.margin
        y: flick.y + flick.height + 5
        svg: SvgFilled.send
        accessibleName: qsTr("send message")
        enabled: !page.isSending && newMessageText.graphemeLength > 0 && newMessageText.graphemeLength <= page.maxMessageLength
        onClicked: sendMessage()
    }

    Rectangle {
        x: page.margin
        y: flick.y - newMessageText.padding
        z: -1
        width: newMessageText.width
        height: flick.height + newMessageText.bottomPadding
        radius: 10
        color: guiSettings.messageNewBackgroundColor
        border.width: newMessageText.activeFocus ? 1 : 0
        border.color: guiSettings.buttonColor

        // Quote post
        Rectangle {
            radius: 10
            anchors.fill: quoteColumn
            border.width: 1
            border.color: guiSettings.borderHighLightColor
            color: guiSettings.postHighLightColor
            visible: quoteColumn.visible
        }
        QuotePost {
            id: quoteColumn
            x: page.margin
            width: parent.width - 2 * page.margin
            anchors.bottom: fontSelector.visible ? fontSelector.top : parent.bottom
            author: newMessageText.quoteAuthor
            postText: newMessageText.quoteText
            postDateTime: newMessageText.quoteDateTime
            ellipsisBackgroundColor: guiSettings.postHighLightColor
            showCloseButton: newMessageText.quoteFixed
            visible: newMessageText.quoteUri

            onCloseClicked: {
                newMessageText.fixQuoteLink(false)
                newMessageText.forceActiveFocus()
            }
        }

        // Quote feed
        Rectangle {
            radius: 10
            anchors.fill: quoteFeedColumn
            border.width: 1
            border.color: guiSettings.borderHighLightColor
            color: guiSettings.postHighLightColor
            visible: quoteFeedColumn.visible
        }
        QuoteFeed {
            id: quoteFeedColumn
            x: page.margin
            width: parent.width - 2 * page.margin
            anchors.bottom: fontSelector.visible ? fontSelector.top : parent.bottom
            feed: newMessageText.quoteFeed
            visible: !newMessageText.quoteFeed.isNull()
        }

        FontComboBox {
            id: fontSelector
            x: page.margin
            anchors.bottomMargin: 5
            anchors.bottom: parent.bottom
            popup.height: page.height - (page.header.y + page.header.height)
            focusPolicy: Qt.NoFocus
            visible: textInputToolbarHeight > 0
        }

        TextLengthCounter {
            anchors.rightMargin: page.margin
            anchors.right: parent.right
            anchors.bottomMargin: 5
            anchors.bottom: parent.bottom
            textField: newMessageText
            visible: textInputToolbarHeight > 0
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: false
    }

    PostUtils {
        id: postUtils
        skywalker: page.skywalker // qmllint disable missing-type

        onQuotePost: (uri, cid, text, author, timestamp) => { // qmllint disable signal-handler-parameters
            if (!newMessageText.firstPostLink)
                return

            newMessageText.quoteFeed = newMessageText.nullFeed
            newMessageText.quoteUri = uri
            newMessageText.quoteCid = cid
            newMessageText.quoteText = text
            newMessageText.quoteAuthor = author
            newMessageText.quoteDateTime = timestamp

            if (!newMessageText.cursorInFirstPostLink)
                newMessageText.fixQuoteLink(true)
            else
                newMessageText.cutLinkIfJustAdded(newMessageText.firstPostLink, () => newMessageText.fixQuoteLink(true))
        }

        // Embedded feeds are not supported
        // onQuoteFeed: (feed) => {
        //     if (!newMessageText.firstFeedLink)
        //         return

        //     if (newMessageText.firstPostLink)
        //         return

        //     newMessageText.quoteFeed = feed
        // }
    }


    // This was needed in Qt 6.6.3
    // Connections {
    //     target: Qt.inputMethod

    //     function onKeyboardRectangleChanged() {
    //         const keyboardY = Qt.inputMethod.keyboardRectangle.y  / Screen.devicePixelRatio

    //         // NOTE: This function seems to be called many times when the keyboard
    //         // pops up, with increasing Y values. The first Y value seems to be the
    //         // position of the top of the keyboard, not sure where the others calls
    //         // come from.
    //         if (keyboardY > 0) {
    //             if (!keyboardVisible) {
    //                 const keyboardHeight = page.height - keyboardY

    //                 // Shrink empty space between message list and text input. The
    //                 // text input shifted up to make place for the keyboard.
    //                 messagesView.y = Math.min(keyboardHeight, Math.max(messagesView.height - messagesView.contentHeight, 0))

    //                 // Qt seems to scroll the whole window up!. Pull the header
    //                 // down to make it visible
    //                 header.y = keyboardHeight

    //                 newMessageText.ensureVisible(newMessageText.cursorRectangle)
    //                 keyboardVisible = true
    //             }
    //         }
    //         else {
    //             messagesView.y = 0
    //             header.y = 0
    //             keyboardVisible = false
    //         }
    //     }
    // }

    // This works since Qt 6.7.3
    // Seems not to work on every phone. Replaced this with adding keyboard height
    // to the bottom margin of flick.
    // VirtualKeyboardPageResizer {
    //     id: virtualKeyboardPageResizer
    // }

    VirtualKeyboardHandler {
        id: keyboardHandler
    }

    function addMessage(msgText) {
        Qt.inputMethod.commit() // qmllint disable missing-property
        newMessageText.insert(newMessageText.length, msgText)
        newMessageText.cursorPosition = newMessageText.length
        newMessageText.forceActiveFocus()
    }

    function sendMessage() {
        Qt.inputMethod.commit() // qmllint disable missing-property
        isSending = true
        const qUri = newMessageText.getQuoteUri()
        const qCid = newMessageText.getQuoteCid()
        let msgText = newMessageText.text
        console.debug("Send message:", convo.id, msgText)
        chat.sendMessage(convo.id, msgText, qUri, qCid)
    }

    function deleteMessage(messageId) {
        guiSettings.askYesNoQuestion(page,
            qsTr("Do you want to delete the message? The message will be deleted for you, the other participant will still see it."),
            () => chat.deleteMessage(convo.id, messageId))
    }

    function reportDirectMessage(msg) {
        root.reportDirectMessage(msg, convo.id, convo.getMember(msg.senderDid).basicProfile)
    }

    function sendMessageOkHandler() {
        isSending = false
        busyIndicator.running = false
        newMessageText.reset()
        chat.updateMessages(convo.id)
    }

    function sendMessageFailedHandler(error) {
        skywalker.showStatusMessage(error, QEnums.STATUS_LEVEL_ERROR)
        isSending = false
        busyIndicator.running = false
    }

    function sendMessageProgressHandler() {
        busyIndicator.running = true
    }

    function deleteMessageOkHandler() {
        skywalker.showStatusMessage(qsTr("Message deleted"), QEnums.STATUS_LEVEL_INFO)
        chat.getMessages(convo.id)
    }

    function deleteMessageFailedHandler(error) {
        skywalker.showStatusMessage(error, QEnums.STATUS_LEVEL_ERROR)
    }

    function getMessagesOkHandler(cursor) {
        if (!cursor)
            messagesView.moveToEnd()
    }

    function getMessagesFailedHandler(error) {
        skywalker.showStatusMessage(error, QEnums.STATUS_LEVEL_ERROR)
    }

    function doMoveToMessage(index) {
        const firstVisibleIndex = messagesView.getFirstVisibleIndex()
        const lastVisibleIndex = messagesView.getLastVisibleIndex()
        console.debug("Move to:", index, "first:", firstVisibleIndex, "last:", lastVisibleIndex, "count:", messagesView.count)
        messagesView.positionViewAtIndex(Math.max(index, 0), ListView.End)

        return (lastVisibleIndex >= index - 1 && lastVisibleIndex <= index + 1)
    }

    function moveToMessage(index) {
        const destination = index >= 0 ? index : messagesView.count - 1
        messagesView.moveToIndex(destination, doMoveToMessage)
    }

    function rowsInsertedHandler(parent, start, end) {
        if (end === messagesView.count - 1)
            moveToMessage(-1)
    }

    function initHandlers() {
        messagesView.model.onRowsInserted.connect(rowsInsertedHandler)

        chat.onSendMessageOk.connect(sendMessageOkHandler)
        chat.onSendMessageFailed.connect(sendMessageFailedHandler)
        chat.onSendMessageProgress.connect(sendMessageProgressHandler)
        chat.onDeleteMessageOk.connect(deleteMessageOkHandler)
        chat.onDeleteMessageFailed.connect(deleteMessageFailedHandler)
        chat.onGetMessagesOk.connect(getMessagesOkHandler)
        chat.onGetMessagesFailed.connect(getMessagesFailedHandler)
    }

    function destroyHandlers() {
        messagesView.model.onRowsInserted.disconnect(rowsInsertedHandler)

        chat.onSendMessageOk.disconnect(sendMessageOkHandler)
        chat.onSendMessageFailed.disconnect(sendMessageFailedHandler)
        chat.onSendMessageProgress.disconnect(sendMessageProgressHandler)
        chat.onDeleteMessageOk.disconnect(deleteMessageOkHandler)
        chat.onDeleteMessageFailed.disconnect(deleteMessageFailedHandler)
        chat.onGetMessagesOk.disconnect(getMessagesOkHandler)
        chat.onGetMessagesFailed.disconnect(getMessagesFailedHandler)

        chat.removeMessageListModel(convo.id)
    }

    Component.onDestruction: {
        chat.updateRead(convo.id)
        destroyHandlers()
    }

    Component.onCompleted: {
        const inputTextHeight = newMessageText.height - newMessageText.padding - newMessageText.bottomPadding
        maxInputTextHeight = 5 * inputTextHeight
        moveToMessage(-1)
        initHandlers()
        sendButton.forceActiveFocus()
    }
}
