import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Settings"

    property var stackViewRef
    property var appToast
    property bool hasChanges: false

    Component.onCompleted: {
        var data = dbManager.loadRackDetails()
        if (data.logicalName !== undefined && data.logicalName !== "")
            settingsVM.logicalName = data.logicalName
        if (data.rackId !== undefined && data.rackId !== "")
            settingsVM.rackId = String(data.rackId)
        if (data.nodeCount !== undefined && data.nodeCount !== "")
            settingsVM.nodeCount = String(data.nodeCount)
        if (data.slotCount !== undefined && data.slotCount !== "")
            settingsVM.slotCount = String(data.slotCount)
        root.hasChanges = false
    }

    QtObject {
        id: settingsVM

        property bool editMode: false
        property string logicalName: "Smart Rack"
        property string rackId: "1"
        property string nodeCount: "1"
        property string slotCount: "80"
        property bool isValid: rackId.length > 0
                               && nodeCount.length > 0
                               && slotCount.length > 0
                               && Number(rackId) >= 0
                               && Number(nodeCount) >= 1
                               && Number(slotCount) >= 1

        function auditRack() {
            var ok = false

            if (typeof rackManager !== "undefined")
                ok = rackManager.init()

            if (root.appToast)
                root.appToast.show(ok ? "Rack audit started." : "Rack audit is not available.",
                                   ok ? "success" : "warn")
        }

        function save() {
            if (dbManager.saveRackDetails(logicalName,
                                          rackId,
                                          Number(nodeCount),
                                          Number(slotCount))) {
                editMode = false
                if (root.appToast)
                    root.appToast.show("Smart rack configuration saved.", "success")
            } else if (root.appToast) {
                root.appToast.show(dbManager.lastError || "Unable to save rack settings.", "error")
            }
        }
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
                Layout.preferredHeight: 112
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
                            text: "Settings"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#14213d"
                        }

                        Label {
                            text: "Configure the smart rack identity, node layout, and slot capacity."
                            color: "#64748b"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Audit Rack"
                        onClicked: settingsVM.auditRack()
                    }

                    Button {
                        text: settingsVM.editMode ? "Save" : "Edit"
                        enabled: settingsVM.editMode ? root.hasChanges && settingsVM.isValid : true
                        onClicked: {
                            if (!settingsVM.editMode) {
                                settingsVM.editMode = true
                            } else {
                                settingsVM.save()
                                root.hasChanges = false
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
                    Layout.preferredWidth: 280
                    Layout.fillHeight: true
                    radius: 18
                    color: "#14213d"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        Label {
                            text: "Rack Summary"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        SummaryChip { label: "Logical Name"; value: settingsVM.logicalName }
                        SummaryChip { label: "Rack Id"; value: settingsVM.rackId }
                        SummaryChip { label: "Nodes"; value: settingsVM.nodeCount }
                        SummaryChip { label: "Slots"; value: settingsVM.slotCount }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: "white"
                    border.color: "#dbe3ea"

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        columns: 2
                        rowSpacing: 18
                        columnSpacing: 18

                        SettingField {
                            label: "Logical Name"
                            value: settingsVM.logicalName
                            editable: settingsVM.editMode
                            onValueEdited: function(text) {
                                settingsVM.logicalName = text
                                root.hasChanges = true
                            }
                        }

                        SettingField {
                            label: "Rack ID"
                            value: settingsVM.rackId
                            editable: settingsVM.editMode
                            numericOnly: true
                            onValueEdited: function(text) {
                                settingsVM.rackId = text
                                root.hasChanges = true
                            }
                        }

                        SettingField {
                            label: "Node Count"
                            value: settingsVM.nodeCount
                            editable: settingsVM.editMode
                            numericOnly: true
                            onValueEdited: function(text) {
                                settingsVM.nodeCount = text
                                root.hasChanges = true
                            }
                        }

                        SettingField {
                            label: "Slot Count"
                            value: settingsVM.slotCount
                            editable: settingsVM.editMode
                            numericOnly: true
                            onValueEdited: function(text) {
                                settingsVM.slotCount = text
                                root.hasChanges = true
                            }
                        }

                        Label {
                            Layout.columnSpan: 2
                            visible: !settingsVM.isValid
                            text: "Please enter valid numeric values."
                            color: "#dc2626"
                        }
                    }
                }
            }
        }
    }

    component SummaryChip: Rectangle {
        id: summaryChip
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        radius: 12
        color: "#1f335c"
        implicitHeight: 62

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: summaryChip.label
                color: "#93c5fd"
                font.pixelSize: 12
            }

            Text {
                text: summaryChip.value
                color: "white"
                font.bold: true
            }
        }
    }

    component SettingField: ColumnLayout {
        property string label: ""
        property string value: ""
        property bool editable: false
        property bool numericOnly: false
        signal valueEdited(string text)

        Layout.fillWidth: true
        spacing: 6

        Label {
            text: parent.label
            color: "#334155"
            font.bold: true
        }

        TextField {
            id: field
            Layout.fillWidth: true
            text: parent.value
            readOnly: !parent.editable
            inputMethodHints: parent.numericOnly ? Qt.ImhDigitsOnly : Qt.ImhNone
            onTextEdited: parent.valueEdited(text)

            background: Rectangle {
                radius: 10
                color: field.readOnly ? "#f8fafc" : "white"
                border.color: "#dbe3ea"
            }
        }
    }
}
