#include "databasemanager.h"

#include "DatabaseSchema.h"
#include "DbNotifier.h"

#include <QDir>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

namespace {
QString workOrderTypePrefix()
{
    return QStringLiteral("workorder:");
}

QString directTypeValue()
{
    return QStringLiteral("direct");
}
}

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
    if (!openDatabase())
        return;

    DatabaseSchema::initializeDatabase();
    m_ready = true;
    emit readyChanged();
    setLastError(QString());
}

bool DatabaseManager::isReady() const
{
    return m_ready;
}

QString DatabaseManager::lastError() const
{
    return m_lastError;
}

bool DatabaseManager::openDatabase()
{
    if (QSqlDatabase::contains("qt_sql_default_connection"))
        db = QSqlDatabase::database("qt_sql_default_connection");
    else
        db = QSqlDatabase::addDatabase("QSQLITE");

    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (dataDir.isEmpty()) {
        setLastError(QStringLiteral("Unable to resolve a writable data directory."));
        return false;
    }

    QDir dir(dataDir);
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        setLastError(QStringLiteral("Unable to create data directory: %1").arg(dataDir));
        return false;
    }

    db.setDatabaseName(dir.filePath(QStringLiteral("rack.db")));
    if (!db.open()) {
        setLastError(db.lastError().text());
        return false;
    }

    return true;
}

void DatabaseManager::setLastError(const QString &error)
{
    if (m_lastError == error)
        return;

    m_lastError = error;
    emit lastErrorChanged();
}

void DatabaseManager::addInventory(QString id, QString part, QString lot, int qty)
{
    if (!m_ready)
        return;

    id = id.trimmed();
    part = part.trimmed();
    lot = lot.trimmed();

    if (id.isEmpty() || part.isEmpty() || qty <= 0) {
        setLastError(QStringLiteral("Inventory data is incomplete."));
        return;
    }

    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO stocks (uniqueId, quantity, lotNumber, partNumber, createdAt, updatedAt) "
        "VALUES (?, ?, ?, ?, datetime('now','localtime'), datetime('now','localtime')) "
        "ON CONFLICT(uniqueId) DO UPDATE SET "
        "quantity = excluded.quantity, "
        "lotNumber = excluded.lotNumber, "
        "partNumber = excluded.partNumber, "
        "updatedAt = datetime('now','localtime')");
    query.addBindValue(id);
    query.addBindValue(qty);
    query.addBindValue(lot);
    query.addBindValue(part);

    if (!query.exec()) {
        setLastError(query.lastError().text());
        return;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
}

bool DatabaseManager::reelExists(const QString &id)
{
    if (!m_ready || id.trimmed().isEmpty())
        return false;

    QSqlQuery query(db);
    query.prepare("SELECT 1 FROM stocks WHERE uniqueId = ? LIMIT 1");
    query.addBindValue(id.trimmed());

    if (!query.exec()) {
        setLastError(query.lastError().text());
        return false;
    }

    return query.next();
}

