import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyListView {
    required property var skywalker
    required property int modelId
    property bool showAsHome: false
    property int unreadPosts: 0

    signal closed

    id: postListFeedView
    model: skywalker.getPostFeedModel(modelId)

    Accessible.name: postListFeedView.model.feedName

    header: PostFeedHeader {
        skywalker: postListFeedView.skywalker
        feedName: postListFeedView.model.feedName
        defaultSvg: SvgFilled.list
        feedAvatar: postListFeedView.model.getListView().avatarThumb
        showAsHome: postListFeedView.showAsHome
        showLanguageFilter: postListFeedView.model.languageFilterConfigured
        filteredLanguages: postListFeedView.model.filteredLanguages
        showPostWithMissingLanguage: postListFeedView.model.showPostWithMissingLanguage

        onClosed: postListFeedView.closed()
        onFeedAvatarClicked: {
            let list = postListFeedView.model.getListView()
            root.viewListByUri(list.uri, false)
        }
    }
    headerPositioning: ListView.OverlayHeader

    footer: SkyFooter {
        visible: showAsHome
        timeline: postListFeedView
        skywalker: postListFeedView.skywalker
        homeActive: true
        showHomeFeedBadge: true
        onHomeClicked: postListFeedView.positionViewAtBeginning()
        onNotificationsClicked: root.viewNotifications()
        onSearchClicked: root.viewSearchView()
        onFeedsClicked: root.viewFeedsView()
        onMessagesClicked: root.viewChat()
    }
    footerPositioning: ListView.OverlayFooter

    delegate: PostFeedViewDelegate {
        width: postListFeedView.width
    }

    FlickableRefresher {
        inProgress: skywalker.getFeedInProgress
        topOvershootFun: () => skywalker.getListFeed(modelId)
        bottomOvershootFun: () => skywalker.getListFeedNextPage(modelId)
        topText: qsTr("Pull down to refresh feed")
        enableScrollToTop: !showAsHome
    }

    EmptyListIndication {
        y: parent.headerItem ? parent.headerItem.height : 0
        svg: SvgOutline.noPosts
        text: qsTr("Feed is empty")
        list: postListFeedView
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: skywalker.getFeedInProgress
    }

    GuiSettings {
        id: guiSettings
    }

    function forceDestroy() {
        if (modelId !== -1) {
            postListFeedView.model = null
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
