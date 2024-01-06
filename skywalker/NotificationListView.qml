import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

ListView {
    required property var skywalker
    required property var timeline

    signal closed

    id: notificationListView
    spacing: 0
    model: skywalker.notificationListModel
    flickDeceleration: guiSettings.flickDeceleration
    ScrollIndicator.vertical: ScrollIndicator {}

    header: SimpleHeader {
        text: qsTr("Notifications")
        onBack: notificationListView.closed()
    }
    headerPositioning: ListView.OverlayHeader

    footer: SkyFooter {
        timeline: notificationListView.timeline
        skywalker: notificationListView.skywalker
        notificationsActive: true
        onHomeClicked: root.viewTimeline()
        onNotificationsClicked: positionViewAtBeginning()
        onSearchClicked: root.viewSearchView()
        onFeedsClicked: root.viewFeedsView()
    }
    footerPositioning: ListView.OverlayFooter

    delegate: NotificationViewDelegate {
        viewWidth: notificationListView.width
    }

    FlickableRefresher {
        inProgress: skywalker.getNotificationsInProgress
        verticalOvershoot: notificationListView.verticalOvershoot
        topOvershootFun: () => skywalker.getNotifications(25, true)
        bottomOvershootFun: () => skywalker.getNotificationsNextPage()
        topText: qsTr("Pull down to refresh notifications")
    }

    EmptyListIndication {
        y: parent.headerItem ? parent.headerItem.height : 0
        svg: svgOutline.noPosts
        text: qsTr("No notifications")
        list: notificationListView
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: skywalker.getNotificationsInProgress
    }

    GuiSettings {
        id: guiSettings
    }
}
