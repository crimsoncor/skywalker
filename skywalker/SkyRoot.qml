pragma Singleton
import QtQuick
import QtQuick.Controls

QtObject {
    property ApplicationWindow root

    function skywalker() {
        return root.getSkywalker()
    }
}
