pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import skywalker

SkyListView {
    required property var skywalker
    required property int modelId
    property bool showAsHome: false
    property int unreadPosts: 0

    signal closed

    id: postFeedView
    model: skywalker.getPostFeedModel(modelId)

    Accessible.name: postFeedView.model.feedName

    header: PostFeedHeader {
        skywalker: postFeedView.skywalker
        feedName: postFeedView.model.feedName
        feedAvatar: guiSettings.contentVisible(postFeedView.model.getGeneratorView()) ? postFeedView.model.getGeneratorView().avatarThumb : ""
        showAsHome: postFeedView.showAsHome
        showLanguageFilter: postFeedView.model.languageFilterConfigured
        filteredLanguages: postFeedView.model.filteredLanguages
        showPostWithMissingLanguage: postFeedView.model.showPostWithMissingLanguage

        onClosed: postFeedView.closed()
        onFeedAvatarClicked: skywalker.getFeedGenerator(postFeedView.model.getGeneratorView().uri)
    }
    headerPositioning: ListView.OverlayHeader

    footer: SkyFooter {
        visible: postFeedView.showAsHome
        timeline: postFeedView
        skywalker: postFeedView.skywalker
        homeActive: true
        showHomeFeedBadge: true
        onHomeClicked: postFeedView.positionViewAtBeginning()
        onNotificationsClicked: SkyRoot.root.viewNotifications()
        onSearchClicked: SkyRoot.root.viewSearchView()
        onFeedsClicked: SkyRoot.root.viewFeedsView()
        onMessagesClicked: SkyRoot.root.viewChat()
    }
    footerPositioning: ListView.OverlayFooter

    delegate: PostFeedViewDelegate {
        width: postFeedView.width
    }

    FlickableRefresher {
        inProgress: SkyRoot.skywalker().getFeedInProgress
        verticalOvershoot: postFeedView.verticalOvershoot
        topOvershootFun: () => SkyRoot.skywalker().getFeed(postFeedView.modelId)
        bottomOvershootFun: () => SkyRoot.skywalker().getFeedNextPage(postFeedView.modelId)
        topText: qsTr("Pull down to refresh feed")
        enableScrollToTop: !postFeedView.showAsHome
    }

    EmptyListIndication {
        y: parent.headerItem ? parent.headerItem.height : 0
        svg: SvgOutline.noPosts
        text: qsTr("Feed is empty")
        list: postFeedView
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: SkyRoot.skywalker().getFeedInProgress
    }

    GuiSettings {
        id: guiSettings
    }

    function forceDestroy() {
        if (modelId !== -1) {
            postFeedView.model = null
            skywalker.removePostFeedModel(modelId)
            modelId = -1
            destroy()
        }
    }

    Component.onDestruction: {
        if (modelId !== -1)
            skywalker.removePostFeedModel(modelId)
    }
}
