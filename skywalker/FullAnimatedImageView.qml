import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyPage {
    required property string imageUrl
    property string imageTitle

    signal closed

    id: page
    width: parent.width
    height: parent.height
    padding: 10
    background: Rectangle { color: "black" }

    Text {
        id: altText
        width: parent.width
        anchors.bottom: parent.bottom
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        color: "white"
        text: imageTitle
        visible: imageTitle
    }
    AnimatedImageAutoRetry {
        id: img
        y: (parent.height - altText.height - height) / 2
        width: parent.width
        height: parent.height - altText.height
        fillMode: Image.PreserveAspectFit
        source: imageUrl
    }
    BusyIndicator {
        id: gifLoadingIndicator
        anchors.centerIn: parent
        running: img.status === Image.Loading
    }

    SvgButton {
        iconColor: "white"
        Material.background: "black"
        opacity: 0.7
        svg: SvgOutline.arrowBack
        accessibleName: qsTr("go back")
        onClicked: page.closed()
    }
}
