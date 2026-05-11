import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    title: "Login"

    signal loginSucceeded()

    property bool triedLogin: false

    Connections {
        target: loginVM

        function onLoginSuccess() {
            toast.show("Login successful", true)
            loginDelay.start()
        }

        function onLoginFailed(message) {
            toast.show(message)
        }
    }

    Timer {
        id: loginDelay
        interval: 350
        repeat: false
        onTriggered: root.loginSucceeded()
    }

    Rectangle {
        anchors.fill: parent
        color: "#f4f6f8"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 28
            width: 400

            Image {
                source: "qrc:/assets/icons/logo.png"
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 220
                Layout.preferredHeight: 160
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                // text: "Rexsatronix"
                font.pixelSize: 28
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true

                TextField {
                    id: username
                    placeholderText: "Username"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    focus: true

                    background: Rectangle {
                        radius: 6
                        border.color: username.text === "" && root.triedLogin ? "red" : "#cccccc"
                        color: "white"
                    }

                    onAccepted: loginBtn.clicked()
                }

                TextField {
                    id: password
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45

                    background: Rectangle {
                        radius: 6
                        border.color: password.text === "" && root.triedLogin ? "red" : "#cccccc"
                        color: "white"
                    }

                    onAccepted: loginBtn.clicked()
                }

                Button {
                    id: loginBtn
                    text: "Login"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50

                    background: Rectangle {
                        color: "#1976d2"
                        radius: 8
                    }

                    contentItem: Text {
                        text: loginBtn.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                    }

                    onClicked: {
                        root.triedLogin = true

                        if (username.text === "" || password.text === "") {
                            toast.show("Please enter username & password")
                            return
                        }

                        loginVM.login(username.text, password.text)
                    }
                }
            }
        }

        Rectangle {
            id: toast
            visible: false
            opacity: 0
            radius: 8
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            width: toastText.implicitWidth + 24
            height: toastText.implicitHeight + 24

            Text {
                id: toastText
                anchors.centerIn: parent
                color: "white"
            }

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }

            function show(msg, success) {
                toastText.text = msg
                toast.color = success ? "#2e7d32" : "#c62828"
                visible = true
                opacity = 1
                toastTimer.restart()
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
}
