import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyListView {
    required property var skywalker
    property bool inSync: false
    property int unreadPosts: 0
    property var anchorItem // item used to calibrate list position on insert of new posts
    property int calibrationDy: 0

    id: timelineView
    model: skywalker.timelineModel

    Accessible.name: qsTr("Following")

    header: PostFeedHeader {
        skywalker: timelineView.skywalker
        feedName: qsTr("Following")
        showAsHome: true
        isHomeFeed: true
    }
    headerPositioning: ListView.OverlayHeader

    footer: SkyFooter {
        timeline: timelineView
        skywalker: timelineView.skywalker
        homeActive: true
        onHomeClicked: moveToPost(0)
        onNotificationsClicked: root.viewNotifications()
        onSearchClicked: root.viewSearchView()
        onFeedsClicked: root.viewFeedsView()
        onMessagesClicked: root.viewChat()
    }
    footerPositioning: ListView.OverlayFooter

    delegate: PostFeedViewDelegate {
        width: timelineView.width

        onCalibratedPosition: (dy) => {
            calibrationDy += dy
            calibratePosition()
        }
    }

    onCountChanged: {
        if (!inSync)
            return

        let firstVisibleIndex = getFirstVisibleIndex()
        let lastVisibleIndex = getLastVisibleIndex()
        // Adding/removing content changes the indices.
        skywalker.timelineMovementEnded(firstVisibleIndex, lastVisibleIndex)
        updateUnreadPosts(firstVisibleIndex)
    }

    onMovementEnded: {
        if (!inSync)
            return

        let firstVisibleIndex = getFirstVisibleIndex()
        let lastVisibleIndex = getLastVisibleIndex()
        skywalker.timelineMovementEnded(firstVisibleIndex, lastVisibleIndex)
        setAnchorItem(lastVisibleIndex + 1)
        updateUnreadPosts(firstVisibleIndex)
    }

    FlickableRefresher {
        inProgress: skywalker.getTimelineInProgress
        topOvershootFun: () => skywalker.getTimeline(50)
        bottomOvershootFun: () => skywalker.getTimelineNextPage()
        scrollToTopFun: () => moveToPost(0)
        enabled: timelineView.inSync
        topText: qsTr("Pull down to refresh timeline")
        enableScrollToTop: false
    }

    EmptyListIndication {
        y: parent.headerItem ? parent.headerItem.height : 0
        svg: svgOutline.noPosts
        text: qsTr("No posts, follow more people")
        list: timelineView
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: skywalker.getTimelineInProgress && !skywalker.autoUpdateTimelineInProgress
        Accessible.role: Accessible.ProgressBar
    }

    GuiSettings {
        id: guiSettings
    }

    function getFirstVisibleIndex() {
        let firstVisibleIndex = indexAt(0, contentY + headerItem.height)

        if (firstVisibleIndex < 0 && count > 0)
            return 0

        return firstVisibleIndex
    }

    function getLastVisibleIndex() {
        let lastVisibleIndex = indexAt(0, contentY + height - 1)

        if (lastVisibleIndex < 0 && count > 0)
            return count

        return lastVisibleIndex
    }

    function calibratePosition() {
        timelineView.contentY += calibrationDy
        calibrationDy = 0
        calibrateUnreadPosts()
    }

    function updateUnreadPosts(firstIndex) {
        timelineView.unreadPosts = Math.max(firstIndex, 0)
    }

    function setAnchorItem(index) {
        if (anchorItem)
            anchorItem.isAnchorItem = false

        if (index < 0)
            anchorItem = null
        else
            anchorItem = itemAtIndex(index)

        if (anchorItem)
            anchorItem.isAnchorItem = true
    }

    function moveToPost(index) {
        positionViewAtIndex(Math.max(index, 0), ListView.Beginning)
        const last = getLastVisibleIndex()
        setAnchorItem(last + 1)
        updateUnreadPosts(index)
    }

    function calibrateUnreadPosts() {
        const firstVisibleIndex = getFirstVisibleIndex()
        updateUnreadPosts(firstVisibleIndex)
    }

    function rowsInsertedHandler(parent, start, end) {
        calibrateUnreadPosts()
    }

    function rowsAboutToBeInsertedHandler(parent, start, end) {
        const index = getLastVisibleIndex()
        setAnchorItem(index + 1)
    }

    function setInSync(index) {
        moveToPost(index)
        inSync = true
        model.onRowsInserted.connect(rowsInsertedHandler)
        model.onRowsAboutToBeInserted.connect(rowsAboutToBeInsertedHandler)
    }

    function stopSync() {
        inSync = false
        model.onRowsInserted.disconnect(rowsInsertedHandler)
        model.onRowsAboutToBeInserted.disconnect(rowsAboutToBeInsertedHandler)
    }
}
