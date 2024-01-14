// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#pragma once
#include "list_view.h"
#include "local_list_model_changes.h"
#include <QAbstractListModel>
#include <deque>

namespace Skywalker {

class FavoriteFeeds;

class ListListModel : public QAbstractListModel, public LocalListModelChanges
{
    Q_OBJECT
public:
    enum class Role {
        List = Qt::UserRole + 1,
        ListCreator,
        ListBlockedUri,
        ListMuted,
        ListSaved,
        ListPinned
    };

    using Type = QEnums::ListType;
    using Purpose = QEnums::ListPurpose;
    using Ptr = std::unique_ptr<ListListModel>;

    ListListModel(Type type, Purpose purpose, const QString& atId, const FavoriteFeeds& favoriteFeeds, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    void clear();

    // Returns the number of lists added
    int addLists(ATProto::AppBskyGraph::ListViewList lists, const QString& cursor);
    void addLists(const QList<ListView>& lists);
    Q_INVOKABLE void prependList(const ListView& list);
    Q_INVOKABLE void updateEntry(int index, const QString& cid, const QString& name, const QString& description, const QString& avatar);
    Q_INVOKABLE void deleteEntry(int index);

    const QString& getCursor() const { return mCursor; }
    bool isEndOfList() const { return mCursor.isEmpty(); }

    Type getType() const { return mType; }
    Q_INVOKABLE Purpose getPurpose() const { return mPurpose; }
    const QString& getAtId() const { return mAtId; }

protected:
    QHash<int, QByteArray> roleNames() const override;
    virtual void blockedChanged() override;
    virtual void mutedChanged() override;

private:
    using ListList = std::deque<ListView>;

    void listSavedChanged();
    void listPinnedChanged();
    void changeData(const QList<int>& roles);

    ListList filterLists(ATProto::AppBskyGraph::ListViewList lists) const;

    Type mType;
    Purpose mPurpose;
    QString mAtId;
    ListList mLists;
    QString mCursor;
    const FavoriteFeeds& mFavoriteFeeds;
};

}