QString DatabaseManager::pickupDirect(QString id)
{
    if (!m_ready)
        return QStringLiteral("DB_ERROR");

    id = id.trimmed();
    if (id.isEmpty())
        return QStringLiteral("INVALID_INPUT");

    if (!db.transaction()) {
        setLastError(db.lastError().text());
        return QStringLiteral("DB_ERROR");
    }

    QSqlQuery selectQuery(db);
    selectQuery.prepare("SELECT quantity FROM stocks WHERE uniqueId = ? AND isScraped = 0");
    selectQuery.addBindValue(id);
    if (!selectQuery.exec()) {
        setLastError(selectQuery.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    if (!selectQuery.next()) {
        QSqlQuery logQuery(db);
        logQuery.prepare(
            "INSERT INTO pickupStation(uniqueIds, type, status, button, createdAt, updatedAt) "
            "VALUES (?, ?, 'failed', 'Retry', datetime('now','localtime'), datetime('now','localtime'))");
        logQuery.addBindValue(id);
        logQuery.addBindValue(directTypeValue());
        logQuery.exec();
        db.commit();
        DbNotifier::instance().notifyChange();
        emit dataChanged();
        return QStringLiteral("NOT_FOUND");
    }

    if (selectQuery.value(0).toInt() <= 0) {
        QSqlQuery logQuery(db);
        logQuery.prepare(
            "INSERT INTO pickupStation(uniqueIds, type, status, button, createdAt, updatedAt) "
            "VALUES (?, ?, 'failed', 'Retry', datetime('now','localtime'), datetime('now','localtime'))");
        logQuery.addBindValue(id);
        logQuery.addBindValue(directTypeValue());
        logQuery.exec();
        db.commit();
        DbNotifier::instance().notifyChange();
        emit dataChanged();
        return QStringLiteral("OUT_OF_STOCK");
    }

    QSqlQuery updateQuery(db);
    updateQuery.prepare("UPDATE stocks SET quantity = quantity - 1 WHERE uniqueId = ? AND quantity > 0");
    updateQuery.addBindValue(id);
    if (!updateQuery.exec() || updateQuery.numRowsAffected() != 1) {
        setLastError(updateQuery.lastError().text().isEmpty()
                         ? QStringLiteral("Failed to update stock quantity.")
                         : updateQuery.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    QSqlQuery logQuery(db);
    logQuery.prepare(
        "INSERT INTO pickupStation(uniqueIds, type, status, button, createdAt, updatedAt) "
        "VALUES (?, ?, 'completed', 'Done', datetime('now','localtime'), datetime('now','localtime'))");
    logQuery.addBindValue(id);
    logQuery.addBindValue(directTypeValue());
    if (!logQuery.exec()) {
        setLastError(logQuery.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    if (!db.commit()) {
        setLastError(db.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
    return QStringLiteral("SUCCESS");
}

bool DatabaseManager::pickupWorkOrder(QString workOrder, QString id)
{
    workOrder = workOrder.trimmed();
    if (workOrder.isEmpty())
        workOrder = QStringLiteral("WO-DEMO");

    QString result = pickupDirect(id);
    if (result != QStringLiteral("SUCCESS"))
        return false;

    QSqlQuery query(db);
    query.prepare(
        "UPDATE pickupStation "
        "SET type = ?, updatedAt = datetime('now','localtime') "
        "WHERE id = (SELECT MAX(id) FROM pickupStation WHERE uniqueIds = ? AND status = 'completed')");
    query.addBindValue(workOrderTypePrefix() + workOrder);
    query.addBindValue(id.trimmed());
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return false;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
    return true;
}

QVariantList DatabaseManager::getRecentInventory()
{
    QVariantList list;
    if (!m_ready)
        return list;

    QSqlQuery query(db);
    query.prepare(
        "SELECT uniqueId, partNumber, lotNumber, quantity, updatedAt "
        "FROM stocks "
        "ORDER BY updatedAt DESC "
        "LIMIT 10");
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return list;
    }

    while (query.next()) {
        QVariantMap row;
        row["id"] = query.value(0);
        row["part"] = query.value(1);
        row["lot"] = query.value(2);
        row["qty"] = query.value(3);
        row["updatedAt"] = query.value(4);
        list.append(row);
    }

    return list;
}

QVariantList DatabaseManager::getRecentPickups()
{
    QVariantList list;
    if (!m_ready)
        return list;

    QSqlQuery query(db);
    query.prepare(
        "SELECT p.uniqueIds, p.type, p.status, p.updatedAt, "
        "COALESCE(s.quantity, 0), COALESCE(s.partNumber, ''), COALESCE(s.lotNumber, '') "
        "FROM pickupStation p "
        "LEFT JOIN stocks s ON s.uniqueId = p.uniqueIds "
        "WHERE p.status <> 'idle' "
        "ORDER BY p.id DESC "
        "LIMIT 50");
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return list;
    }

    while (query.next()) {
        const QString typeValue = query.value(1).toString();
        QVariantMap row;
        row["itemId"] = query.value(0);
        row["workOrder"] = typeValue.startsWith(workOrderTypePrefix())
                               ? typeValue.mid(workOrderTypePrefix().size())
                               : QString();
        row["type"] = typeValue.startsWith(workOrderTypePrefix()) ? QStringLiteral("workorder")
                                                                  : typeValue;
        row["time"] = query.value(3);
        row["qty"] = query.value(4);
        row["part"] = query.value(5);
        row["lot"] = query.value(6);
        list.append(row);
    }

    return list;
}

QVariantList DatabaseManager::getInventory()
{
    QVariantList list;
    if (!m_ready)
        return list;

    QSqlQuery query(db);
    query.prepare(
        "SELECT uniqueId, partNumber, lotNumber, quantity, updatedAt "
        "FROM stocks "
        "WHERE isScraped = 0 "
        "ORDER BY updatedAt DESC, uniqueId ASC");
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return list;
    }

    while (query.next()) {
        QVariantMap row;
        row["id"] = query.value(0);
        row["part"] = query.value(1);
        row["lot"] = query.value(2);
        row["qty"] = query.value(3);
        row["updatedAt"] = query.value(4);
        list.append(row);
    }

    return list;
}

QVariantList DatabaseManager::getMissPickups()
{
    QVariantList list;
    if (!m_ready)
        return list;

    QSqlQuery query(db);
    query.prepare(
        "SELECT p.uniqueIds, COALESCE(s.partNumber, 'Unknown'), COALESCE(s.lotNumber, '-'), "
        "COALESCE(s.quantity, 0), p.updatedAt "
        "FROM pickupStation p "
        "LEFT JOIN stocks s ON s.uniqueId = p.uniqueIds "
        "WHERE p.status = 'failed' "
        "ORDER BY p.id DESC");
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return list;
    }

    while (query.next()) {
        QVariantMap row;
        row["uniqueId"] = query.value(0);
        row["partNumber"] = query.value(1);
        row["internalPart"] = query.value(2);
        row["quantity"] = query.value(3);
        row["createdOn"] = query.value(4);
        list.append(row);
    }

    return list;
}

bool DatabaseManager::enqueueStoreOut(QString itemId, QString workOrder, QString queueType)
{
    if (!m_ready)
        return false;

    itemId = itemId.trimmed();
    workOrder = workOrder.trimmed();
    queueType = queueType.trimmed().toLower();

    if (itemId.isEmpty()) {
        setLastError(QStringLiteral("Item id is required for store out."));
        return false;
    }

    QString storedType = queueType == QStringLiteral("workorder")
                             ? workOrderTypePrefix() + (workOrder.isEmpty() ? QStringLiteral("WO-DEMO") : workOrder)
                             : directTypeValue();

    QSqlQuery duplicateQuery(db);
    duplicateQuery.prepare(
        "SELECT 1 FROM pickupStation WHERE uniqueIds = ? AND type = ? AND status = 'idle' LIMIT 1");
    duplicateQuery.addBindValue(itemId);
    duplicateQuery.addBindValue(storedType);
    if (!duplicateQuery.exec()) {
        setLastError(duplicateQuery.lastError().text());
        return false;
    }

    if (duplicateQuery.next()) {
        setLastError(QStringLiteral("This item is already queued for pickup."));
        return false;
    }

    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO pickupStation(uniqueIds, type, status, button, createdAt, updatedAt) "
        "VALUES (?, ?, 'idle', 'Pickup', datetime('now','localtime'), datetime('now','localtime'))");
    query.addBindValue(itemId);
    query.addBindValue(storedType);
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return false;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
    return true;
}

QVariantList DatabaseManager::getStoreOutQueue(QString queueType)
{
    QVariantList list;
    if (!m_ready)
        return list;

    queueType = queueType.trimmed().toLower();
    if (queueType.isEmpty())
        queueType = directTypeValue();

    QString whereClause = queueType == QStringLiteral("workorder")
                              ? "p.type LIKE 'workorder:%'"
                              : "p.type = 'direct'";

    QSqlQuery query(db);
    const QString sql =
        QStringLiteral(
        "SELECT p.id, p.uniqueIds, p.type, p.createdAt, "
        "COALESCE(s.partNumber, ''), COALESCE(s.lotNumber, ''), COALESCE(s.quantity, 0) "
        "FROM pickupStation p "
        "LEFT JOIN stocks s ON s.uniqueId = p.uniqueIds "
        "WHERE p.status = 'idle' AND ")
        + whereClause
        + QStringLiteral(" ORDER BY p.id DESC");
    query.prepare(sql);
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return list;
    }

    while (query.next()) {
        const QString typeValue = query.value(2).toString();
        QVariantMap row;
        row["queueId"] = query.value(0);
        row["itemId"] = query.value(1);
        row["workOrder"] = typeValue.startsWith(workOrderTypePrefix())
                               ? typeValue.mid(workOrderTypePrefix().size())
                               : QString();
        row["queueType"] = typeValue.startsWith(workOrderTypePrefix()) ? QStringLiteral("workorder")
                                                                       : QStringLiteral("direct");
        row["createdAt"] = query.value(3);
        row["part"] = query.value(4);
        row["lot"] = query.value(5);
        row["qty"] = query.value(6);
        list.append(row);
    }

    return list;
}

QString DatabaseManager::confirmStoreOut(int queueId)
{
    if (!m_ready)
        return QStringLiteral("DB_ERROR");

    QSqlQuery query(db);
    query.prepare("SELECT uniqueIds, type FROM pickupStation WHERE id = ? AND status = 'idle'");
    query.addBindValue(queueId);
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return QStringLiteral("DB_ERROR");
    }

    if (!query.next()) {
        setLastError(QStringLiteral("Pickup queue item was not found."));
        return QStringLiteral("NOT_FOUND");
    }

    const QString itemId = query.value(0).toString();
    const QString typeValue = query.value(1).toString();
    const QString workOrder = typeValue.startsWith(workOrderTypePrefix())
                                  ? typeValue.mid(workOrderTypePrefix().size())
                                  : QString();

    QString result = QStringLiteral("SUCCESS");

    if (!db.transaction()) {
        setLastError(db.lastError().text());
        return QStringLiteral("DB_ERROR");
    }

    QSqlQuery selectQuery(db);
    selectQuery.prepare("SELECT quantity FROM stocks WHERE uniqueId = ? AND isScraped = 0");
    selectQuery.addBindValue(itemId);
    if (!selectQuery.exec()) {
        setLastError(selectQuery.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    if (!selectQuery.next()) {
        result = QStringLiteral("NOT_FOUND");
    } else if (selectQuery.value(0).toInt() <= 0) {
        result = QStringLiteral("OUT_OF_STOCK");
    } else {
        QSqlQuery updateQuery(db);
        updateQuery.prepare("UPDATE stocks SET quantity = quantity - 1 WHERE uniqueId = ? AND quantity > 0");
        updateQuery.addBindValue(itemId);
        if (!updateQuery.exec() || updateQuery.numRowsAffected() != 1) {
            setLastError(updateQuery.lastError().text().isEmpty()
                             ? QStringLiteral("Failed to update stock quantity.")
                             : updateQuery.lastError().text());
            db.rollback();
            return QStringLiteral("DB_ERROR");
        }
    }

    QSqlQuery updateQueue(db);
    updateQueue.prepare(
        "UPDATE pickupStation "
        "SET status = ?, button = ?, updatedAt = datetime('now','localtime') "
        "WHERE id = ?");
    updateQueue.addBindValue(result == QStringLiteral("SUCCESS") ? QStringLiteral("completed")
                                                                  : QStringLiteral("failed"));
    updateQueue.addBindValue(result == QStringLiteral("SUCCESS") ? QStringLiteral("Done")
                                                                  : QStringLiteral("Retry"));
    updateQueue.addBindValue(queueId);
    if (!updateQueue.exec()) {
        setLastError(updateQueue.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    if (!db.commit()) {
        setLastError(db.lastError().text());
        db.rollback();
        return QStringLiteral("DB_ERROR");
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
    Q_UNUSED(workOrder);
    return result;
}

void DatabaseManager::deleteStoreOutQueue(int queueId)
{
    if (!m_ready)
        return;

    QSqlQuery query(db);
    query.prepare("DELETE FROM pickupStation WHERE id = ? AND status = 'idle'");
    query.addBindValue(queueId);
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
}

void DatabaseManager::deleteMissPickup(QString itemId, QString timestamp)
{
    if (!m_ready)
        return;

    QSqlQuery query(db);
    query.prepare("DELETE FROM pickupStation WHERE uniqueIds = ? AND updatedAt = ? AND status = 'failed'");
    query.addBindValue(itemId.trimmed());
    query.addBindValue(timestamp.trimmed());
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
}

void DatabaseManager::clearAllMissPickups()
{
    if (!m_ready)
        return;

    QSqlQuery query(db);
    if (!query.exec("DELETE FROM pickupStation WHERE status = 'failed'")) {
        setLastError(query.lastError().text());
        return;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
}

void DatabaseManager::saveCompany(QString name,
                                  QString phone,
                                  QString gst,
                                  QString cin,
                                  QString address,
                                  QString pin)
{
    if (!m_ready)
        return;

    QSqlQuery query(db);
    query.prepare(
        "INSERT OR REPLACE INTO company (id, name, phone, gst, cin, address, pin) "
        "VALUES (1, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(name.trimmed());
    query.addBindValue(phone.trimmed());
    query.addBindValue(gst.trimmed());
    query.addBindValue(cin.trimmed());
    query.addBindValue(address.trimmed());
    query.addBindValue(pin.trimmed());
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return;
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
}

QVariantMap DatabaseManager::loadCompany()
{
    QVariantMap data;
    if (!m_ready)
        return data;

    QSqlQuery query(db);
    query.prepare("SELECT name, phone, gst, cin, address, pin FROM company WHERE id = 1");
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return data;
    }

    if (query.next()) {
        data["name"] = query.value(0);
        data["phone"] = query.value(1);
        data["gst"] = query.value(2);
        data["cin"] = query.value(3);
        data["address"] = query.value(4);
        data["pin"] = query.value(5);
    }

    return data;
}

QVariantMap DatabaseManager::loadRackDetails()
{
    QVariantMap data;
    if (!m_ready)
        return data;

    QSqlQuery query(db);
    query.prepare(
        "SELECT logicalName, rackId, nodeCount, numberOfSlots, type, rackStatus, ledText "
        "FROM rackDetails ORDER BY id ASC LIMIT 1");
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return data;
    }

    if (query.next()) {
        data["logicalName"] = query.value(0);
        data["rackId"] = query.value(1);
        data["nodeCount"] = query.value(2);
        data["slotCount"] = query.value(3);
        data["type"] = query.value(4);
        data["rackStatus"] = query.value(5);
        data["ledText"] = query.value(6);
    }

    return data;
}

bool DatabaseManager::saveRackDetails(QString logicalName,
                                      QString rackId,
                                      int nodeCount,
                                      int numberOfSlots)
{
    if (!m_ready)
        return false;

    logicalName = logicalName.trimmed();
    rackId = rackId.trimmed();

    if (logicalName.isEmpty() || rackId.isEmpty() || nodeCount <= 0 || numberOfSlots <= 0) {
        setLastError(QStringLiteral("Rack details are incomplete."));
        return false;
    }

    QSqlQuery query(db);
    query.prepare(
        "UPDATE rackDetails "
        "SET logicalName = ?, rackId = ?, nodeCount = ?, numberOfSlots = ? "
        "WHERE id = (SELECT id FROM rackDetails ORDER BY id ASC LIMIT 1)");
    query.addBindValue(logicalName);
    query.addBindValue(rackId);
    query.addBindValue(nodeCount);
    query.addBindValue(numberOfSlots);
    if (!query.exec()) {
        setLastError(query.lastError().text());
        return false;
    }

    if (query.numRowsAffected() == 0) {
        QSqlQuery insertQuery(db);
        insertQuery.prepare(
            "INSERT INTO rackDetails(name, logicalName, rackId, nodeCount, numberOfSlots, type, rackStatus, ledText) "
            "VALUES ('DefaultRack', ?, ?, ?, ?, 'Stationary', 'Online', 'Rexsatronix')");
        insertQuery.addBindValue(logicalName);
        insertQuery.addBindValue(rackId);
        insertQuery.addBindValue(nodeCount);
        insertQuery.addBindValue(numberOfSlots);
        if (!insertQuery.exec()) {
            setLastError(insertQuery.lastError().text());
            return false;
        }
    }

    setLastError(QString());
    DbNotifier::instance().notifyChange();
    emit dataChanged();
    return true;
}
