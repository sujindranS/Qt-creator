#ifndef DATABASESCHEMA_H
#define DATABASESCHEMA_H

#include <QDebug>
#include <QSqlError>
#include <QSqlQuery>
#include <QString>

class DatabaseSchema
{
public:
    static void initializeDatabase()
    {
        QSqlQuery query;

        const QString createUserTable = R"(
CREATE TABLE IF NOT EXISTS users(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    UNIQUE(username, password)
);
)";
        executeQuery(query, createUserTable, "users");

        const QString insertDefaultUser = R"(
INSERT OR IGNORE INTO users(username,password)
VALUES('qik','qik');
)";
        executeQuery(query, insertDefaultUser, "default user");

        const QString createRackDetailsTable = R"(
CREATE TABLE IF NOT EXISTS rackDetails(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    logicalName TEXT,
    rackId TEXT UNIQUE NOT NULL,
    nodeCount INTEGER NOT NULL,
    numberOfSlots INTEGER NOT NULL,
    type TEXT NOT NULL,
    rackStatus TEXT NOT NULL,
    ledText TEXT
);
)";
        executeQuery(query, createRackDetailsTable, "rackDetails");

        const QString defaultRackDetails = R"(
INSERT OR IGNORE INTO rackDetails(
    name,
    logicalName,
    rackId,
    nodeCount,
    numberOfSlots,
    type,
    rackStatus,
    ledText
)
VALUES(
    'DefaultRack',
    'S001',
    'QIKKRACKTEST1',
    1,
    15,
    'Stationary',
    'Online',
    'Rexsatronix'
);
)";
        executeQuery(query, defaultRackDetails, "default rackDetails");

        const QString createStocksTable = R"(
CREATE TABLE IF NOT EXISTS stocks(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uniqueId TEXT UNIQUE NOT NULL,
    quantity INTEGER,
    manufactureDate TEXT,
    lotNumber TEXT,
    isScraped BOOL NOT NULL DEFAULT FALSE,
    partNumber TEXT,
    expireDate TEXT,
    invoiceDate TEXT,
    createdAt DATETIME DEFAULT (datetime('now','localtime')),
    updatedAt DATETIME DEFAULT (datetime('now','localtime'))
);
)";
        executeQuery(query, createStocksTable, "stocks");

        const QString createTriggerStocks = R"(
CREATE TRIGGER IF NOT EXISTS trigger_stocks_updatedAt
AFTER UPDATE ON stocks
FOR EACH ROW
BEGIN
    UPDATE stocks
    SET updatedAt = datetime('now','localtime')
    WHERE id = NEW.id;
END;
)";
        executeQuery(query, createTriggerStocks, "trigger_stocks_updatedAt");

        const QString createStoresTable = R"(
CREATE TABLE IF NOT EXISTS stores(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uniqueId TEXT UNIQUE NOT NULL,
    quantity TEXT,
    partNumber TEXT,
    manufactureDate TEXT,
    lotNumber TEXT,
    expireDate TEXT,
    reelPlaced BOOL,
    isWarning BOOL NOT NULL DEFAULT FALSE,
    isPickup BOOL NOT NULL DEFAULT FALSE,
    isPickupDone BOOL NOT NULL DEFAULT FALSE,
    rowNo INTEGER,
    slotNo INTEGER,
    createdAt DATETIME DEFAULT (datetime('now','localtime')),
    updatedAt DATETIME DEFAULT (datetime('now','localtime'))
);
)";
        executeQuery(query, createStoresTable, "stores");

        const QString createTriggerStores = R"(
CREATE TRIGGER IF NOT EXISTS trigger_stores_updatedAt
AFTER UPDATE ON stores
FOR EACH ROW
BEGIN
    UPDATE stores
    SET updatedAt = datetime('now','localtime')
    WHERE id = NEW.id;
END;
)";
        executeQuery(query, createTriggerStores, "trigger_stores_updatedAt");

        const QString createPickupStationTable = R"(
CREATE TABLE IF NOT EXISTS pickupStation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uniqueIds TEXT NOT NULL,
    type TEXT NOT NULL,
    status TEXT DEFAULT 'idle',
    button TEXT DEFAULT 'Pickup',
    createdAt DATETIME DEFAULT (datetime('now','localtime')),
    updatedAt DATETIME DEFAULT (datetime('now','localtime'))
);
)";
        executeQuery(query, createPickupStationTable, "pickupStation");

        const QString createTriggerPickupStation = R"(
