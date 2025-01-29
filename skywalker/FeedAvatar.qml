import QtQuick
import skywalker

Avatar {
    property int contentMode: QEnums.CONTENT_MODE_UNSPECIFIED
    property string badgeOutlineColor: guiSettings.backgroundColor

    radius: width * 0.1
    unknownSvg: SvgFilled.feed

    SkySvg {
        x: parent.width - width * 0.8
        y: height - height * 0.2
        width: parent.width * 0.5
        height: width
        color: guiSettings.videoIconColor
        outlineColor: badgeOutlineColor
        svg: contentMode === QEnums.CONTENT_MODE_VIDEO ? SvgFilled.film : SvgFilled.image
        visible: [QEnums.CONTENT_MODE_VIDEO, QEnums.CONTENT_MODE_MEDIA].includes(contentMode)
    }
}
