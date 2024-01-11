// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#include "favorite_feed_view.h"

namespace Skywalker {

FavoriteFeedView::FavoriteFeedView(const GeneratorView& generatorView) :
    mGeneratorView(generatorView)
{
}

FavoriteFeedView::FavoriteFeedView(const ListView& listView) :
    mListView(listView)
{
}

QString FavoriteFeedView::getName() const
{
    return isGeneratorView() ? mGeneratorView.getDisplayName() : mListView.getName();
}

QString FavoriteFeedView::getAvatar() const
{
    return isGeneratorView() ? mGeneratorView.getAvatar() : mListView.getAvatar();
}

}
