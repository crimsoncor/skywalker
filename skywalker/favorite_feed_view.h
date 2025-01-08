// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#pragma once
#include "enums.h"
#include "generator_view.h"
#include "list_view.h"
#include "search_feed_view.h"

namespace Skywalker {

class FavoriteFeedView
{
    Q_GADGET
    Q_PROPERTY(QEnums::FavoriteType type READ getType FINAL)
    Q_PROPERTY(QString uri READ getUri FINAL)
    Q_PROPERTY(QString name READ getName FINAL)
    Q_PROPERTY(QString avatar READ getAvatar FINAL)
    Q_PROPERTY(QString avatarThumb READ getAvatarThumb FINAL)
    Q_PROPERTY(GeneratorView generatorView READ getGeneratorView FINAL)
    Q_PROPERTY(ListView listView READ getListView FINAL)
    Q_PROPERTY(SearchFeedView searchFeedView READ getSearchFeedView FINAL)
    QML_VALUE_TYPE(favoritefeedview)

public:
    FavoriteFeedView() = default;
    explicit FavoriteFeedView(const GeneratorView& generatorView);
    explicit FavoriteFeedView(const ListView& listView);
    explicit FavoriteFeedView(const SearchFeedView& searchFeedView);

    Q_INVOKABLE bool isNull() const { return mView.index() == 0 && std::get<0>(mView).isNull(); }
    QEnums::FavoriteType getType() const;
    QString getUri() const;
    QString getName() const;
    QString getAvatar() const;
    QString getAvatarThumb() const;
    GeneratorView getGeneratorView() const;
    ListView getListView() const;
    SearchFeedView getSearchFeedView() const;

private:
    std::variant<GeneratorView, ListView, SearchFeedView> mView;
};

}

Q_DECLARE_METATYPE(::Skywalker::FavoriteFeedView)
