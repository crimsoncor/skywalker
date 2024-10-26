import QtQuick
import skywalker

SvgButton {
    property var overrideOnClicked

    id: button
    x: 10 + (parent.width - width - 20) * SkyRoot.root.postButtonRelativeX
    width: 70
    height: width
    opacity: 0.6
    imageMargin: 20
    svg: SvgOutline.chat
    accessibleName: qsTr("create post")

    onXChanged: {
        if (mouseArea.drag.active)
            SkyRoot.root.postButtonRelativeX = (x - 10) / (parent.width - width - 20)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        drag.target: button
        drag.axis: Drag.XAxis
        drag.minimumX: 10
        drag.maximumX: button.parent.width - button.width - 10

        onClicked: {
            if (button.overrideOnClicked)
                button.overrideOnClicked()
            else
                SkyRoot.root.composePost()
        }
    }
}
