import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: navbar
    Layout.fillWidth: true
    Layout.preferredHeight: 72
    color: "white"
    border.color: "#dbe3ea"

    signal refreshClicked()
    signal logoClicked()
    signal warningClicked()
    signal clearAllWarningsClicked()

    property int warningCount: 0
    property bool loggedIn: false

    Timer {
        interval: 1000
        running: navbar.loggedIn
        repeat: true
        onTriggered: navbar.warningCount = databaseVM.getWarnings().length
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 18

        Item {
            Layout.preferredWidth: brandRow.implicitWidth
            Layout.preferredHeight: 42

            RowLayout {
                id: brandRow
                anchors.fill: parent
                spacing: 12

                Image {
                    source: "qrc:/assets/icons/logo.png"
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 230
                    sourceSize.height: 40
                    Layout.preferredWidth: 230
                    Layout.preferredHeight: 40
                }

                Text {
                    // text: "REXSATRONIX"
                    color: "#123a63"
                    font.pixelSize: 20
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: navbar.logoClicked()
            }
        }

        Item { Layout.fillWidth: true }

        Button {
            id: refreshButton
            visible: navbar.loggedIn
            hoverEnabled: true
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44

            background: Rectangle {
                radius: 22
                color: refreshButton.down ? "#dbeafe" : (refreshButton.hovered ? "#eff6ff" : "#f8fafc")
                border.color: refreshButton.hovered ? "#60a5fa" : "#cbd5e1"
            }

            contentItem: Item {
                Image {
                    id: refreshIcon
                    anchors.centerIn: parent
                    source: "qrc:/assets/icons/clock.png"
                    width: 22
                    height: 22
                    fillMode: Image.PreserveAspectFit
                    rotation: refreshButton.down ? 180 : 0
                    scale: refreshButton.hovered ? 1.08 : 1.0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            onClicked: navbar.refreshClicked()
        }

        Item {
            visible: navbar.loggedIn
            Layout.preferredWidth: visible ? 40 : 0
            Layout.preferredHeight: visible ? 40 : 0

            Button {
                id: warningButton
                anchors.fill: parent
                background: Rectangle {
                    radius: 20
                    color: warningButton.down ? "#e2e8f0" : "#f8fafc"
                    border.color: "#cbd5e1"
                }

                contentItem: Item {
                    Image {
                        id: warningIcon
                        anchors.centerIn: parent
                        source: "qrc:/assets/icons/warning.png"
                        width: 50
                        height: 22
                        fillMode: Image.PreserveAspectFit
                        scale: warningPulse.running ? 1.12 : 1.0
                        rotation: warningPulse.running ? 6 : 0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }

                onClicked: {
                    warningBounce.restart()
                    navbar.warningClicked()
                }
            }

            SequentialAnimation {
                id: warningPulse
                running: navbar.loggedIn && navbar.warningCount > 0
                loops: Animation.Infinite

                NumberAnimation {
                    target: warningIcon
                    property: "scale"
                    to: 1.14
                    duration: 420
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: warningIcon
                    property: "scale"
                    to: 1.0
                    duration: 420
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                id: warningBounce
                NumberAnimation {
                    target: warningIcon
                    property: "rotation"
                    to: -10
                    duration: 90
                }
                NumberAnimation {
                    target: warningIcon
                    property: "rotation"
                    to: 10
                    duration: 120
                }
                NumberAnimation {
                    target: warningIcon
                    property: "rotation"
                    to: 0
                    duration: 90
                }
            }

            Rectangle {
                visible: navbar.warningCount > 0
                width: 20
                height: 20
                radius: 10
                color: "#d32f2f"
                anchors.right: parent.right
                anchors.top: parent.top

                Text {
                    anchors.centerIn: parent
                    text: navbar.warningCount > 99 ? "99+" : navbar.warningCount
                    color: "white"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }

        Button {
            id: clearWarningsButton
            visible: navbar.loggedIn && navbar.warningCount > 0
            text: "Clear Warnings"

            background: Rectangle {
                color: "#d9534f"
                radius: 6
            }

            contentItem: Text {
                text: clearWarningsButton.text
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: navbar.clearAllWarningsClicked()
        }
    }
}
