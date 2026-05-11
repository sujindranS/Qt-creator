import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Reports"

    property var stackViewRef
    property var appToast

    ListModel { id: reportsModel }

    QtObject {
        id: reportsVM

        property string activeTab: "store"
        property string pageTitle: "Store History"
        property string pageInfo: "Page 1 of 1"
        property int page: 1
        property int pageSize: 25
        property string searchText: ""
        property var allRows: []

        function showStoreHistory() {
            activeTab = "store"
            pageTitle = "Store History"
            page = 1
            loadRows()
        }

        function showStockHistory() {
            activeTab = "stock"
            pageTitle = "Stock History"
            page = 1
            loadRows()
        }

        function search(text) {
            searchText = (text || "").toLowerCase().trim()
            page = 1
            applyRows()
        }

        function setPageSize(sizeText) {
            pageSize = parseInt(sizeText) || 25
            page = 1
            applyRows()
        }

        function prevPage() {
            if (page > 1) {
                page--
                applyRows()
            }
        }

        function nextPage() {
            var totalPages = Math.max(1, Math.ceil(filteredRows().length / pageSize))
            if (page < totalPages) {
                page++
                applyRows()
            }
        }

        function download() {
            if (root.appToast)
                root.appToast.show("CSV download is not connected yet.", "warn")
        }

        function loadRows() {
            var rows = []

            if (activeTab === "store") {
                var pickups = dbManager.getRecentPickups()
                for (var i = 0; i < pickups.length; i++) {
                    rows.push({
                        c1: pickups[i].itemId || "",
                        c2: pickups[i].part || "",
                        c3: pickups[i].workOrder || "-",
                        c4: pickups[i].type || "",
                        c5: String(pickups[i].qty || 0),
                        c6: pickups[i].time || ""
                    })
                }
            } else {
                var inventory = dbManager.getInventory()
                for (var j = 0; j < inventory.length; j++) {
                    rows.push({
                        c1: inventory[j].id || "",
                        c2: inventory[j].part || "",
                        c3: inventory[j].lot || "",
                        c4: String(inventory[j].qty || 0),
                        c5: inventory[j].updatedAt || "",
                        c6: ""
                    })
                }
            }

            allRows = rows
            applyRows()
        }

        function filteredRows() {
            if (!searchText)
                return allRows

            var rows = []
            for (var i = 0; i < allRows.length; i++) {
                var text = [
                    allRows[i].c1,
                    allRows[i].c2,
                    allRows[i].c3,
                    allRows[i].c4,
                    allRows[i].c5,
                    allRows[i].c6
                ].join(" ").toLowerCase()

                if (text.indexOf(searchText) !== -1)
                    rows.push(allRows[i])
            }
            return rows
        }

        function applyRows() {
            reportsModel.clear()

            var rows = filteredRows()
            var totalPages = Math.max(1, Math.ceil(rows.length / pageSize))
            page = Math.min(page, totalPages)

            var start = (page - 1) * pageSize
            var end = Math.min(start + pageSize, rows.length)

            for (var i = start; i < end; i++)
                reportsModel.append(rows[i])

            pageInfo = "Page " + page + " of " + totalPages
        }
    }

    Connections {
        target: dbNotifier
        function onDatabaseChanged() {
            reportsVM.loadRows()
        }
    }

    Component.onCompleted: reportsVM.loadRows()

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
                color: "#ffffff"
                border.color: "#dbe3ea"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 18

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: "Reports"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#14213d"
                        }

                        Label {
                            text: "Browse recent store transactions and stock movements."
                            color: "#64748b"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        radius: 14
                        color: "#f8fafc"
                        border.color: "#dbe3ea"
                        implicitWidth: 210
                        implicitHeight: 56

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: reportsVM.activeTab === "store" ? "Store Feed" : "Stock Feed"
                                font.bold: true
                                color: "#0f172a"
                            }

                            Text {
                                text: reportsVM.pageInfo
                                color: "#64748b"
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18

                Rectangle {
                    Layout.preferredWidth: 250
                    Layout.fillHeight: true
                    radius: 18
                    color: "#14213d"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        Label {
                            text: "Views"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Button {
                            id: storeHistoryButton
                            text: "Store History"
                            Layout.fillWidth: true
                            onClicked: reportsVM.showStoreHistory()
                            background: Rectangle {
                                radius: 10
                                color: reportsVM.activeTab === "store" ? "#3b82f6" : "#1e2f52"
                            }
                            contentItem: Text {
                                text: storeHistoryButton.text
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            id: stockHistoryButton
                            text: "Stock History"
                            Layout.fillWidth: true
                            onClicked: reportsVM.showStockHistory()
                            background: Rectangle {
                                radius: 10
                                color: reportsVM.activeTab === "stock" ? "#3b82f6" : "#1e2f52"
                            }
                            contentItem: Text {
                                text: stockHistoryButton.text
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        TextField {
                            placeholderText: "Search records"
                            Layout.preferredWidth: 320
                            onTextChanged: reportsVM.search(text)
                        }

                        ComboBox {
                            model: ["10", "25", "50", "100"]
                            currentIndex: 1
                            onCurrentTextChanged: reportsVM.setPageSize(currentText)
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "Download CSV"
                            onClicked: reportsVM.download()
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
                            spacing: 0

                            ReportRow {
                                Layout.fillWidth: true
                                isHeader: true
                                c1: reportsVM.activeTab === "store" ? "Item Id" : "Unique Id"
                                c2: "Part"
                                c3: reportsVM.activeTab === "store" ? "Work Order" : "Lot"
                                c4: reportsVM.activeTab === "store" ? "Type" : "Qty"
                                c5: reportsVM.activeTab === "store" ? "Qty" : "Updated"
                                c6: reportsVM.activeTab === "store" ? "Time" : ""
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 6
                                model: reportsModel

                                delegate: ReportRow {
                                    width: ListView.view ? ListView.view.width : 0
                                    c1: model.c1
                                    c2: model.c2
                                    c3: model.c3
                                    c4: model.c4
                                    c5: model.c5
                                    c6: model.c6
                                    shade: index % 2 === 0
                                }
                            }

                            Label {
                                text: "No records found"
                                visible: reportsModel.count === 0
                                color: "#64748b"
                                Layout.alignment: Qt.AlignHCenter
                                padding: 18
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: "Prev"
                            onClicked: reportsVM.prevPage()
                        }

                        Label { text: reportsVM.pageInfo }

                        Button {
                            text: "Next"
                            onClicked: reportsVM.nextPage()
                        }
                    }
                }
            }
        }
    }

    component ReportRow: Rectangle {
        property bool isHeader: false
        property bool shade: false
        property string c1: ""
        property string c2: ""
        property string c3: ""
        property string c4: ""
        property string c5: ""
        property string c6: ""

        height: isHeader ? 46 : 44
        radius: 12
        color: isHeader ? "#eef4fb" : shade ? "#f8fafc" : "white"
        border.color: "#e2e8f0"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text { text: c1; font.bold: isHeader; Layout.preferredWidth: 180; elide: Text.ElideRight }
            Text { text: c2; font.bold: isHeader; Layout.preferredWidth: 160; elide: Text.ElideRight }
            Text { text: c3; font.bold: isHeader; Layout.preferredWidth: 140; elide: Text.ElideRight }
            Text { text: c4; font.bold: isHeader; Layout.preferredWidth: 90; elide: Text.ElideRight }
            Text { text: c5; font.bold: isHeader; Layout.preferredWidth: 130; elide: Text.ElideRight }
            Text { text: c6; font.bold: isHeader; Layout.fillWidth: true; elide: Text.ElideRight }
        }
    }
}
