import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 1400
    height: 800
    minimumWidth: 1100
    minimumHeight: 680
    title: "REXSATRONIX"

    Material.theme: Material.Light
    Material.accent: Material.Blue
    Material.primary: Material.BlueGrey

    property alias toast: appToast
    property bool loggedIn: false
    property string currentPageKey: "dashboard"

    function pageProps(pageSource) {
        var props = {}
        var pagesWithStack = [
            "AdministrationPage.qml",
            "ReelsInPage.qml",
            "PickupPage.qml",
            "ReportPage.qml",
            "WarningsPage.qml",
            "StoresInPage.qml",
            "StoreoutPage.qml",
            "VirtualRackPage.qml",
            "SettingsPage.qml"
        ]
        var pagesWithToast = [
            "AdministrationPage.qml",
            "ReelsInPage.qml",
            "PickupPage.qml",
            "ReportPage.qml",
            "WarningsPage.qml",
            "StoreoutPage.qml",
            "SettingsPage.qml"
        ]

        if (pagesWithStack.indexOf(pageSource) !== -1)
            props.stackViewRef = stackView
        if (pagesWithToast.indexOf(pageSource) !== -1)
            props.appToast = appToast

        return props
    }

    function openPage(pageSource, props) {
        currentPageKey = pageSource
        var merged = pageProps(pageSource)
        if (props) {
            for (var key in props)
                merged[key] = props[key]
        }
        stackView.push(pageSource, merged)
    }

    function showLoading() {
        loader.show()
    }

    function hideLoading() {
        loader.hide()
    }

    function navigateHome() {
        if (!window.loggedIn)
            return

        stackView.clear()
        stackView.push(dashboardPage)
        currentPageKey = "dashboard"
    }

    function refreshCurrentPage() {
        if (!window.loggedIn)
            return

        if (currentPageKey === "dashboard") {
            appToast.show("Dashboard is already up to date.", "success")
            return
        }

        var pageToReload = currentPageKey
        stackView.pop()
        openPage(pageToReload)
        appToast.show("Page refreshed.", "success")
    }

    function openWarningsPage() {
        if (!window.loggedIn || currentPageKey === "WarningsPage.qml")
            return

        openPage("WarningsPage.qml")
    }

    function clearAllWarnings() {
        var warnings = databaseVM.getWarnings()
        if (warnings.length === 0) {
            appToast.show("No warnings to clear.", "warn")
            return
        }

        for (var i = 0; i < warnings.length; i++)
            databaseVM.deleteWarning(warnings[i].uid)

        appToast.show("All warnings cleared.", "success")
    }

    Toast { id: appToast }
    LoaderOverlay { id: loader }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Navbar {
            loggedIn: window.loggedIn
            onLogoClicked: window.navigateHome()
            onRefreshClicked: window.refreshCurrentPage()
            onWarningClicked: window.openWarningsPage()
            onClearAllWarningsClicked: window.clearAllWarnings()
        }

        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: loginPage

            onCurrentItemChanged: {
                if (!currentItem) {
                    currentPageKey = "dashboard"
                } else if (currentItem.title === "Warnings") {
                    currentPageKey = "WarningsPage.qml"
                } else if (currentItem.title === "Reports") {
                    currentPageKey = "ReportPage.qml"
                } else if (currentItem.title === "Reels In") {
                    currentPageKey = "ReelsInPage.qml"
                } else if (currentItem.title === "Pick Up") {
                    currentPageKey = "PickupPage.qml"
                } else if (currentItem.title === "Administration") {
                    currentPageKey = "AdministrationPage.qml"
                } else if (currentItem.title === "Settings") {
                    currentPageKey = "SettingsPage.qml"
                } else if (currentItem.title === "Stores Out") {
                    currentPageKey = "StoreoutPage.qml"
                } else if (currentItem.title === "Stores In") {
                    currentPageKey = "StoresInPage.qml"
                } else if (currentItem.title === "Virtual Rack") {
                    currentPageKey = "VirtualRackPage.qml"
                } else if (currentItem.title === "Login") {
                    currentPageKey = "login"
                } else {
                    currentPageKey = "dashboard"
                }
            }
        }

        Footer {
            visible: window.loggedIn
            appVersion: "v1.0.0"
        }
    }

    Component {
        id: loginPage

        LoginPage {
            onLoginSucceeded: {
                window.loggedIn = true
                currentPageKey = "dashboard"
                stackView.replace(dashboardPage)
            }
        }
    }

    Component {
        id: dashboardPage

        Rectangle {
            color: "#ecf0f1"

            Flickable {
                anchors.fill: parent
                anchors.margins: 28
                contentHeight: Math.max(height, cardGrid.implicitHeight + 20)
                clip: true

                GridLayout {
                    id: cardGrid
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 12
                    columns: 4
                    rowSpacing: 30
                    columnSpacing: 30

                    Repeater {
                        model: [
                            { name: "Administration", icon: "qrc:/assets/icons/profile.png", page: "AdministrationPage.qml" },
                            { name: "Reels In", icon: "qrc:/assets/icons/film-reel.png", page: "ReelsInPage.qml" },
                            { name: "Pick Up", icon: "qrc:/assets/icons/package.png", page: "PickupPage.qml" },
                            { name: "Reports", icon: "qrc:/assets/icons/document.png", page: "ReportPage.qml" },
                            { name: "Warnings", icon: "qrc:/assets/icons/warning.png", page: "WarningsPage.qml" },
                            { name: "Stores In", icon: "qrc:/assets/icons/database.png", page: "StoresInPage.qml" },
                            { name: "Stores Out", icon: "qrc:/assets/icons/stores-out.png", page: "StoreoutPage.qml" },
                            { name: "Virtual Rack", icon: "qrc:/assets/icons/visualization.png", page: "VirtualRackPage.qml" },
                            { name: "Settings", icon: "qrc:/assets/icons/settings.png", page: "SettingsPage.qml" }
                        ]

                        delegate: AnimatedDashboardCard {
                            Layout.preferredWidth: 250
                            Layout.preferredHeight: 200
                            width: 250
                            height: 200
                            title: modelData.name
                            iconSource: modelData.icon

                            onClicked: {
                                if (!dbManager.ready) {
                                    appToast.show("Database not ready", "error")
                                    return
                                }

                                window.openPage(modelData.page)
                            }
                        }
                    }
                }
            }
        }
    }
}
