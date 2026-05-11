import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    title: "Administration"

    property var stackViewRef
    property var appToast
    property string logoPath: ""

    Component.onCompleted: {
        var data = dbManager.loadCompany()
        companyName.text = data.name || ""
        phoneField.text = data.phone || ""
        gstField.text = data.gst || ""
        cinField.text = data.cin || ""
        addressField.text = data.address || ""
        pinField.text = data.pin || ""
    }

    function saveCompanyProfile() {
        if (!companyName.text.trim() || !addressField.text.trim() || !pinField.text.trim()) {
            appToast.show("Company name, address, and pin are required.", "warn")
            return
        }

        dbManager.saveCompany(
                    companyName.text,
                    phoneField.text,
                    gstField.text,
                    cinField.text,
                    addressField.text,
                    pinField.text)
        appToast.show("Company profile saved.", "success")
    }

    RowLayout {
        anchors.fill: parent

        Rectangle {
            width: 220
            color: "#1e293b"

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 20

                Text {
                    text: "Administration"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: "#3b82f6"

                    Text {
                        anchors.centerIn: parent
                        text: "Company Profile"
                        color: "white"
                        font.bold: true
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#f4f6f9"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Company Profile"
                        font.pixelSize: 26
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Save"
                        onClicked: saveCompanyProfile()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: "white"
                    border.color: "#e5e7eb"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 44

                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: 12

                            Rectangle {
                                width: 220
                                height: 220
                                radius: 12
                                color: "#f1f5f9"
                                border.color: "#cbd5e1"

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    source: logoPath
                                    fillMode: Image.PreserveAspectFit
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: fileDialog.open()
                                }
                            }

                            Text {
                                text: logoPath ? "Logo selected" : "Upload company logo"
                                color: "#64748b"
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            columns: 2
                            rowSpacing: 18
                            columnSpacing: 24

                            Column {
                                spacing: 6
                                Text { text: "Company Name *" }
                                TextField {
                                    id: companyName
                                    width: 280
                                    placeholderText: "Enter company name"
                                }
                            }

                            Column {
                                spacing: 6
                                Text { text: "Phone" }
                                TextField {
                                    id: phoneField
                                    width: 280
                                    placeholderText: "Enter phone number"
                                }
                            }

                            Column {
                                spacing: 6
                                Text { text: "GST" }
                                TextField {
                                    id: gstField
                                    width: 280
                                }
                            }

                            Column {
                                spacing: 6
                                Text { text: "CIN" }
                                TextField {
                                    id: cinField
                                    width: 280
                                }
                            }

                            Column {
                                spacing: 6
                                Text { text: "Address *" }
                                TextField {
                                    id: addressField
                                    width: 280
                                    placeholderText: "Enter address"
                                }
                            }

                            Column {
                                spacing: 6
                                Text { text: "Pin *" }
                                TextField {
                                    id: pinField
                                    width: 280
                                    placeholderText: "Enter pin code"
                                }
                            }
                        }
                    }
                }

            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select Logo"
        nameFilters: ["Images (*.png *.jpg *.jpeg)"]
        onAccepted: logoPath = selectedFile
    }
}
