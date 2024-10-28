pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyListView {
    required property detailedprofile author
    required property var enclosingView
    required property var getFeed
    required property var getFeedNextPage
    required property var getEmptyListIndicationSvg
    required property var getEmptyListIndicationText
    required property var visibilityShowProfileLink
    required property var disableWarning
    property int modelId: -1
    property int feedFilter: QEnums.AUTHOR_FEED_FILTER_POSTS

    id: authorPostsList
    width: parent.width
    height: parent.height
    model: modelId >= 0 ? SkyRoot.skywalker().getAuthorFeedModel(modelId) : null
    interactive: !enclosingView.interactive

    StackLayout.onIsCurrentItemChanged: {
        if (!StackLayout.isCurrentItem)
            cover()

        if (StackLayout.isCurrentItem && modelId < 0 && !SkyRoot.skywalker().getAuthorFeedInProgress) {
            modelId = SkyRoot.skywalker().createAuthorFeedModel(author, feedFilter)
            model = SkyRoot.skywalker().getAuthorFeedModel(modelId)
            getFeed(modelId)
        }
    }

    onVerticalOvershootChanged: {
        if (verticalOvershoot < 0)
            enclosingView.interactive = true
    }

    delegate: PostFeedViewDelegate {
        width: authorPostsList.enclosingView.width
    }

    FlickableRefresher {
        inProgress: SkyRoot.skywalker().getAuthorFeedInProgress
        topOvershootFun: () => {
            if (authorPostsList.modelId >= 0)
                authorPostsList.getFeed(authorPostsList.modelId)
        }
        bottomOvershootFun: () => {
            if (authorPostsList.modelId >= 0)
                authorPostsList.getFeedNextPage(authorPostsList.modelId)
        }
        topText: qsTr("Pull down to refresh")
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: SkyRoot.skywalker().getAuthorFeedInProgress
    }

    EmptyListIndication {
        id: noPostIndication
        svg: authorPostsList.getEmptyListIndicationSvg()
        text: authorPostsList.getEmptyListIndicationText()
        list: authorPostsList
        onLinkActivated: (link) => SkyRoot.root.viewListByUri(link, false)
    }
    Text {
        anchors.top: noPostIndication.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        elide: Text.ElideRight
        textFormat: Text.RichText
        text: `<br><a href=\"show\" style=\"color: ${guiSettings.linkColor}\">` + qsTr("Show profile") + "</a>"
        visible: authorPostsList.visibilityShowProfileLink(authorPostsList)
        onLinkActivated: authorPostsList.disableWarning()
    }

    Timer {
        readonly property int maxRetry: 1
        property int retryAttempts: maxRetry

        id: retryGetFeedTimer
        interval: 500
        onTriggered: {
            if (authorPostsList.modelId >= 0) {
                console.debug("RETRY GET FEED:", authorPostsList.modelId)
                authorPostsList.getFeed(authorPostsList.modelId)
            }
            else {
                console.debug("NO MODEL")
                resetRetryAttempts()
            }
        }

        function retry() {
            if (retryAttempts <= 0) {
                resetRetryAttempts()
                return false
            }

            --retryAttempts
            start()
            return true
        }

        function resetRetryAttempts() {
            console.debug("RESET RETRY ATTEMPTS")
            retryAttempts = maxRetry
        }
    }

    GuiSettings {
        id: guiSettings
    }

    function feedOk() {
        retryGetFeedTimer.resetRetryAttempts()
    }

    function retryGetFeed() {
        return retryGetFeedTimer.retry()
    }

    function refresh() {
        if (modelId >= 0)
            getFeed(modelId)
    }

    function clear() {
        if (modelId >= 0)
            SkyRoot.skywalker().clearAuthorFeed(modelId)
    }

    function removeModel() {
        if (modelId >= 0) {
            const id = modelId
            modelId = -1
            SkyRoot.skywalker().removeAuthorFeedModel(id)
        }
    }

    Component.onDestruction: {
        removeModel()
    }
}