CREATE TRIGGER IF NOT EXISTS trigger_pickupStation_updatedAt
AFTER UPDATE ON pickupStation
FOR EACH ROW
BEGIN
    UPDATE pickupStation
    SET updatedAt = datetime('now','localtime')
    WHERE id = NEW.id;
END;
)";
        executeQuery(query, createTriggerPickupStation, "trigger_pickupStation_updatedAt");

        const QString createBarcodeTempletTable = R"(
CREATE TABLE IF NOT EXISTS barcodeTemplet(
    id INTEGER PRIMARY KEY CHECK (id = 1),
    type TEXT,
    reelsinMethod TEXT,
    autoUniqueIdGen TEXT,
    groupSeperator TEXT,
    data TEXT,
    templete TEXT,
    createdAt DATETIME DEFAULT (datetime('now','localtime')),
    updatedAt DATETIME DEFAULT (datetime('now','localtime'))
);
)";
        executeQuery(query, createBarcodeTempletTable, "barcodeTemplet");

        const QString createBarcodeTempletTrigger = R"(
CREATE TRIGGER IF NOT EXISTS trigger_barcodeTemplet_updatedAt
AFTER UPDATE ON barcodeTemplet
FOR EACH ROW
BEGIN
    UPDATE barcodeTemplet
    SET updatedAt = datetime('now','localtime')
    WHERE id = NEW.id;
END;
)";
        executeQuery(query, createBarcodeTempletTrigger, "trigger_barcodeTemplet_updatedAt");

        const QString createSlotsTable = R"(
CREATE TABLE IF NOT EXISTS slots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_id TEXT,
    slotNo TEXT,
    uniqueID TEXT,
    status TEXT,
    isExpire BOOL NOT NULL DEFAULT FALSE,
    createdAt DATETIME DEFAULT (datetime('now','localtime')),
    updatedAt DATETIME DEFAULT (datetime('now','localtime'))
);
)";
        executeQuery(query, createSlotsTable, "slots");

        const QString createTriggerSlots = R"(
CREATE TRIGGER IF NOT EXISTS trigger_slots_updatedAt
AFTER UPDATE ON slots
FOR EACH ROW
BEGIN
    UPDATE slots
    SET updatedAt = datetime('now','localtime')
    WHERE id = NEW.id;
END;
)";
        executeQuery(query, createTriggerSlots, "trigger_slots_updatedAt");

        const QString createNodesTable = R"(
CREATE TABLE IF NOT EXISTS nodes(
    node_id INTEGER PRIMARY KEY,
    node_data INTEGER DEFAULT 0,
    warning_data INTEGER DEFAULT 0,
    pickup_data INTEGER DEFAULT 0,
    expiry_data INTEGER DEFAULT 0,
    createdAt DATETIME DEFAULT (datetime('now','localtime')),
    updatedAt DATETIME DEFAULT (datetime('now','localtime'))
);
)";
        executeQuery(query, createNodesTable, "nodes");

        const QString createTriggerNodes = R"(
CREATE TRIGGER IF NOT EXISTS trigger_nodes_updatedAt
AFTER UPDATE ON nodes
FOR EACH ROW
BEGIN
    UPDATE nodes
    SET updatedAt = datetime('now','localtime')
    WHERE node_id = NEW.node_id;
END;
)";
        executeQuery(query, createTriggerNodes, "trigger_nodes_updatedAt");

        for (int id = 2; id <= 50; ++id) {
            executeQuery(query,
                         QStringLiteral("INSERT OR IGNORE INTO nodes (node_id) VALUES (%1);").arg(id),
                         "insert nodes");
        }

        // Compatibility table kept so the existing administration page can still save profile data.
        const QString createCompanyTable = R"(
CREATE TABLE IF NOT EXISTS company (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    name TEXT,
    phone TEXT,
    gst TEXT,
    cin TEXT,
    address TEXT,
    pin TEXT
);
)";
        executeQuery(query, createCompanyTable, "company");
    }

private:
    static void executeQuery(QSqlQuery &query, const QString &sql, const QString &description)
    {
        if (!query.exec(sql))
            qDebug() << "Failed to create" << description << ":" << query.lastError().text();
    }
};

#endif
