import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Reels In"

    property var stackViewRef
    property var appToast

    property string scannedData: ""
    property string partNumber: ""
    property string internalPN: ""
    property int quantity: 0
    property string manufacturer: ""
    property string manufactureDate: ""
    property string lotNumber: ""
    property string invoiceNumber: ""
    property string description: ""
    property string expireDate: ""

    QtObject {
        id: reelVM

        property string error: ""
        property bool loading: false
        property var recentReels: []

        function refreshRecent() {
            var rows = dbManager.getRecentInventory()
            var reels = []

            for (var i = 0; i < rows.length; i++) {
                reels.push({
                    uniqueId: rows[i].id || "",
                    part: rows[i].part || "",
                    qty: rows[i].qty || 0,
                    updatedAt: rows[i].updatedAt || ""
                })
            }

            recentReels = reels
        }

        function clearForm() {
            error = ""
            uniqueIdField.clear()
            uniqueIdField.forceActiveFocus()
        }

        function handleIn() {
            root.scannedData = uniqueIdField.text.trim()

            if (root.scannedData.length === 0) {
                error = "Unique ID cannot be empty!"
                return
            }

            loading = true
            error = ""

            if (dbManager.reelExists(root.scannedData)) {
                loading = false
                error = "Data Already Present!"
                if (root.appToast)
                    root.appToast.show("Data Already Present!", "error")
                uniqueIdField.selectAll()
                uniqueIdField.forceActiveFocus()
                return
            }

            root.partNumber = root.scannedData
            root.quantity = 1
            root.lotNumber = ""

            dbManager.addInventory(root.scannedData, root.partNumber, root.lotNumber, root.quantity)
            loading = false

            if (dbManager.lastError.length > 0) {
                error = dbManager.lastError
                if (root.appToast)
                    root.appToast.show(dbManager.lastError, "error")
                return
            }

            refreshRecent()
            uniqueIdField.clear()
            uniqueIdField.forceActiveFocus()

            if (root.appToast)
                root.appToast.show("Reelin success", "success")
        }
    }

    Connections {
        target: dbNotifier
        function onDatabaseChanged() {
            reelVM.refreshRecent()
        }
    }

    Component.onCompleted: {
        reelVM.refreshRecent()
        uniqueIdField.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "#ecf0f1"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Label {
                text: "Reels In"
                font.pixelSize: 22
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    radius: 8
                    color: "white"
                    border.color: "#d7dfe7"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 40
                        spacing: 12

                        TextField {
                            id: uniqueIdField
                            placeholderText: "Unique Id"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            focus: true
                            onAccepted: reelVM.handleIn()
                        }

                        Label {
                            id: errorText
                            color: "#d32f2f"
                            text: reelVM.error
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 10
                            Layout.fillWidth: true

                            Button {
                                text: "IN"
                                Layout.fillWidth: true
                                onClicked: reelVM.handleIn()
                            }

                            Button {
                                text: "CANCEL"
                                Layout.fillWidth: true
                                onClicked: reelVM.clearForm()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    radius: 8
                    color: "white"
                    border.color: "#d7dfe7"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Label {
                            text: "Recently Scanned Reels"
                            font.bold: true
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ListView {
                                id: recentList
                                width: parent.width
                                height: parent.height
                                model: reelVM.recentReels
                                spacing: 6

                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 42
                                    radius: 6
                                    color: index % 2 === 0 ? "#f8fafc" : "#eef2f7"

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        text: "UID: " + modelData.uniqueId + " | Part: " + modelData.part + " | Qty: " + modelData.qty
                                        color: "#334155"
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Label {
                            text: "No reels scanned yet"
                            visible: reelVM.recentReels.length === 0
                            color: "#64748b"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                radius: 8
                color: "white"
                border.color: "#d7dfe7"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Label {
                        text: "Rack Details"
                        font.bold: true
                    }

                    Label {
                        text: "Connect QAbstractTableModel here"
                        color: "#64748b"
                    }
                }
            }
        }
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#80000000"
        visible: reelVM.loading
        z: 10

        BusyIndicator {
            anchors.centerIn: parent
            running: reelVM.loading
        }

        MouseArea {
            anchors.fill: parent
        }
    }
}
