import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

Page {
    required property var skywalker
    required property detailedprofile author
    required property int modelId

    property int margin: 8
    property bool inTopOvershoot: false
    property bool inBottomOvershoot: false
    property string following: author.viewer.following

    signal closed

    id: page

    header: Rectangle {
        Image {
            id: bannerImg
            anchors.top: parent.top
            width: parent.width
            source: author.banner
            fillMode: Image.PreserveAspectFit
            visible: author.banner && !author.viewer.blockedBy && status === Image.Ready
        }

        Rectangle {
            id: noBanner
            anchors.top: parent.top
            width: parent.width
            height: width / 3
            color: "blue"
            visible: !bannerImg.visible
        }

        SvgButton {
            anchors.top: parent.top
            anchors.left: parent.left
            iconColor: "white"
            Material.background: "black"
            opacity: 0.5
            svg: svgOutline.arrowBack
            onClicked: page.closed()
        }

        Rectangle {
            id: avatar
            x: parent.width - width - 10
            y: (bannerImg.visible ? bannerImg.y + bannerImg.height : noBanner.y + noBanner.height) - height / 2
            width: 104
            height: width
            radius: width / 2
            color: "white"

            Avatar {
                anchors.centerIn: parent
                width: parent.width - 4
                height: parent.height - 4
                avatarUrl: author.viewer.blockedBy ? "" : author.avatarUrl
                onClicked: root.viewFullImage([author.imageView], 0)
            }
        }
    }

    ListView {
        id: authorFeedView
        y: avatar.y + avatar.height / 2 + 10
        width: parent.width
        height: parent.height - y
        spacing: 0
        model: skywalker.getAuthorFeedModel(page.modelId)
        ScrollIndicator.vertical: ScrollIndicator {}

        header: Column {
            width: parent.width
            leftPadding: 10
            rightPadding: 10

            RowLayout {
                SvgButton {
                    Material.background: guiSettings.buttonColor
                    iconColor: guiSettings.buttonTextColor
                    svg: svgOutline.moreVert
                }
                SkyButton {
                    text: qsTr("Follow")
                    visible: !following && !isUser(author) && !author.viewer.blockedBy
                    onClicked: graphUtils.follow(author.did)
                }
                SkyButton {
                    flat: true
                    text: qsTr("Following")
                    visible: following && !isUser(author) && !author.viewer.blockedBy
                    onClicked: graphUtils.unfollow(author.did, following)
                }
            }

            Text {
                id: nameText
                width: parent.width - (parent.leftPadding + parent.rightPadding)
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                font.pointSize: guiSettings.scaledFont(16/8)
                text: author.name
            }

            RowLayout {
                width: parent.width - (parent.leftPadding + parent.rightPadding)

                Text {
                    id: handleText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: guiSettings.handleColor
                    text: `@${author.handle}`
                }
                SkyLabel {
                    text: qsTr("follows you")
                    visible: author.viewer.followedBy
                }
            }

            Row {
                id: statsRow
                width: parent.width - (parent.leftPadding + parent.rightPadding)
                spacing: 15
                topPadding: 10
                visible: !author.viewer.blockedBy

                Text {
                    color: guiSettings.linkColor
                    text: qsTr(`<b>${author.followersCount}</b> followers`)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let modelId = skywalker.createAuthorListModel(
                                    QEnums.AUTHOR_LIST_FOLLOWERS, author.did)
                            root.viewAuthorList(modelId, qsTr("Followers"))
                        }
                    }
                }
                Text {
                    color: guiSettings.linkColor
                    text: qsTr(`<b>${author.followsCount}</b> following`)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let modelId = skywalker.createAuthorListModel(
                                    QEnums.AUTHOR_LIST_FOLLOWS, author.did)
                            root.viewAuthorList(modelId, qsTr("Following"))
                        }
                    }
                }
                Text {
                    text: qsTr(`<b>${author.postsCount}</b> posts`)
                }
            }

            Text {
                id: descriptionText
                width: parent.width - (parent.leftPadding + parent.rightPadding)
                topPadding: 10
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                text: postUtils.linkiFy(author.description)
                visible: !author.viewer.blockedBy

                onLinkActivated: (link) => {
                                     if (link.startsWith("@")) {
                                         console.debug("MENTION:", link)
                                         skywalker.getDetailedProfile(link.slice(1))
                                     } else {
                                         Qt.openUrlExternally(link)
                                     }
                                 }
            }

            Text {
                width: parent.width - (parent.leftPadding + parent.rightPadding)
                topPadding: 10
                bottomPadding: 10
                font.bold: true
                text: qsTr("Posts")
            }

            Rectangle {
                x: -parent.leftPadding
                width: parent.width
                height: 1
                color: "lightgrey"
            }
        }

        delegate: PostFeedViewDelegate {
            viewWidth: authorFeedView.width
        }

        onVerticalOvershootChanged: {
            if (verticalOvershoot < 0)  {
                if (!inTopOvershoot && !skywalker.getAuthorFeedInProgress) {
                    skywalker.getAuthorFeed(modelId, 100)
                }

                inTopOvershoot = true
            } else {
                inTopOvershoot = false
            }

            if (verticalOvershoot > 0) {
                if (!inBottomOvershoot && !skywalker.getAuthorFeedInProgress) {
                    skywalker.getAuthorFeedNextPage(modelId)
                }

                inBottomOvershoot = true;
            } else {
                inBottomOvershoot = false;
            }
        }

        BusyIndicator {
            id: busyIndicator
            anchors.centerIn: parent
            running: skywalker.getAuthorFeedInProgress
        }

        SvgImage {
            id: noPostImage
            width: 150
            height: 150
            y: height + (parent.headerItem ? parent.headerItem.height : 0)
            anchors.horizontalCenter: parent.horizontalCenter
            color: "grey"
            svg: {
                if (author.viewer.blockedBy || author.viewer.blocking) {
                    return svgOutline.block
                } else if (author.viewer.muted) {
                    return svgOutline.muted
                }

                return svgOutline.noPosts
            }
            visible: authorFeedView.count === 0
        }
        Text {
            y: noPostImage.y
            anchors.horizontalCenter: parent.horizontalCenter
            font.pointSize: guiSettings.scaledFont(10/8)
            color: "grey"
            text: {
                if (author.viewer.blocking) {
                    return "You blocked this account"
                } else if (author.viewer.blockedBy) {
                    return "You are blocked"
                } else if (author.viewer.muted) {
                    return "You muted this account"
                }

                return "No posts"
            }
            visible: authorFeedView.count === 0
        }
    }

    StatusPopup {
        id: statusPopup
    }

    PostUtils {
        id: postUtils
        skywalker: page.skywalker
    }

    GraphUtils {
        id: graphUtils
        skywalker: page.skywalker

        onFollowOk: (uri) => { following = uri }
        onFollowFailed: (error) => { statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR) }
        onUnfollowOk: following = ""
        onUnfollowFailed: (error) => { statusPopup.show(error, QEnums.STATUS_LEVEL_ERROR) }
    }

    GuiSettings {
        id: guiSettings
    }

    function isUser(author) {
        return skywalker.getUserDid() === author.did
    }

    Component.onDestruction: {
        skywalker.removeAuthorFeedModel(modelId)
    }
}
