// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "author_list_model.h"

namespace Skywalker {

AuthorListModel::AuthorListModel(Type type, const QString& atId, QObject* parent) :
    QAbstractListModel(parent),
    mType(type),
    mAtId(atId)
{
}

int AuthorListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return mList.size();
}

QVariant AuthorListModel::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() >= mList.size())
        return {};

    const auto& author = mList[index.row()];
    const auto* change = getLocalChange(author.getDid());

    switch (Role(role))
    {
    case Role::Author:
        return QVariant::fromValue(author);
    case Role::FollowingUri:
        return change && change->mFollowingUri ? *change->mFollowingUri : author.getViewer().getFollowing();
    case Role::BlockingUri:
        return change && change->mBlockingUri ? *change->mBlockingUri : author.getViewer().getBlocking();
    }

    qWarning() << "Uknown role requested:" << role;
    return {};
}

void AuthorListModel::clear()
{
    beginRemoveRows({}, 0, mList.size() - 1);
    mList.clear();
    clearLocalChanges();
    endRemoveRows();

    mCursor.clear();
}

void AuthorListModel::addAuthors(ATProto::AppBskyActor::ProfileViewList authors, const QString& cursor)
{
    qDebug() << "Add authors:" << authors.size() << "cursor:" << cursor;
    mCursor = cursor;
    const size_t newRowCount = mList.size() + authors.size();

    beginInsertRows({}, mList.size(), newRowCount - 1);

    for (const auto& author : authors)
        mList.push_back(Profile(author.get()));

    endInsertRows();

    mRawLists.push_back(std::forward<ATProto::AppBskyActor::ProfileViewList>(authors));
    qDebug() << "New list size:" << mList.size();
}

QHash<int, QByteArray> AuthorListModel::roleNames() const
{
    static const QHash<int, QByteArray> roles{
        { int(Role::Author), "author" },
        { int(Role::FollowingUri), "followingUri" },
        { int(Role::BlockingUri), "blockingUri" }
    };

    return roles;
}

void AuthorListModel::blockingUriChanged()
{
    changeData({ int(Role::BlockingUri) });
}

void AuthorListModel::followingUriChanged()
{
    changeData({ int(Role::FollowingUri) });
}

void AuthorListModel::changeData(const QList<int>& roles)
{
    emit dataChanged(createIndex(0, 0), createIndex(mList.size() - 1, 0), roles);
}

}
