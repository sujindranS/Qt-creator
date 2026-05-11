import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Pick Up"

    property var stackViewRef
    property var appToast

    ListModel {
        id: pickupModel
    }

    function loadTable() {
        pickupModel.clear()

        var search = searchField.text ? searchField.text.toLowerCase().trim() : ""
        var data = dbManager.getInventory()

        for (var i = 0; i < data.length; i++) {
            var idText = (data[i].id || "").toString()
            var partText = (data[i].part || "").toString()
            var lotText = (data[i].lot || "").toString()
            var updatedText = (data[i].updatedAt || "").toString()

            if (search &&
                    !idText.toLowerCase().includes(search) &&
                    !partText.toLowerCase().includes(search) &&
                    !lotText.toLowerCase().includes(search))
                continue

            pickupModel.append({
                itemId: idText,
                part: partText,
                lot: lotText,
                qty: data[i].qty || 0,
                time: updatedText,
                checked: false
            })
        }
    }

    function showPickupResult(result, itemId) {
        if (result === "SUCCESS")
            appToast.show("Pickup successful for " + itemId + ".", "success")
        else if (result === "NOT_FOUND")
            appToast.show("Item " + itemId + " was not found.", "error")
        else if (result === "OUT_OF_STOCK")
            appToast.show("Item " + itemId + " is out of stock.", "warn")
        else if (result === "INVALID_INPUT")
            appToast.show("Scan a valid item id first.", "warn")
        else
            appToast.show("Pickup failed. " + (dbManager.lastError || ""), "error")
    }

    function doDirectPick() {
        var idText = scanInput.text.trim()
        if (!idText) {
            appToast.show("Scan a barcode before pickup.", "warn")
            return
        }

        var result = dbManager.pickupDirect(idText)
        showPickupResult(result, idText)
        scanInput.text = ""
        scanInput.forceActiveFocus()
        loadTable()
    }

    function addSelectedToPickup() {
        var queued = 0
        var selected = 0

        for (var i = 0; i < pickupModel.count; i++) {
            var item = pickupModel.get(i)
            if (!item.checked)
                continue

            selected++
            if (dbManager.enqueueStoreOut(item.itemId, "", "direct"))
                queued++
        }

        if (selected === 0)
            appToast.show("Select at least one row to add.", "warn")
        else if (queued === selected)
            appToast.show(queued + " item(s) added to Stores Out.", "success")
        else if (queued === 0)
            appToast.show(dbManager.lastError || "No items were added to Stores Out.", "error")
        else
            appToast.show(queued + " of " + selected + " item(s) added to Stores Out.", "warn")

        loadTable()
    }

    Connections {
        target: dbNotifier
        function onDatabaseChanged() {
            loadTable()
        }
    }

    Component.onCompleted: {
        loadTable()
        scanInput.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: "#eef3f8"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                radius: 18
                color: "white"
                border.color: "#dbe3ea"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 18

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: "Pickup"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#14213d"
                        }

                        Label {
                            text: "Scan reels, filter inventory, and complete direct or work-order pickup flows."
                            color: "#64748b"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        radius: 14
                        color: "#f8fafc"
                        border.color: "#dbe3ea"
                        implicitWidth: 188
                        implicitHeight: 56

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: tabBar.currentIndex === 0 ? "Direct Pickup" : "Work Order Pickup"
                                font.bold: true
                                color: "#0f172a"
                            }

                            Text {
                                text: "Rows: " + pickupModel.count
                                color: "#64748b"
                            }
                        }
                    }
                }
            }

            TabBar {
                id: tabBar
                Layout.fillWidth: true

                background: Rectangle {
                    radius: 14
                    color: "white"
                    border.color: "#dbe3ea"
                }

                TabButton { text: "Direct Pickup" }
                TabButton { text: "Work Order Pickup" }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            TextField {
                                id: searchField
                                placeholderText: "Search by id, part, or lot"
                                Layout.preferredWidth: 280
                                onTextChanged: loadTable()
                            }

                            TextField {
                                id: scanInput
                                placeholderText: "Scan item for direct pickup"
                                Layout.fillWidth: true
                                onAccepted: doDirectPick()
                            }

                            Button {
                                text: "Scan Pick"
                                onClicked: doDirectPick()
                            }

                            Button {
                                text: "Add To Pickup"
                                onClicked: addSelectedToPickup()
                            }
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
                                    height: 44
                                    radius: 12
                                    color: "#f8fafc"
                                    border.color: "#e2e8f0"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 14

                                        CheckBox {
                                            onCheckedChanged: {
                                                for (var i = 0; i < pickupModel.count; i++)
                                                    pickupModel.setProperty(i, "checked", checked)
                                            }
                                        }

                                        Text { text: "#"; font.bold: true; Layout.preferredWidth: 34 }
                                        Text { text: "Unique Id"; font.bold: true; Layout.preferredWidth: 220 }
                                        Text { text: "Part"; font.bold: true; Layout.preferredWidth: 180 }
                                        Text { text: "Lot"; font.bold: true; Layout.preferredWidth: 140 }
                                        Text { text: "Qty"; font.bold: true; Layout.preferredWidth: 80 }
                                        Text { text: "Updated"; font.bold: true; Layout.fillWidth: true }
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 8
                                    model: pickupModel

                                    delegate: Rectangle {
                                        width: ListView.view ? ListView.view.width : 0
                                        height: 54
                                        radius: 14
                                        color: qty === 0 ? "#fff1f2" : (index % 2 === 0 ? "#ffffff" : "#f8fafc")
                                        border.color: qty === 0 ? "#fecdd3" : "#e2e8f0"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 14

                                            CheckBox {
                                                checked: model.checked
                                                onCheckedChanged: pickupModel.setProperty(index, "checked", checked)
                                            }

                                            Text { text: index + 1; Layout.preferredWidth: 34 }
                                            Text { text: itemId; Layout.preferredWidth: 220; elide: Text.ElideRight }
                                            Text { text: part; Layout.preferredWidth: 180; elide: Text.ElideRight }
                                            Text { text: lot; Layout.preferredWidth: 140; elide: Text.ElideRight }
                                            Text {
                                                text: qty
                                                Layout.preferredWidth: 80
                                                color: qty === 0 ? "#dc2626" : "#0f172a"
                                                font.bold: qty === 0
                                            }
                                            Text { text: time; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                    }
                                }

                                Label {
                                    text: "No inventory records found"
                                    visible: pickupModel.count === 0
                                    color: "#64748b"
                                    Layout.alignment: Qt.AlignHCenter
                                    padding: 18
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    radius: 18
                    color: "white"
                    border.color: "#dbe3ea"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 18

                        Label {
                            text: "Work Order Pickup"
                            font.pixelSize: 24
                            font.bold: true
                            color: "#14213d"
                        }

                        Label {
                            text: "This flow uses the same protected inventory update path in C++. Connect the final work-order source here before enabling it for production."
                            wrapMode: Text.WordWrap
                            color: "#64748b"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: 16
                            color: "#f8fafc"
                            border.color: "#dbe3ea"
                            implicitHeight: 180

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 12

                                TextField {
                                    id: workOrderScanInput
                                    Layout.fillWidth: true
                                    placeholderText: "Scan or enter item id"
                                }

                                Button {
                                    text: "Add Sample Work Order"
                                    Layout.alignment: Qt.AlignLeft
                                    onClicked: {
                                        if (dbManager.enqueueStoreOut(workOrderScanInput.text.trim(), "WO-DEMO", "workorder"))
                                            appToast.show("Work order item added to Stores Out.", "success")
                                        else
                                            appToast.show(dbManager.lastError || "Work order queue failed.", "warn")
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
