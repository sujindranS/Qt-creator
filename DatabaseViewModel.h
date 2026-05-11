#ifndef DATABASEVIEWMODEL_H
#define DATABASEVIEWMODEL_H

#include <QObject>
#include <QVariantList>

class DatabaseViewModel : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseViewModel(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList getWarnings();
    Q_INVOKABLE QVariantList getStores();
    Q_INVOKABLE void deleteWarning(QString uid);
};

#endif
