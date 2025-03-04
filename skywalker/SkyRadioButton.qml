import QtQuick
import QtQuick.Controls
import skywalker

RadioButton {
    property int horizontalAlignment: Qt.AlignLeft
    property int borderWidth: 1

    id: radio
    padding: 0

    indicator: Rectangle { width: 0 }
    display: AbstractButton.TextOnly
    icon.name: ""
    icon.source: ""

    contentItem: Label {
        padding: 5
        background: Rectangle {
            color: radio.checked ? guiSettings.buttonColor : "transparent"
            border.width: radio.borderWidth
            border.color: guiSettings.buttonColor
        }
        horizontalAlignment: radio.horizontalAlignment
        color: checked ? guiSettings.buttonTextColor : guiSettings.buttonColor
        text: radio.text
    }

    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.onToggleAction: toggle()

}
