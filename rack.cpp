#include "rack.h"

#include <QDebug>

Rack &Rack::instance()
{
    static Rack rack;
    return rack;
}

Rack::Rack(QObject *parent)
    : QObject(parent)
{
}

bool Rack::initialized() const
{
    return m_initialized;
}

QString Rack::lastPacketHex() const
{
    return m_lastPacketHex;
}

bool Rack::init()
{
    if (!m_initialized) {
        m_initialized = true;
        emit initializedChanged();
    }

    qInfo() << "[RACK] Initialized";
    return true;
}

void Rack::shutdown()
{
    if (m_initialized) {
        m_initialized = false;
        emit initializedChanged();
    }

    qInfo() << "[RACK] Shutdown complete";
}

void Rack::processSlotDataSideA(const QByteArray &packet)
{
    m_lastPacketHex = QString::fromLatin1(packet.toHex(' '));
    qDebug() << "[RACK] Side A packet:" << m_lastPacketHex;
    emit lastPacketChanged();
}
