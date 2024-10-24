pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import skywalker

ComboBox {
    property profile selectedAuthor: currentValue ? currentValue : nullProfile
    property profile nullProfile

    id: authorComboBox
    valueRole: "author"

    onCountChanged: currentIndex = 0

    contentItem: AuthorItemDelegate {
        author: authorComboBox.selectedAuthor
    }

    delegate: ItemDelegate {
        required property int index
        required property var modelData

        id: delegate
        width: authorComboBox.popup.width
        highlighted: authorComboBox.highlightedIndex === index

        contentItem: AuthorItemDelegate {
            author: delegate.modelData.author
        }

        background: Rectangle {
            implicitWidth: delegate.width
            color: delegate.highlighted ? Material.listHighlightColor : "transparent"
        }
    }

    GuiSettings {
        id: guiSettings
    }
}
