import QtQuick
import QtQuick.Shapes
import skywalker

Shape {
    required property SvgImage svg
    property string color
    property string outlineColor: color

    id: shape
    y: height

    ShapePath {
        property string myPath: shape.svg.path

        id: shapePath
        scale: Qt.size(shape.height / shape.svg.width, shape.height / shape.svg.height)
        strokeColor: shape.outlineColor
        fillColor: shape.color
        PathSvg { path: shapePath.myPath } // shape.svg.path makes the app crash when you refresh timeline ???
    }
}
