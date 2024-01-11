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

    signal closed

    id: authorListView
    spacing: 0
    model: skywalker.getAuthorListModel(modelId)
    flickDeceleration: guiSettings.flickDeceleration
    ScrollIndicator.vertical: ScrollIndicator {}

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

        viewWidth: authorListView.width
        showFollow: authorListView.showFollow
        onFollow: (profile) => { graphUtils.follow(profile) }
        onUnfollow: (did, uri) => { graphUtils.unfollow(did, uri) }
        onDeleteItem: (listItemUri) => authorListView.deleteListItem(listItemUri, index)
    }

    FlickableRefresher {
        inProgress: skywalker.getAuthorListInProgress
        verticalOvershoot: authorListView.verticalOvershoot
        topOvershootFun: () => skywalker.getAuthorList(modelId)
        bottomOvershootFun: () => skywalker.getAuthorListNextPage(modelId)
        topText: "Refresh"
    }

    EmptyListIndication {
        y: parent.headerItem ? parent.headerItem.height : 0
        svg: svgOutline.noUsers
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
            skywalker.getAuthorList(modelId)
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
        graphUtils.removeListUser(listItemUri)
    }

    Component.onDestruction: {
        skywalker.removeAuthorListModel(modelId)
    }
}
