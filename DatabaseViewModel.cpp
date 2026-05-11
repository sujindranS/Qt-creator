#include "DatabaseViewModel.h"
#include "DbNotifier.h"

#include <QDebug>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariantMap>

DatabaseViewModel::DatabaseViewModel(QObject *parent)
    : QObject(parent)
{
}

QVariantList DatabaseViewModel::getWarnings()
{
    QVariantList list;

    QSqlQuery query;
    query.prepare(
        "SELECT uniqueId, partNumber, lotNumber, quantity, createdAt "
        "FROM stores "
        "WHERE isWarning = 1 "
        "ORDER BY uniqueId");

    if (!query.exec()) {
        qWarning() << "[DatabaseViewModel] getWarnings failed:" << query.lastError().text();
        return list;
    }

    while (query.next()) {
        QVariantMap row;
        row["uid"] = query.value(0).toString();
        row["part"] = query.value(1).toString();
        row["lot"] = query.value(2).toString();
        row["qty"] = query.value(3).toString();
        row["createdOn"] = query.value(4).toString();
        list.append(row);
    }

    return list;
}

QVariantList DatabaseViewModel::getStores()
{
    QVariantList list;

    QSqlQuery query;
    query.prepare(
        "SELECT uniqueId, partNumber, lotNumber, quantity, isWarning, createdAt "
        "FROM stores "
        "ORDER BY uniqueId");

    if (!query.exec()) {
        qWarning() << "[DatabaseViewModel] getStores failed:" << query.lastError().text();
        return list;
    }

    while (query.next()) {
        QVariantMap row;
        row["uid"] = query.value(0).toString();
        row["part"] = query.value(1).toString();
        row["lot"] = query.value(2).toString();
        row["qty"] = query.value(3).toString();
        row["isWarning"] = query.value(4).toBool();
        row["createdOn"] = query.value(5).toString();
        list.append(row);
    }

    return list;
}

void DatabaseViewModel::deleteWarning(QString uid)
{
    QSqlQuery query;
    query.prepare("UPDATE stores SET isWarning = 0, updatedAt = datetime('now','localtime') WHERE uniqueId = ?");
    query.addBindValue(uid.trimmed());

    if (!query.exec()) {
        qWarning() << "[DatabaseViewModel] deleteWarning failed:" << query.lastError().text();
        return;
    }

    DbNotifier::instance().notifyChange();
}
