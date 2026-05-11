#ifndef RACK_H
#define RACK_H

#include <QObject>
#include <QByteArray>

class Rack : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)
    Q_PROPERTY(QString lastPacketHex READ lastPacketHex NOTIFY lastPacketChanged)

public:
    static Rack &instance();

    bool initialized() const;
    QString lastPacketHex() const;

    Q_INVOKABLE bool init();
    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void processSlotDataSideA(const QByteArray &packet);

signals:
    void initializedChanged();
    void lastPacketChanged();

private:
    explicit Rack(QObject *parent = nullptr);

    bool m_initialized = false;
    QString m_lastPacketHex;
};

#endif
