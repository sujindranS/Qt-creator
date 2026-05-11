import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Warnings"

    property var stackViewRef
    property var appToast
    property bool anySelected: false

    ListModel {
        id: warningModel
    }

    QtObject {
        id: warningVM

        property string searchText: ""
        property int page: 1
        property int pageSize: 25
        property string pageInfo: "Page 1 of 1"
        property var allRows: []

        function loadWarnings() {
            var rows = []
            var data = databaseVM.getWarnings()

            for (var i = 0; i < data.length; i++) {
                rows.push({
                    uid: data[i].uid || "",
                    part: data[i].part || "",
                    lot: data[i].lot || "",
                    qty: String(data[i].qty || 0),
                    createdOn: data[i].createdOn || "",
                    checked: false
                })
            }

            allRows = rows
            page = 1
            applyFilter()
        }

        function filter(text) {
            searchText = (text || "").toLowerCase().trim()
            page = 1
            applyFilter()
        }

        function filteredRows() {
            if (!searchText)
                return allRows

            var rows = []
            for (var i = 0; i < allRows.length; i++) {
                var rowText = [
                    allRows[i].uid,
                    allRows[i].part,
                    allRows[i].lot,
                    allRows[i].qty,
                    allRows[i].createdOn
                ].join(" ").toLowerCase()

                if (rowText.indexOf(searchText) !== -1)
                    rows.push(allRows[i])
            }

            return rows
        }

        function applyFilter() {
            warningModel.clear()

            var rows = filteredRows()
            var totalPages = Math.max(1, Math.ceil(rows.length / pageSize))
            page = Math.min(page, totalPages)

            var start = (page - 1) * pageSize
            var end = Math.min(start + pageSize, rows.length)

            for (var i = start; i < end; i++)
                warningModel.append(rows[i])

            pageInfo = "Page " + page + " of " + totalPages
            updateSelectionState()
        }

        function selectAll(checked) {
            for (var i = 0; i < warningModel.count; i++)
                warningModel.setProperty(i, "checked", checked)

            updateSelectionState()
        }

        function toggle(uid, checked) {
            for (var i = 0; i < warningModel.count; i++) {
                if (warningModel.get(i).uid === uid) {
                    warningModel.setProperty(i, "checked", checked)
                    break
                }
            }

            updateSelectionState()
        }

        function updateSelectionState() {
            root.anySelected = false
            for (var i = 0; i < warningModel.count; i++) {
                if (warningModel.get(i).checked) {
                    root.anySelected = true
                    return
                }
            }
        }

        function removeSelected() {
            var removed = 0

            for (var i = warningModel.count - 1; i >= 0; i--) {
                var row = warningModel.get(i)
                if (!row.checked)
                    continue

                databaseVM.deleteWarning(row.uid)
                removed++
            }

            if (removed > 0) {
                showToast("Warning cleared")
                loadWarnings()
            }
        }

        function prevPage() {
            if (page > 1) {
                page--
                applyFilter()
            }
        }

        function nextPage() {
            var totalPages = Math.max(1, Math.ceil(filteredRows().length / pageSize))
            if (page < totalPages) {
                page++
                applyFilter()
            }
        }
    }

    function showToast(message) {
        if (appToast) {
            appToast.show(message, "success")
            return
        }

        toastText.text = message
        toast.visible = true
        toast.opacity = 1
        toastTimer.restart()
    }

    Connections {
        target: dbNotifier
        function onDatabaseChanged() {
            warningVM.loadWarnings()
        }
    }

    Component.onCompleted: warningVM.loadWarnings()

    Dialog {
        id: confirmDialog
        modal: true
        width: 350
        anchors.centerIn: parent

        property string message: ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Label {
                text: confirmDialog.message
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    onClicked: confirmDialog.close()
                }

                Button {
                    text: "Yes"
                    Layout.fillWidth: true
                    onClicked: {
                        confirmDialog.close()
                        warningVM.removeSelected()
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#f4f6f8"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Warnings"
                    font.pixelSize: 24
                    font.bold: true
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "Search:"
                }

                TextField {
                    placeholderText: "Enter Unique ID..."
                    Layout.preferredWidth: 300
                    onTextChanged: warningVM.filter(text)
                }

                Item {
                    Layout.fillWidth: true
                }

                CheckBox {
                    id: selectAllBox
                    text: "Select All"
                    onCheckedChanged: warningVM.selectAll(checked)
                }

                Button {
                    id: removeButton
                    text: "Remove"
                    enabled: root.anySelected
                    onClicked: {
                        if (!root.anySelected) {
                            showToast("Select at least one record")
                            return
                        }

                        confirmDialog.message = "Are you sure you want to clear the warning?"
                        confirmDialog.open()
                    }

                    background: Rectangle {
                        color: removeButton.enabled ? "#d9534f" : "#cccccc"
                        radius: 8
                    }

                    contentItem: Text {
                        text: removeButton.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                radius: 10
                border.color: "#e5e7eb"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 0

                    WarningRow {
                        Layout.fillWidth: true
                        isHeader: true
                        uid: "Unique ID"
                        part: "Part"
                        lot: "Lot"
                        qty: "Qty"
                        createdOn: "Created On"
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: warningModel

                        delegate: WarningRow {
                            width: ListView.view ? ListView.view.width : 0
                            checked: model.checked
                            uid: model.uid
                            part: model.part
                            lot: model.lot
                            qty: model.qty
                            createdOn: model.createdOn
                            shade: index % 2 === 0
                            onToggled: function(value) {
                                warningVM.toggle(uid, value)
                            }
                        }
                    }

                    Label {
                        text: "No warning records found"
                        visible: warningModel.count === 0
                        color: "gray"
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
                    onClicked: warningVM.prevPage()
                }

                Label {
                    text: warningVM.pageInfo
                }

                Button {
                    text: "Next"
                    onClicked: warningVM.nextPage()
                }
            }
        }

        Rectangle {
            id: toast
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            color: "#323232"
            radius: 8
            opacity: 0
            width: toastText.implicitWidth + 24
            height: toastText.implicitHeight + 24

            Text {
                id: toastText
                anchors.centerIn: parent
                color: "white"
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Timer {
                id: toastTimer
                interval: 2000
                repeat: false
                onTriggered: {
                    toast.opacity = 0
                    toast.visible = false
                }
            }
        }
    }

    component WarningRow: Rectangle {
        id: rowRoot

        property bool isHeader: false
        property bool checked: false
        property bool shade: false
        property string uid: ""
        property string part: ""
        property string lot: ""
        property string qty: ""
        property string createdOn: ""

        signal toggled(bool checked)

        height: isHeader ? 44 : 45
        color: isHeader ? "#eef2f7" : shade ? "#f9fafb" : "white"
        border.color: "#eeeeee"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            CheckBox {
                visible: !rowRoot.isHeader
                checked: rowRoot.checked
                Layout.preferredWidth: 42
                onCheckedChanged: rowRoot.toggled(checked)
            }

            Text {
                visible: rowRoot.isHeader
                text: ""
                Layout.preferredWidth: 42
            }

            Text { text: rowRoot.uid; font.bold: rowRoot.isHeader; Layout.preferredWidth: 190; elide: Text.ElideRight }
            Text { text: rowRoot.part; font.bold: rowRoot.isHeader; Layout.preferredWidth: 180; elide: Text.ElideRight }
            Text { text: rowRoot.lot; font.bold: rowRoot.isHeader; Layout.preferredWidth: 140; elide: Text.ElideRight }
            Text { text: rowRoot.qty; font.bold: rowRoot.isHeader; Layout.preferredWidth: 80; elide: Text.ElideRight }
            Text { text: rowRoot.createdOn; font.bold: rowRoot.isHeader; Layout.fillWidth: true; elide: Text.ElideRight }
        }
    }
}
