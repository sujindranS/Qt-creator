import QtQuick
import QtQuick.Controls

Popup {
    id: toast
    parent: Overlay.overlay
    modal: false
    focus: false
    closePolicy: Popup.NoAutoClose
    padding: 0

    property color bgColor: "#2ecc71"
    property string message: ""

    x: parent ? parent.width - width - 24 : 0
    y: 24

    width: Math.min(parent ? parent.width * 0.35 : 420, 420)
    height: 56

    background: Rectangle {
        radius: 10
        color: toast.bgColor
        opacity: 0.96
        border.color: Qt.darker(toast.bgColor, 1.15)
    }

    contentItem: Text {
        text: toast.message
        color: "white"
        font.bold: true
        font.pixelSize: 15
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        leftPadding: 16
        rightPadding: 16
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 180
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: 180
        }
    }

    function show(msg, type) {
        message = msg
        bgColor = type === "error" ? "#e74c3c"
                 : type === "warn" ? "#f39c12"
                 : "#2ecc71"

        open()
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2200
        onTriggered: toast.close()
    }
}
