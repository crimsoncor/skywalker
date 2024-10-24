import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

ListView {
    required property string title
    required property var skywalker
    required property int modelId
    property string description
    property bool showFollow: true
    property bool allowDeleteItem: false
    property string listUri // set when the author list is a list of members from listUri
    property int prevModelId: -1

    signal closed

    id: authorListView
    spacing: 0
    clip: true
    model: skywalker.getAuthorListModel(modelId)
    flickDeceleration: guiSettings.flickDeceleration
    maximumFlickVelocity: guiSettings.maxFlickVelocity
    pixelAligned: guiSettings.flickPixelAligned
    ScrollIndicator.vertical: ScrollIndicator {}

    Accessible.role: Accessible.List

    header: SimpleDescriptionHeader {
        title: authorListView.title
        description: authorListView.description
        visible: authorListView.title
        onClosed: authorListView.closed()

        Component.onCompleted: {
            if (!visible)
                height = 0
        }
    }
    headerPositioning: ListView.OverlayHeader

    delegate: AuthorViewDelegate {
        required property int index

        width: authorListView.width
        showFollow: authorListView.showFollow
        allowDeleteItem: authorListView.allowDeleteItem

        onFollow: (profile) => { graphUtils.follow(profile) }
        onUnfollow: (did, uri) => { graphUtils.unfollow(did, uri) }
        onDeleteItem: (listItemUri) => authorListView.deleteListItem(listItemUri, index)
    }

    onModelIdChanged: {
        if (prevModelId > -1) {
            console.debug("Delete previous model:", prevModelId)
            skywalker.removeAuthorListModel(prevModelId)
            prevModelId = modelId
            refresh()
        }
    }

    FlickableRefresher {
        inProgress: skywalker.getAuthorListInProgress
        topOvershootFun: () => refresh()
        bottomOvershootFun: () => skywalker.getAuthorListNextPage(modelId)
        topText: qsTr("Refresh")
    }

    EmptyListIndication {
        y: parent.headerItem ? parent.headerItem.height : 0
        svg: SvgOutline.noDirectMessages
        text: qsTr("None")
        list: authorListView
    }

    GraphUtils {
        id: graphUtils
        skywalker: authorListView.skywalker

        onFollowFailed: (error) => { statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR) }
        onUnfollowFailed: (error) => { statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR) }
        onRemoveListUserFailed: (error) => {
            statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR)
            refresh()
        }
    }

    BusyIndicator {
        id: busyBottomIndicator
        anchors.centerIn: parent
        running: skywalker.getAuthorListInProgress
    }

    GuiSettings {
        id: guiSettings
    }

    function deleteListItem(listItemUri, index) {
        model.deleteEntry(index)
        graphUtils.removeListUser(listUri, listItemUri)
    }

    function refresh() {
        skywalker.getAuthorList(modelId)
    }

    Component.onDestruction: {
        skywalker.removeAuthorListModel(modelId)
    }

    Component.onCompleted: {
        prevModelId = modelId
    }
}
