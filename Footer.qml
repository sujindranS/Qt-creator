import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: footer

    Layout.fillWidth: true
    Layout.preferredHeight: 30

    color: "#0078D7"

    property string appVersion: "v1.0.0"
    readonly property string currentYear: {
        var d = new Date()
        return d.getFullYear().toString()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 10

        Text {
            text: "Copyright " + footer.currentYear + " Rexsatronix         | All Rights Reserved"
            color: "white"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: footer.appVersion
            color: "white"
            font.pixelSize: 13
            opacity: 0.8
            verticalAlignment: Text.AlignVCenter
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
