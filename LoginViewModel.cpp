#include "LoginViewModel.h"

#include <QSqlError>
#include <QSqlQuery>

LoginViewModel::LoginViewModel(QObject *parent)
    : QObject(parent)
{
}

void LoginViewModel::login(const QString &username, const QString &password)
{
    QSqlQuery query;
    query.prepare("SELECT 1 FROM users WHERE username = ? AND password = ? LIMIT 1");
    query.addBindValue(username.trimmed());
    query.addBindValue(password);

    if (query.exec() && query.next()) {
        emit loginSuccess();
        return;
    }

    emit loginFailed(QStringLiteral("Invalid username or password"));
}
