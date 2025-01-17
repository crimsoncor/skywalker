import QtQuick
import QtQuick.Controls.Material
import skywalker

RoundedFrame {
    property string uri
    property string title
    property string description
    property string thumbUrl
    required property int contentVisibility // QEnums::ContentVisibility
    required property string contentWarning
    property string borderColor: guiSettings.borderColor
    property int columnHeight: externalColumn.height

    id: card
    objectToRound: externalColumn
    border.width: 1
    border.color: borderColor

    FilteredImageWarning {
        id: filter
        width: parent.width - 2
        contentVisibiliy: card.contentVisibility
        contentWarning: card.contentWarning
        imageUrl: card.thumbUrl
    }

    Column {
        id: externalColumn
        width: parent.width
        topPadding: 1
        spacing: 3

        // HACK: The filter should be in this place, but inside a rounded object links
        // cannot be clicked.
        Rectangle {
            width: filter.width
            height: filter.height
            color: "transparent"
        }
        ImageAutoRetry {
            id: thumbImg
            x: 1
            width: parent.width - 2
            source: filter.imageVisible() ? card.thumbUrl : ""
            fillMode: Image.PreserveAspectFit
            indicateLoading: false
        }
        Text {
            id: linkText
            width: parent.width - 10
            leftPadding: 5
            rightPadding: 5
            text: card.uri ? new URL(card.uri).hostname : ""
            elide: Text.ElideRight
            color: guiSettings.linkColor
        }
        Text {
            id: titleText
            width: parent.width - 10
            leftPadding: 5
            rightPadding: 5
            color: Material.foreground
            text: card.title
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.bold: true
        }
        Text {
            id: descriptionText
            width: parent.width - 10
            leftPadding: 5
            rightPadding: 5
            bottomPadding: 5
            color: Material.foreground
            text: card.description ? card.description : card.uri
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
        }
    }
}
