import QtQuick
import QtQuick.Controls

Label {
    property string backgroundColor: guiSettings.labelColor

    padding: 3
    background: Rectangle { color: backgroundColor; radius: 2 }
    font.pointSize: guiSettings.labelFontSize

    GuiSettings {
        id: guiSettings
    }
}
