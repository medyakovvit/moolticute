#ifndef SERVICEITEM_H
#define SERVICEITEM_H

// Application
#include "TreeItem.h"
class LoginItem;

class ServiceItem : public TreeItem
{
public:
    ServiceItem(const QString &sServiceName);
    virtual ~ServiceItem();

    LoginItem *addLogin(const QString &sLoginName);
    LoginItem *findLoginByName(const QString &sLoginName);
    bool isExpanded() const;
    void setExpanded(bool bExpanded);
    QString logins() const;

private:
    bool m_bIsExpanded;
};

#endif // SERVICEITEM_H
