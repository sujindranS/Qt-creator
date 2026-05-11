import QtQuick
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 999

    function show() {
        root.visible = true
    }

    function hide() {
        root.visible = false
    }

    // 🔳 Transparent dark background
    Rectangle {
        anchors.fill: parent
        color: "#80000000"   // semi-transparent black
    }

    // 🎞️ Loading GIF
    Image {
        anchors.centerIn: parent
        source: "qrc:/assets/icons/loading.gif"
        width: 80
        height: 80
        fillMode: Image.PreserveAspectFit
    }
}
