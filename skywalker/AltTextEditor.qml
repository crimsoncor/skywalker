import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyPage {
    required property string imgSource
    property bool sourceIsVideo: false
    property alias text: altText.text
    property var skywalker: root.getSkywalker()
    readonly property int margin: 10

    signal altTextChanged(string text)

    id: page
    width: parent.width
    topPadding: 10
    bottomPadding: 10

    header: SimpleButtonHeader {
        title: qsTr("ALT text")
        buttonSvg: svgOutline.check
        enabled: !altText.maxGraphemeLengthExceeded()
        onButtonClicked: altTextChanged(page.text)
    }

    // Needed for SkyFormattedTextEdit
    footer: Rectangle {
        height: 0
        color: "transparent"
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: altImage.y + altImage.height
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        onHeightChanged: altText.ensureVisible(altText.cursorRectangle)

        SkyFormattedTextEdit {
            id: altText
            width: parent.width
            leftPadding: page.margin
            rightPadding: page.margin
            parentPage: page
            parentFlick: flick
            maxLength: 1000
            placeholderText: qsTr("Help users with visual impairments")
        }

        Image {
            id: altImage
            anchors.leftMargin: page.margin
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.top: altText.bottom
            width: 240
            height: 180
            fillMode: Image.PreserveAspectCrop
            autoTransform: true
            source: !sourceIsVideo ? page.imgSource : ""
            visible: !sourceIsVideo
        }

        VideoThumbnail {
            id: altVideo
            anchors.leftMargin: page.margin
            anchors.left: parent.left
            anchors.topMargin: 10
            anchors.top: altText.bottom
            width: Math.min(height * 1.777, page.width - 2 * page.margin)
            height: 180
            videoSource: sourceIsVideo ? page.imgSource : ""
            visible: sourceIsVideo
        }
    }

    VirtualKeyboardPageResizer {
        id: virtualKeyboardPageResizer
    }

    Component.onCompleted: {
        // Save the full page height now. Later when the Android keyboard pops up,
        // the page height sometimes changes by itself, but not always...
        virtualKeyboardPageResizer.fullPageHeight = parent.height

        altText.forceActiveFocus()
    }
}
