pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import skywalker

Dialog {
    required property string rootUri
    required property string postUri
    required property bool restrictReply
    required property bool allowMentioned
    required property bool allowFollowing
    required property list<bool> allowLists
    required property list<int> allowListIndexes
    required property list<string> allowListUrisFromDraft
    required property int listModelId
    property list<bool> duplicateList: [false, false, false]
    property bool prevAllowQuoting: true
    property bool allowQuoting: true
    property postgate postgate
    property bool postgateReceived: false
    property bool isThreadFromUser: false

    id: restrictionDialog
    width: parent.width
    contentHeight: restrictionColumn.height
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: parent
    Material.background: guiSettings.backgroundColor

    onAllowListsChanged: {
        allowLists.forEach((allow) => {
                            if (allow)
                                restrictReply = true
                        })

        checkUniqueLists()
    }

    onAllowListIndexesChanged: checkUniqueLists()

    function checkUniqueLists() {
        let duplicates = false
        let lists = []
        duplicateList = [false, false, false]

        for (let i = 0; i < allowLists.length; ++i) {
            if (allowLists[i]) {
                const index = allowListIndexes[i]

                if (lists.includes(index)) {
                    duplicateList[i] = true
                    duplicates = true
                    continue
                }

                lists.push(index)
            }
        }

        let okButton = standardButton(Dialog.Ok)

        if (okButton)
            okButton.enabled = !duplicates
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: restrictionColumn.height
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: restrictionColumn
            width: parent.width

            AccessibleText {
                width: parent.width
                padding: 10
                font.pointSize: guiSettings.scaledFont(9/8)
                font.bold: true
                text: qsTr("Quote settings")
            }

            AccessibleSwitch {
                text: qsTr("Allow others to quote this post")
                checked: restrictionDialog.allowQuoting
                enabled: restrictionDialog.postgateReceived
                onCheckedChanged: restrictionDialog.allowQuoting = checked
            }

            AccessibleText {
                width: parent.width
                padding: 10
                font.pointSize: guiSettings.scaledFont(9/8)
                font.bold: true
                text: qsTr("Who can reply to this thread?")
            }

            AccessibleCheckBox {
                checked: !restrictionDialog.restrictReply
                text: qsTr("Everyone")
                visible: restrictionDialog.isThreadFromUser
                onCheckedChanged: {
                    restrictionDialog.restrictReply = !checked

                    if (checked) {
                        restrictionDialog.allowMentioned = false
                        restrictionDialog.allowFollowing = false
                        restrictionDialog.allowLists = [false, false, false]
                    }
                }
            }
            AccessibleCheckBox {
                checked: restrictionDialog.restrictReply && !restrictionDialog.allowMentioned &&
                         !restrictionDialog.allowFollowing && !restrictionDialog.allowLists[0] &&
                         !restrictionDialog.allowLists[1] && !restrictionDialog.allowLists[2]
                text: qsTr("Nobody")
                visible: restrictionDialog.isThreadFromUser
                onCheckedChanged: {
                    if (checked) {
                        restrictionDialog.restrictReply = true
                        restrictionDialog.allowMentioned = false
                        restrictionDialog.allowFollowing = false
                        restrictionDialog.allowLists = [false, false, false]
                    }
                }
            }
            AccessibleCheckBox {
                checked: restrictionDialog.allowMentioned
                text: qsTr("Users mentioned in your post")
                visible: restrictionDialog.isThreadFromUser
                onCheckedChanged: {
                    restrictionDialog.allowMentioned = checked

                    if (checked)
                        restrictionDialog.restrictReply = true
                }
            }
            AccessibleCheckBox {
                checked: restrictionDialog.allowFollowing
                text: qsTr("Users you follow")
                visible: restrictionDialog.isThreadFromUser
                onCheckStateChanged: {
                    restrictionDialog.allowFollowing = checked

                    if (checked)
                        restrictionDialog.restrictReply = true
                }
            }

            Repeater {
                // TODO is this needed: property alias restrictReply: restrictionDialog.restrictReply

                id: listRestrictions
                width: parent.width
                model: restrictionDialog.allowLists.length
                visible: restrictionDialog.isThreadFromUser

                function available() {
                    const item = itemAt(0)
                    return item && item.visible
                }

                Row {
                    required property int index

                    width: parent.width
                    visible: listComboBox.count > index && restrictionDialog.isThreadFromUser

                    AccessibleCheckBox {
                        id: allowListCheckBox
                        checked: restrictionDialog.allowLists[parent.index]
                        text: qsTr("Users from list:")
                        onCheckStateChanged: restrictionDialog.allowLists[parent.index] = checked
                    }
                    PagingComboBox {
                        id: listComboBox
                        width: parent.width - allowListCheckBox.width
                        height: allowListCheckBox.height
                        model: skywalker.getListListModel(listModelId)
                        valueRole: "listUri"
                        textRole: "listName"
                        inProgress: skywalker.getListListInProgress
                        bottomOvershootFun: () => skywalker.getListListNextPage(listModelId)
                        initialIndex: restrictionDialog.allowListIndexes[parent.index]
                        findValue: restrictionDialog.getListUriFromDraft(parent.index)
                        backgroundColor: restrictionDialog.duplicateList[parent.index] ? guiSettings.errorColor : Material.dialogColor
                        enabled: restrictionDialog.allowLists[parent.index]

                        onCurrentIndexChanged: restrictionDialog.allowListIndexes[parent.index] = currentIndex
                        onValueFound: restrictionDialog.allowLists[parent.index] = true
                    }
                }
            }

            AccessibleText {
                x: 10
                width: parent.width - 20
                wrapMode: Text.Wrap
                font.italic: true
                text: qsTr("User lists can also be used to restrict who can reply. You have no user lists at this moment.");
                visible: restrictionDialog.isThreadFromUser && (listRestrictions.count === 0 || !listRestrictions.available())
            }

            AccessibleText {
                x: 10
                width: parent.width - 20
                wrapMode: Text.Wrap
                font.italic: true
                text: qsTr("You cannot restrict replies as this is not your thread.")
                visible: !restrictionDialog.isThreadFromUser
            }
        }
    }

    PostUtils {
        id: postUtils
        skywalker: root.getSkywalker()

        onGetPostgateOk: (postgate) => {
            restrictionDialog.postgate = postgate
            prevAllowQuoting = !postgate.disabledEmbedding
            allowQuoting = prevAllowQuoting
            postgateReceived = true
        }

        onGetPostgateFailed: (error) => skywalker.showStatusMessage(error, QEnums.STATUS_LEVEL_ERROR)
    }

    GuiSettings {
        id: guiSettings
    }

    function getListUriFromDraft(index) {
        return index < allowListUrisFromDraft.length ? allowListUrisFromDraft[index] : ""
    }

    Component.onCompleted: {
        if (postUri)
            postUtils.getPostgate(postUri)

        if (rootUri) {
            const did = postUtils.extractDidFromUri(rootUri)
            isThreadFromUser = Boolean(did === root.getSkywalker().getUserDid())
        }

        // For a post being composed there are no URIs
        if (!rootUri && !postUri) {
            postgateReceived = true
            isThreadFromUser = true
        }
    }
}
