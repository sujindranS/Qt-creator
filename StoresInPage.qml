import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Stores In"

    property var stackViewRef

    ListModel { id: recentModel }
    ListModel { id: binModel }

    Rectangle {
        anchors.fill: parent
        color: "#eef2f7"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                radius: 12
                color: "#ffffff"
                border.color: "#e5e7eb"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: "Stores In"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    TextField {
                        id: scanInput
                        Layout.fillWidth: true
                        Layout.minimumWidth: 120
                        height: 40
                        placeholderText: "Scan Slot / Bin / Part"
                        font.pixelSize: 14

                        background: Rectangle {
                            radius: 6
                            border.color: "#d1d5db"
                            color: "#f9fafb"
                        }

                        onAccepted: inBtn.clicked()
                    }

                    Button {
                        id: inBtn
                        text: "IN"
                        Layout.preferredWidth: 80
                        height: 40

                        background: Rectangle {
                            color: "#2563eb"
                            radius: 6
                        }

                        contentItem: Text {
                            text: "IN"
                            color: "white"
                            anchors.centerIn: parent
                            font.bold: true
                        }

                        onClicked: {
                            if (scanInput.text === "")
                                return

                            recentModel.insert(0, {
                                uid: scanInput.text,
                                rack: "RACKRM1-RK14",
                                part: "PART"
                            })

                            var found = false
                            for (var i = 0; i < binModel.count; i++) {
                                if (binModel.get(i).bin === scanInput.text) {
                                    binModel.setProperty(i, "count", binModel.get(i).count + 1)
                                    found = true
                                    break
                                }
                            }

                            if (!found) {
                                binModel.append({
                                    bin: scanInput.text,
                                    count: 1
                                })
                            }

                            scanInput.text = ""
                        }
                    }

                    Button {
                        text: "CLEAR"
                        Layout.preferredWidth: 86
                        height: 40

                        background: Rectangle {
                            color: "#ef4444"
                            radius: 6
                        }

                        contentItem: Text {
                            text: "CLEAR"
                            color: "white"
                            anchors.centerIn: parent
                            font.bold: true
                        }

                        onClicked: scanInput.text = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 3
                    radius: 10
                    color: "#ffffff"
                    border.color: "#e5e7eb"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Unmapped Bins"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#111827"
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Row {
                                width: parent.width
                                height: 40

                                Repeater {
                                    model: ["#", "Bin Id", "Parts Count"]

                                    delegate: Rectangle {
                                        width: parent.width / 3
                                        height: 40
                                        color: "#f3f4f6"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.bold: true
                                            color: "#374151"
                                        }
                                    }
                                }
                            }

                            ListView {
                                width: parent.width
                                height: parent.height - 40
                                model: binModel
                                clip: true
                                spacing: 1

                                delegate: Row {
                                    width: ListView.view.width
                                    height: 38

                                    Rectangle {
                                        width: parent.width / 3
                                        height: 38
                                        color: index % 2 === 0 ? "#ffffff" : "#f9fafb"
                                        Text { anchors.centerIn: parent; text: index + 1 }
                                    }

                                    Rectangle {
                                        width: parent.width / 3
                                        height: 38
                                        color: index % 2 === 0 ? "#ffffff" : "#f9fafb"
                                        Text { anchors.centerIn: parent; text: bin }
                                    }

                                    Rectangle {
                                        width: parent.width / 3
                                        height: 38
                                        color: index % 2 === 0 ? "#ffffff" : "#f9fafb"
                                        Text { anchors.centerIn: parent; text: count }
                                    }
                                }

                                Text {
                                    text: "No Data Found"
                                    visible: binModel.count === 0
                                    anchors.centerIn: parent
                                    color: "#9ca3af"
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Rows: " + binModel.count; color: "#6b7280" }
                            Item { Layout.fillWidth: true }
                            Text { text: "Total: " + binModel.count; color: "#6b7280" }
                        }
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 250
                    radius: 10
                    color: "#ffffff"
                    border.color: "#e5e7eb"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Recently Scanned"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#111827"
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: recentModel
                            spacing: 8
                            clip: true

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 70
                                radius: 8
                                color: "#f9fafb"
                                border.color: "#e5e7eb"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2

                                    Text { text: "ID: " + uid; font.bold: true }
                                    Text { text: "Rack: " + rack; color: "#4b5563" }
                                    Text { text: "Part: " + part; color: "#4b5563" }
                                }
                            }
                        }

                        Text {
                            visible: recentModel.count === 0
                            text: "No scans yet"
                            color: "#9ca3af"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
