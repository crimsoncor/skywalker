import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyPage {
    required property var images // list<imageview>: var to allow regular javascript arrays
    required property int imageIndex

    signal closed
    signal saveImage(string sourceUrl)

    id: page
    width: parent.width
    height: parent.height
    padding: 10
    background: Rectangle { color: "black" }

    SwipeView {
        property bool zooming: false

        id: view
        anchors.fill: parent
        currentIndex: imageIndex
        interactive: !zooming

        Repeater {
            model: images.length

            Rectangle {
                required property int index
                property bool isCurrentItem: SwipeView.isCurrentItem

                id: imgRect
                color: "black"

                Flickable {
                    id: altFlick
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.min(contentHeight, 6 * 21)
                    clip: true
                    contentWidth: parent.width
                    contentHeight: altText.contentHeight
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { id: altScrollBar }

                    onHeightChanged: setScrollBarPolicy()
                    onContentHeightChanged: setScrollBarPolicy()

                    function setScrollBarPolicy() {
                        altScrollBar.policy = contentHeight > height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        altScrollBar.contentItem.color = "#1d3030"
                    }

                    SkyCleanedText {
                        id: altText
                        leftPadding: 10
                        width: parent.width - 15
                        wrapMode: Text.Wrap
                        color: "white"
                        plainText: images[index].alt
                        visible: images[index].alt && isCurrentItem
                    }
                }
                ImageAutoRetry {
                    id: img
                    y: (parent.height - altFlick.height - height) / 2
                    width: parent.width
                    height: parent.height - altFlick.height
                    fillMode: Image.PreserveAspectFit
                    source: images[index].fullSizeUrl
                    transform: Translate { id: imgTranslation }

                    PinchHandler {
                        target: null
                        rotationAxis.enabled: false
                        xAxis.enabled: false
                        yAxis.enabled: false

                        onScaleChanged: (delta) => {
                            let dx = (centroid.position.x - img.getCenter().x) * img.scale
                            let dy = (centroid.position.y - img.getCenter().y) * img.scale

                            img.scale *= delta
                            imgTranslation.x -= dx * delta - dx
                            imgTranslation.y -= dy * delta - dy

                            if (img.scale < 1)
                                img.scale = 1

                            img.keepInScreen()
                        }

                        onGrabChanged: (transition, point) => {
                            if (transition === PointerDevice.UngrabPassive) {
                                view.zooming = img.scale > 1
                            }
                        }
                    }

                    PinchHandler {
                        id: imgDrag
                        target: null
                        rotationAxis.enabled: false
                        scaleAxis.enabled: false
                        minimumPointCount: 1
                        maximumPointCount: 1
                        enabled: view.zooming

                        onTranslationChanged: (delta) => {
                            imgTranslation.x += delta.x
                            imgTranslation.y += delta.y
                            img.keepInScreen()
                        }
                    }

                    function getImgSize() {
                        let xScale = width / sourceSize.width
                        let yScale = height / sourceSize.height
                        let s = Math.min(xScale, yScale)
                        return Qt.size(sourceSize.width * s, sourceSize.height * s)
                    }

                    function keepInScreen() {
                        let imgSize = img.getImgSize()

                        let maxXDrag = (imgSize.width * img.scale - imgSize.width) / 2
                        if (imgTranslation.x > maxXDrag)
                            imgTranslation.x = maxXDrag
                        else if (imgTranslation.x < -maxXDrag)
                            imgTranslation.x = -maxXDrag

                        let maxYDrag = (imgSize.height * img.scale - imgSize.height) / 2
                        if (imgTranslation.y > maxYDrag)
                            imgTranslation.y = maxYDrag
                        else if (imgTranslation.y < -maxYDrag)
                            imgTranslation.y = -maxYDrag
                    }

                    function getCenter() {
                        return Qt.point(width / 2, height / 2)
                    }
                }
            }
        }
    }

    SvgButton {
        iconColor: "white"
        Material.background: "black"
        opacity: 0.7
        svg: svgOutline.arrowBack
        accessibleName: qsTr("go back")
        onClicked: page.closed()
    }

    SvgButton {
        anchors.top: parent.top
        anchors.right: parent.right
        iconColor: "white"
        Material.background: "black"
        opacity: 0.7
        svg: svgOutline.moreVert
        accessibleName: qsTr("more options")
        onClicked: moreMenu.open()

        Menu {
            id: moreMenu
            modal: true

            MenuItem {
                text: qsTr("Save picture")
                onTriggered: page.saveImage(images[view.currentIndex].fullSizeUrl)

                MenuItemSvg {
                    svg: svgOutline.save
                }
            }

            MenuItem {
                text: qsTr("Translate")
                enabled: images[view.currentIndex].alt
                onTriggered: root.translateText(images[view.currentIndex].alt)

                MenuItemSvg {
                    svg: svgOutline.googleTranslate
                }
            }
        }
    }
}
