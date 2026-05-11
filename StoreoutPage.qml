import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Stores Out"

    property var stackViewRef
    property var appToast

    ListModel { id: storeOutModelDirect }
    ListModel { id: storeOutModelWork }

    QtObject {
        id: storeOutVM

        property int pendingQueueId: -1
        property string pendingItemId: ""

        property var detailsModel: ListModel {
            ListElement { label: "Unique Id"; value: "No pickup selected"; isWarning: false }
            ListElement { label: "Status"; value: "-"; isWarning: false }
        }

        function loadRows() {
            storeOutModelDirect.clear()
            storeOutModelWork.clear()

            var directRows = dbManager.getStoreOutQueue("direct")
            for (var i = 0; i < directRows.length; i++) {
                storeOutModelDirect.append({
                    queueId: directRows[i].queueId,
                    pickupId: "DIR-" + directRows[i].queueId,
                    uniqueIds: directRows[i].itemId,
                    part: directRows[i].part || "-",
                    qty: String(directRows[i].qty || 0),
                    status: "Ready",
                    buttonText: "Pickup",
                    deleteText: "Delete"
                })
            }

            var workRows = dbManager.getStoreOutQueue("workorder")
            for (var j = 0; j < workRows.length; j++) {
                storeOutModelWork.append({
                    queueId: workRows[j].queueId,
                    pickupId: workRows[j].workOrder && workRows[j].workOrder.length > 0
                              ? workRows[j].workOrder
                              : "WO-" + workRows[j].queueId,
                    uniqueIds: workRows[j].itemId,
                    part: workRows[j].part || "-",
                    qty: String(workRows[j].qty || 0),
                    status: "Ready",
                    buttonText: "Pickup",
                    deleteText: "Cancel"
                })
            }
        }

        function requestPickup(queueId, uniqueIds, pickupId) {
            pendingQueueId = queueId
            pendingItemId = uniqueIds
            confirmDialog.message = "Are you sure you want to pick up " + uniqueIds + "?"
            confirmDialog.open()
        }

        function confirmPickup() {
            var result = dbManager.confirmStoreOut(pendingQueueId)
            if (result === "SUCCESS") {
                if (root.appToast)
                    root.appToast.show("Pickup successful for " + pendingItemId + ".", "success")
                pendingQueueId = -1
                pendingItemId = ""
                loadRows()
                return
            }

            if (root.appToast)
                root.appToast.show(dbManager.lastError || ("Pickup failed for " + pendingItemId + "."), "error")
        }

        function actionDelete(queueId, pickupId) {
            dbManager.deleteStoreOutQueue(queueId)
            if (root.appToast)
                root.appToast.show("Delete selected: " + pickupId, "warn")
        }

        function actionCancel(queueId, uniqueIds, pickupId) {
            dbManager.deleteStoreOutQueue(queueId)
            if (root.appToast)
                root.appToast.show("Cancel selected: " + pickupId, "warn")
        }

        function showDetails(uniqueIds, pickupId, statusText) {
            detailsModel.clear()
            detailsModel.append({ label: "Pickup Id", value: pickupId, isWarning: false })
            detailsModel.append({ label: "Unique Ids", value: uniqueIds, isWarning: false })
            detailsModel.append({ label: "Status", value: statusText, isWarning: statusText === "Cancel" })
            detailsDialog.open()
        }
    }

    Connections {
        target: dbNotifier
        function onDatabaseChanged() {
            storeOutVM.loadRows()
        }
    }

    Component.onCompleted: storeOutVM.loadRows()

    Rectangle {
        anchors.fill: parent
        color: "#eef3f8"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 104
                radius: 18
                color: "white"
                border.color: "#dbe3ea"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 16

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: "Stores Out"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#14213d"
                        }

                        Label {
                            text: "Track direct and work-order outbound activity in one place."
                            color: "#64748b"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    TabBar {
                        id: modeTabs
                        background: Rectangle {
                            radius: 12
                            color: "#f8fafc"
                            border.color: "#dbe3ea"
                        }

                        TabButton { text: "Direct Pickup" }
                        TabButton { text: "Work Order" }
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: modeTabs.currentIndex

                StoreOutPane {
                    title: "Direct Queue"
                    accentColor: "#2563eb"
                    searchPlaceholder: "Search direct pickup"
                    listModel: storeOutModelDirect
                    onPrimaryAction: function(queueId, uniqueIds, pickupId, buttonText) {
                        if (buttonText === "Pickup")
                            storeOutVM.requestPickup(queueId, uniqueIds, pickupId)
                    }
                    onSecondaryAction: function(queueId, uniqueIds, pickupId, deleteText) {
                        if (deleteText === "Delete")
                            storeOutVM.actionDelete(queueId, pickupId)
                        else
                            storeOutVM.actionCancel(queueId, uniqueIds, pickupId)
                    }
                }

                StoreOutPane {
                    title: "Work Order Queue"
                    accentColor: "#0f766e"
                    searchPlaceholder: "Search work order pickup"
                    listModel: storeOutModelWork
                    onPrimaryAction: function(queueId, uniqueIds, pickupId, buttonText) {
                        if (buttonText === "Pickup")
                            storeOutVM.requestPickup(queueId, uniqueIds, pickupId)
                    }
                    onSecondaryAction: function(queueId, uniqueIds, pickupId, deleteText) {
                        if (deleteText === "Delete")
                            storeOutVM.actionDelete(queueId, pickupId)
                        else
                            storeOutVM.actionCancel(queueId, uniqueIds, pickupId)
                    }
                }
            }
        }

        Dialog {
            id: confirmDialog
            modal: true
            width: 420
            anchors.centerIn: parent

            property string message: ""

            background: Rectangle {
                radius: 18
                color: "white"
                border.color: "#dbe3ea"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Label {
                    text: "Confirm Pickup"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#14213d"
                }

                Label {
                    text: confirmDialog.message
                    wrapMode: Text.WordWrap
                    color: "#475569"
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "No"
                        onClicked: confirmDialog.close()
                    }

                    Button {
                        text: "Yes"
                        onClicked: {
                            confirmDialog.close()
                            storeOutVM.confirmPickup()
                        }
                    }
                }
            }
        }

        Dialog {
            id: detailsDialog
            modal: true
            width: 640
            anchors.centerIn: parent

            background: Rectangle {
                radius: 18
                color: "white"
                border.color: "#dbe3ea"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Pickup Details"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Close"
                        onClicked: detailsDialog.close()
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    clip: true
                    model: storeOutVM.detailsModel
                    spacing: 8

                    delegate: Rectangle {
                        width: ListView.view ? ListView.view.width : 0
                        height: 48
                        radius: 12
                        color: isWarning ? "#fee2e2" : "#f8fafc"
                        border.color: "#e2e8f0"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Text {
                                text: label
                                font.bold: true
                                Layout.preferredWidth: 160
                            }

                            Text {
                                text: value
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    component StoreOutPane: Item {
        property string title: ""
        property string accentColor: "#2563eb"
        property string searchPlaceholder: ""
        property var listModel
        signal primaryAction(int queueId, string uniqueIds, string pickupId, string buttonText)
        signal secondaryAction(int queueId, string uniqueIds, string pickupId, string deleteText)

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: title
                    font.pixelSize: 20
                    font.bold: true
                    color: "#0f172a"
                }

                TextField {
                    placeholderText: searchPlaceholder
                    Layout.preferredWidth: 280
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: "white"
                border.color: "#dbe3ea"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 12
                        color: "#f8fafc"
                        border.color: "#e2e8f0"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text { text: "Pickup Id"; font.bold: true; Layout.preferredWidth: 110 }
                            Text { text: "Unique Ids"; font.bold: true; Layout.preferredWidth: 170 }
                            Text { text: "Part"; font.bold: true; Layout.fillWidth: true }
                            Text { text: "Qty"; font.bold: true; Layout.preferredWidth: 50 }
                            Text { text: "Status"; font.bold: true; Layout.preferredWidth: 90 }
                            Item { Layout.preferredWidth: 192 }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: listModel

                        delegate: Rectangle {
                            width: ListView.view ? ListView.view.width : 0
                            height: 58
                            radius: 14
                            color: index % 2 === 0 ? "#ffffff" : "#f8fafc"
                            border.color: "#e2e8f0"

                            property int queueId: model.queueId

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text { text: model.pickupId; Layout.preferredWidth: 110; elide: Text.ElideRight }
                                Text { text: model.uniqueIds; Layout.preferredWidth: 170; elide: Text.ElideRight }
                                Text { text: model.part; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: model.qty; Layout.preferredWidth: 50 }
                                Text { text: model.status; Layout.preferredWidth: 90 }

                                Button {
                                    id: primaryButton
                                    text: model.buttonText
                                    Layout.preferredWidth: 90
                                    background: Rectangle {
                                        radius: 8
                                        color: accentColor
                                    }
                                    contentItem: Text {
                                        text: primaryButton.text
                                        color: "white"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: primaryAction(queueId, model.uniqueIds, model.pickupId, model.buttonText)
                                }

                                Button {
                                    id: secondaryButton
                                    text: model.deleteText
                                    Layout.preferredWidth: 90
                                    background: Rectangle {
                                        radius: 8
                                        color: "#e11d48"
                                    }
                                    contentItem: Text {
                                        text: secondaryButton.text
                                        color: "white"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: secondaryAction(queueId, model.uniqueIds, model.pickupId, model.deleteText)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
