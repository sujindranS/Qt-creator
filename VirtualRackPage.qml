import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Virtual Rack"

    property var stackViewRef
    property int selectedRow: -1
    property int selectedSlot: -1
    property string currentSide: "A"

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
                            text: "Virtual Rack"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#14213d"
                        }

                        Label {
                            text: "Inspect slot layout and preview rack occupancy by side."
                            color: "#64748b"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ComboBox {
                        Layout.preferredWidth: 180
                        model: ["S001", "S002", "S003"]
                    }

                    Button {
                        text: currentSide === "A" ? "Side A" : "Side B"
                        onClicked: currentSide = currentSide === "A" ? "B" : "A"
                    }
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
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Rack Surface"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#0f172a"
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: selectedRow >= 0 ? "Row " + (selectedRow + 1) + " / Slot " + (selectedSlot + 1) : "Select a slot"
                            color: "#64748b"
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: rackColumn.height
                        clip: true

                        Column {
                            id: rackColumn
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: 4

                                delegate: Flickable {
                                    id: rowFlick
                                    width: parent.width
                                    height: 74
                                    contentWidth: rowContent.width
                                    clip: true
                                    property int rowIndex: index

                                    Row {
                                        id: rowContent
                                        spacing: 6

                                        Rectangle {
                                            width: 84
                                            height: 64
                                            radius: 14
                                            color: "#f8fafc"
                                            border.color: "#dbe3ea"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Row " + (rowIndex + 1)
                                                font.bold: true
                                                color: "#334155"
                                            }
                                        }

                                        Repeater {
                                            model: 40

                                            delegate: Rectangle {
                                                width: 38
                                                height: 64
                                                radius: 12
                                                property int slotIndex: index
                                                color: (selectedRow === rowIndex && selectedSlot === slotIndex) ? "#2563eb" : "#f8fafc"
                                                border.color: (selectedRow === rowIndex && selectedSlot === slotIndex) ? "#2563eb" : "#dbe3ea"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: slotIndex + 1
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: (selectedRow === rowIndex && selectedSlot === slotIndex) ? "white" : "#334155"
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        selectedRow = rowIndex
                                                        selectedSlot = slotIndex
                                                        slotPopup.open()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: slotPopup
        width: 260
        height: 170
        modal: true
        focus: true
        anchors.centerIn: parent

        background: Rectangle {
            radius: 18
            color: "white"
            border.color: "#dbe3ea"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 8

            Label {
                text: "Slot Details"
                font.bold: true
                font.pixelSize: 18
            }

            Label { text: "Side: " + currentSide }
            Label { text: "Row: " + (selectedRow + 1) }
            Label { text: "Slot: " + (selectedSlot + 1) }

            Item { Layout.fillHeight: true }

            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: slotPopup.close()
            }
        }
    }
}
