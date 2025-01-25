// Copyright (C) 2025 Michel de Boer
// License: GPLv3
#pragma once
#include <QObject>

namespace Skywalker {

class IFeedPager : public QObject
{
    Q_OBJECT

public:
    explicit IFeedPager(QObject* parent = nullptr) : QObject(parent) {}

    virtual bool isGetFeedInProgress() const = 0;
    virtual void getFeed(int modelId, int limit = 50, int maxPages = 5, int minEntries = 10, const QString& cursor = {}) = 0;
    virtual void getFeedNextPage(int modelId, int maxPages = 5, int minEntries = 10) = 0;

    virtual bool isGetAuthorFeedInProgress() const = 0;

    virtual void getAuthorFeed(int id, int limit = 50, int maxPages = 20, int minEntries = 10, const QString& cursor = {}) = 0;
    virtual void getAuthorFeedNextPage(int id, int maxPages = 20, int minEntries = 10) = 0;
};

}
