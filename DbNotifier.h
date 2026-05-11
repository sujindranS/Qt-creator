#ifndef DBNOTIFIER_H
#define DBNOTIFIER_H

#include <QObject>

class DbNotifier : public QObject
{
    Q_OBJECT

public:
    static DbNotifier &instance()
    {
        static DbNotifier inst;
        return inst;
    }

    Q_INVOKABLE void notifyChange()
    {
        emit databaseChanged();
    }

signals:
    void databaseChanged();

private:
    explicit DbNotifier(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

    Q_DISABLE_COPY_MOVE(DbNotifier)
};

#endif
