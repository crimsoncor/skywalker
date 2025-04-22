import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    property date startingDate: Date.now()
    property date selectedDate: Date.now()

    id: page
    width: parent.width
    topMargin: guiSettings.headerHeight
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    Material.background: guiSettings.backgroundColor

    AccessibleText {
        id: header
        width: parent.width
        font.bold: true
        text: qsTr('Goto:')
    }

    SkyTextInput {
        id: dateInput
        anchors.top: header.bottom
        Layout.fillWidth: true
        svgIcon: SvgOutline.date
        placeholderText: qsTr("Date, time")
        text: selectedDate.toLocaleString(Qt.locale(), Locale.ShortFormat)

        MouseArea {
            anchors.fill: parent
            onClicked: selectDate()
        }
    }

    GridLayout {
        id: plusMinusGrid
        anchors.top: dateInput.bottom

        columns: 2

        AccessibleText {
            id: backHeader
            text: qsTr("Back:")
        }

        AccessibleText {
            id: forwardHeader
            text: qsTr("Forward:")
        }

        SkyButton {
            id: backHourButton
            text: qsTr("-1 hour")
            onClicked: {
                startingDate = new Date(startingDate.getTime() - (60 * 60 * 1000));
            }
        }

        SkyButton {
            id: forwardHourButton
            text: qsTr("+1 hour")
            onClicked: {
                startingDate = new Date(startingDate.getTime() + (60 * 60 * 1000));
                var now = new Date();
                if (startingDate > now) {
                    startingDate = now
                }
            }
        }

        SkyButton {
            id: back6HourButton
            text: qsTr("-6 hour")
            onClicked: {
                startingDate = new Date(startingDate.getTime() - (6 * 60 * 60 * 1000));
            }
        }

        SkyButton {
            id: forward6HourButton
            text: qsTr("+6 hour")
            onClicked: {
                startingDate = new Date(startingDate.getTime() + (6 * 60 * 60 * 1000));
                var now = new Date();
                if (startingDate > now) {
                    startingDate = now
                }
            }
        }

        SkyButton {
            id: backDayButton
            text: qsTr("-1 day")
            onClicked: {
                startingDate = new Date(startingDate.getTime() - (24 * 60 * 60 * 1000));
            }
        }

        SkyButton {
            id: forwardDayButton
            text: qsTr("+1 day")
            onClicked: {
                startingDate = new Date(startingDate.getTime() + (24 * 60 * 60 * 1000));
                var now = new Date();
                if (startingDate > now) {
                    startingDate = now
                }
            }
        }
    }

    function selectDate() {
        if (isNaN(selectedDate.getTime()))
            selectedDate = Date.now()

        let component = guiSettings.createComponent("DatePicker.qml")
        let datePicker = component.createObject(parent, { selectedDate: selectedDate, enableTime: true })
        datePicker.onRejected.connect(() => datePicker.destroy())

        datePicker.onAccepted.connect(() => {
            selectedDate = datePicker.selectedDate
            datePicker.destroy()
        })

        datePicker.open()
    }

    function show() {
        open()
    }

}
