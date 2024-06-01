// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#pragma once
#include "normalized_word_index.h"
#include <QColor>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>
#include <QString>

namespace Skywalker {

class FocusHashtagEntry : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int maxSize MEMBER MAX_HASHTAGS CONSTANT FINAL)
    Q_PROPERTY(int id READ getId CONSTANT FINAL)
    Q_PROPERTY(QStringList hashtags READ getHashtags NOTIFY hashtagsChanged FINAL)
    Q_PROPERTY(QColor highlightColor READ getHightlightColor WRITE setHighlightColor NOTIFY highlightColorChanged FINAL)

public:
    static constexpr int MAX_HASHTAGS = 20;
    static FocusHashtagEntry* fromJson(const QJsonObject& json, QObject* parent = nullptr);

    explicit FocusHashtagEntry(QObject* parent = nullptr);

    QJsonObject toJson() const;

    const QStringList& getHashtags() const { return mHashtags; }
    void addHashtag(const QString& hashtag);
    void removeHashtag(const QString& hashtag);

    int getId() const { return mId; }
    const QColor& getHightlightColor() const { return mHightlightColor; }
    void setHighlightColor(const QColor& color);

signals:
    void hashtagsChanged();
    void highlightColorChanged();

private:
    int mId;
    QStringList mHashtags;
    QColor mHightlightColor;

    static int sNextId;
};

using FocusHashtagEntryList = QList<FocusHashtagEntry*>;

class FocusHashtags : public QObject, public IMatchWords
{
    Q_OBJECT
    Q_PROPERTY(int maxSize MEMBER MAX_ENTRIES CONSTANT FINAL)
    Q_PROPERTY(FocusHashtagEntryList entries READ getEntries NOTIFY entriesChanged FINAL)

public:
    static constexpr int MAX_ENTRIES = 100;

    explicit FocusHashtags(QObject* parent = nullptr);

    QJsonDocument toJson() const;
    void setEntries(const QJsonDocument& json);

    void clear();
    const FocusHashtagEntryList& getEntries() const { return mEntries; }
    void addEntry(FocusHashtagEntry* entry);
    void removeEntry(int entryId);

    bool match(const NormalizedWordIndex& post) const override;

signals:
    void entriesChanged();

private:
    FocusHashtagEntryList mEntries;
    std::unordered_map<QString, int> mAllHashtags;
};

}
