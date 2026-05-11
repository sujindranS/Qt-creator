#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>

class DatabaseManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ isReady NOTIFY readyChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit DatabaseManager(QObject *parent = nullptr);

    bool isReady() const;
    QString lastError() const;

    Q_INVOKABLE void addInventory(QString id, QString part, QString lot, int qty);
    Q_INVOKABLE bool reelExists(const QString &id);
    Q_INVOKABLE QString pickupDirect(QString id);
    Q_INVOKABLE bool pickupWorkOrder(QString workOrder, QString id);

    Q_INVOKABLE QVariantList getRecentInventory();
    Q_INVOKABLE QVariantList getRecentPickups();
    Q_INVOKABLE QVariantList getInventory();
    Q_INVOKABLE QVariantList getMissPickups();
    Q_INVOKABLE bool enqueueStoreOut(QString itemId,
                                     QString workOrder = QString(),
                                     QString queueType = QStringLiteral("direct"));
    Q_INVOKABLE QVariantList getStoreOutQueue(QString queueType = QStringLiteral("direct"));
    Q_INVOKABLE QString confirmStoreOut(int queueId);
    Q_INVOKABLE void deleteStoreOutQueue(int queueId);
    Q_INVOKABLE void deleteMissPickup(QString itemId, QString timestamp);
    Q_INVOKABLE void clearAllMissPickups();

    Q_INVOKABLE void saveCompany(QString name,
                                 QString phone,
                                 QString gst,
                                 QString cin,
                                 QString address,
                                 QString pin);
    Q_INVOKABLE QVariantMap loadCompany();
    Q_INVOKABLE QVariantMap loadRackDetails();
    Q_INVOKABLE bool saveRackDetails(QString logicalName,
                                     QString rackId,
                                     int nodeCount,
                                     int numberOfSlots);

signals:
    void dataChanged();
    void readyChanged();
    void lastErrorChanged();

private:
    bool openDatabase();
    void setLastError(const QString &error);

    QSqlDatabase db;
    bool m_ready = false;
    QString m_lastError;
};

#endif
