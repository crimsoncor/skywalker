import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

Page {
    required property var images // list<imageview>: var to allow regular javascript arrays
    required property int imageIndex
    signal closed

    id: page
    width: parent.width
    height: parent.height
    padding: 10
    background: Rectangle { color: "black" }

    SwipeView {
        id: view
        anchors.fill: parent
        currentIndex: imageIndex

        Repeater {
            model: images.length

            Rectangle {
                required property int index
                property bool isCurrentItem: SwipeView.isCurrentItem

                id: imgRect
                color: "black"

                Image {
                    y: (parent.height - altText.height - height) / 2
                    width: parent.width
                    height: parent.height - altText.height
                    fillMode: Image.PreserveAspectFit
                    source: images[index].fullSizeUrl

                    PinchHandler {
                        rotationAxis.enabled: false
                    }
                }
                Text {
                    id: altText
                    width: parent.width
                    anchors.bottom: parent.bottom
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    color: "white"
                    text: images[index].alt
                    visible: images[index].alt && isCurrentItem
                }
            }
        }
    }

    SvgButton {
        iconColor: "white"
        Material.background: "black"
        opacity: 0.7
        svg: svgOutline.arrowBack
        onClicked: page.closed()
    }
}
