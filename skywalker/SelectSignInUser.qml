import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import skywalker

SkyPage {
    property list<basicprofile> userList

    signal selectedUser(basicprofile user)
    signal deletedUser(basicprofile user)
    signal canceled

    id: page

    Accessible.role: Accessible.Pane

    header: Rectangle {
        width: parent.width
        height: guiSettings.headerHeight
        z: guiSettings.headerZLevel
        color: guiSettings.headerColor

        Accessible.role: Accessible.Pane

        RowLayout {
            width: parent.width
            height: guiSettings.headerHeight

            SvgPlainButton {
                id: backButton
                iconColor: guiSettings.headerTextColor
                svg: SvgOutline.arrowBack
                accessibleName: qsTr("go back")
                onClicked: page.canceled()
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                leftPadding: 10
                font.bold: true
                font.pointSize: guiSettings.scaledFont(10/8)
                color: guiSettings.headerTextColor
                text: qsTr("Sign in as")

                Accessible.role: Accessible.TitleBar
                Accessible.name: qsTr("Select user to sign in")
            }
        }
    }

    SimpleAuthorListView {
        anchors.fill: parent
        rowPadding: 13
        allowDelete: true
        model: userList
        onAuthorClicked: (profile) => { selectedUser(profile) }
        onDeleteClicked: (profile) => { deleteUser(profile) }
    }


    function deleteUser(profile) {
        guiSettings.askYesNoQuestion(
                    page,
                    qsTr(`Do you really want to delete account "${profile.name}"?`),
                    () => page.deletedUser(profile))
    }
}
