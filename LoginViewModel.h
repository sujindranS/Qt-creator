#ifndef LOGINVIEWMODEL_H
#define LOGINVIEWMODEL_H

#include <QObject>
#include <QString>

class LoginViewModel : public QObject
{
    Q_OBJECT

public:
    explicit LoginViewModel(QObject *parent = nullptr);

    Q_INVOKABLE void login(const QString &username, const QString &password);

signals:
    void loginSuccess();
    void loginFailed(const QString &message);
};

#endif
