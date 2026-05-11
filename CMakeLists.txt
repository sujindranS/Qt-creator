# cmake_minimum_required(VERSION 3.16)

# project(qmlres VERSION 0.1 LANGUAGES CXX)

# set(CMAKE_CXX_STANDARD_REQUIRED ON)

# find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Sql)

# qt_standard_project_setup(REQUIRES 6.8)

# qt_add_executable(appqmlres
#     main.cpp
#databasemanager.cpp

# )

# qt_add_qml_module(appqmlres
#     URI qmlres
#     VERSION 1.0
#     QML_FILES
#         Main.qml
#         SOURCES databasemanager.h
#         QML_FILES AdministrationPage.qml
#         QML_FILES ReelsInPage.qml
#         QML_FILES PickupPage.qml
#         QML_FILES ReportPage.qml
#         QML_FILES WarningsPage.qml
#         QML_FILES VirtualRackPage.qml

#         RESOURCES resource.qrc
#     )






# # Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# # If you are developing for iOS or macOS you should consider setting an
# # explicit, fixed bundle identifier manually though.
# set_target_properties(appqmlres PROPERTIES
# #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appqmlres
#     MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
#     MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
#     MACOSX_BUNDLE TRUE
#     WIN32_EXECUTABLE TRUE
# )
# target_link_libraries(appqmlres
#     PRIVATE
#         Qt6::Core
#         Qt6::Gui
#         Qt6::Qml
#         Qt6::Quick
#         Qt6::Sql   # 🔥 THIS FIXES YOUR ERROR
# )
# include(GNUInstallDirs)
# install(TARGETS appqmlres
#     BUNDLE DESTINATION .
#     LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
#     RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
# )







cmake_minimum_required(VERSION 3.16)

project(qmlres VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql)
find_package(Qt6 QUIET COMPONENTS SerialPort)

qt_standard_project_setup(REQUIRES 6.8)

# ✅ Executable
qt_add_executable(appqmlres
    main.cpp
    databasemanager.cpp
    DatabaseViewModel.cpp
    LoginViewModel.cpp
    rack.cpp
)

# ✅ QML Module (ONLY QML FILES HERE)
qt_add_qml_module(appqmlres
    URI qmlres
    VERSION 1.0

    QML_FILES
        Main.qml
        LoginPage.qml
        AdministrationPage.qml
        ReelsInPage.qml
        PickupPage.qml
        ReportPage.qml
        WarningsPage.qml
        VirtualRackPage.qml
        LoaderOverlay.qml
        Toast.qml
        Footer.qml
        Navbar.qml
        AnimatedDashboardCard.qml
        StoresInPage.qml
        SettingsPage.qml
        StoreoutPage.qml



)




# ✅ 🔥 ADD THIS (IMPORTANT — fixes your icons)
qt_add_resources(appqmlres "app_resources"
    PREFIX "/"
    FILES
        assets/icons/alarm.png
        assets/icons/clock.png
        assets/icons/database.png
        assets/icons/document.png
        assets/icons/film-reel.png
        assets/icons/package.png
        assets/icons/profile.png
        assets/icons/settings.png
        assets/icons/visualization.png
        assets/icons/warning.png
        assets/icons/logo.png
        assets/icons/loading.gif
        assets/icons/stores-out.png
)

# ✅ Headers
target_sources(appqmlres PRIVATE
    databasemanager.h
    DatabaseSchema.h
    DatabaseViewModel.h
    DbNotifier.h
    LoginViewModel.h
    rack.h
)

# ✅ Link libraries
target_link_libraries(appqmlres
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Sql
)

if(TARGET Qt6::SerialPort)
    target_link_libraries(appqmlres PRIVATE Qt6::SerialPort)
    target_compile_definitions(appqmlres PRIVATE QMLRES_HAS_SERIALPORT)
endif()

set_target_properties(appqmlres PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS appqmlres
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
