import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 220
    height: 150

    signal clicked()

    property bool hovered: false
    property bool pressed: false
    property string title: ""
    property url iconSource: ""

    Rectangle {
        id: shadow
        x: root.hovered ? 6 : 3
        y: root.hovered ? 6 : 3
        width: card.width
        height: card.height
        radius: card.radius + 6
        color: "#22000000"
        opacity: root.hovered ? 0.55 : 0.3

        Behavior on x { NumberAnimation { duration: 180 } }
        Behavior on y { NumberAnimation { duration: 180 } }
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: "white"
        border.color: "#e5e7eb"
        scale: root.pressed ? 0.97 : (root.hovered ? 1.03 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: ripple
            width: 10
            height: 10
            radius: width / 2
            color: "#220078D7"
            opacity: 0
            visible: opacity > 0
            anchors.centerIn: parent
            scale: 0

            Behavior on scale { NumberAnimation { duration: 300 } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Column {
            anchors.centerIn: parent
            spacing: 14

            Image {
                source: root.iconSource
                width: 52
                height: 52
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                text: root.title
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.hovered = true
            onExited: root.hovered = false
            onPressed: root.pressed = true
            onReleased: root.pressed = false
            onCanceled: root.pressed = false
            onClicked: {
                root.clicked()
                ripple.opacity = 0.4
                ripple.scale = 6
                rippleResetTimer.restart()
            }
        }
    }

    Timer {
        id: rippleResetTimer
        interval: 300
        repeat: false
        onTriggered: {
            ripple.opacity = 0
            ripple.scale = 0
        }
    }
}
