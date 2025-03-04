import QtQuick
import QtQuick.Controls

ComboBox {
    id: fontComboBox
    height: 22
    model: ["Normal", "𝗕𝗼𝗹𝗱", "𝘐𝘵𝘢𝘭𝘪𝘤", "S̶t̶r̶i̶k̶e̶", "𝙼𝚘𝚗𝚘", "Sᴍᴀʟʟ ᴄᴀᴘs", "𝓒𝓾𝓻𝓼𝓲𝓿𝓮", "Ｗｉｄｅ", "Ⓑⓤⓑⓑⓛⓔ", "🅂🅀🅄🄰🅁🄴"]
    popup.width: 130

    background: Rectangle {
        radius: 3
        implicitWidth: 120
        border.color: guiSettings.buttonColor
        border.width: 1
        color: "transparent"
    }

    indicator: Item {}

    contentItem: Text {
        leftPadding: 10
        rightPadding: 10
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: fontComboBox.displayText
    }


    Component.onCompleted: {
        fontComboBox.contentItem.color = guiSettings.buttonColor
    }
}

