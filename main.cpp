#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTimer>
#include <QDebug>
#include <QIcon>

#include "databasemanager.h"
#include "DatabaseViewModel.h"
#include "DbNotifier.h"
#include "LoginViewModel.h"
#include "rack.h"

#ifdef QMLRES_HAS_SERIALPORT
#include <QSerialPort>

QSerialPort *globalUart = nullptr;
#endif

void cleanupOnExit()
{
    qDebug() << "[CLEANUP] Shutting down rack...";
    Rack::instance().shutdown();
}

int main(int argc, char *argv[])
{
    QQuickStyle::setStyle("Material");
    QGuiApplication::setOrganizationName("Rexsatronix");
    QGuiApplication::setApplicationName("InventoryConsole");

    QGuiApplication app(argc, argv);
    // QGuiApplication::setWindowIcon(QIcon(":/assets/icons/logo.png"));

    qInfo() << "Application started!";

    DatabaseManager dbManager;
    DatabaseViewModel databaseVM;
    LoginViewModel loginVM;

    if (!dbManager.isReady()) {
        qCritical() << "Database failed to open:" << dbManager.lastError();
    }

#ifdef QMLRES_HAS_SERIALPORT
    globalUart = new QSerialPort(&app);
    globalUart->setPortName("/dev/ttyS4");
    globalUart->setBaudRate(QSerialPort::Baud115200);
    globalUart->setDataBits(QSerialPort::Data8);
    globalUart->setParity(QSerialPort::NoParity);
    globalUart->setStopBits(QSerialPort::OneStop);
    globalUart->setFlowControl(QSerialPort::NoFlowControl);

    if (!globalUart->open(QIODevice::ReadWrite)) {
        qDebug() << "[UART] Failed:" << globalUart->errorString();
    }

    QByteArray rxBuffer;
    QTimer processTimer;
    processTimer.setInterval(5);

    if (globalUart->isOpen()) {
        QObject::connect(globalUart, &QSerialPort::readyRead, [&]() {
            rxBuffer.append(globalUart->readAll());

            if (!processTimer.isActive())
                processTimer.start();
        });

        QObject::connect(&processTimer, &QTimer::timeout, [&]() {
            while (rxBuffer.size() >= 6) {
                QByteArray packet = rxBuffer.left(6);
                rxBuffer.remove(0, 6);

                qDebug() << "[UART RX]" << packet.toHex(' ');
                Rack::instance().processSlotDataSideA(packet);
            }

            if (rxBuffer.size() < 6)
                processTimer.stop();
        });
    }
#else
    qWarning() << "[UART] Qt SerialPort module is not available in this Qt kit. UART is disabled.";
#endif

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("dbManager", &dbManager);
    engine.rootContext()->setContextProperty("databaseVM", &databaseVM);
    engine.rootContext()->setContextProperty("dbNotifier", &DbNotifier::instance());
    engine.rootContext()->setContextProperty("loginVM", &loginVM);
    engine.rootContext()->setContextProperty("rackManager", &Rack::instance());

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("qmlres", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    QObject::connect(&app, &QCoreApplication::aboutToQuit, []() {
        qDebug() << "[APP] Shutting down...";

#ifdef QMLRES_HAS_SERIALPORT
        if (globalUart && globalUart->isOpen())
            globalUart->close();
#endif

        cleanupOnExit();
    });

    return app.exec();
}
