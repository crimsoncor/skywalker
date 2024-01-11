// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#pragma once
#include "feed_list_model.h"
#include "favorite_feed_view.h"
#include "generator_view.h"
#include "list_view.h"
#include <atproto/lib/user_preferences.h>
#include <QObject>
#include <unordered_set>

namespace Skywalker {

class Skywalker;

class FavoriteFeeds : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QList<FavoriteFeedView> pinnedFeeds READ getPinnedFeeds NOTIFY pinnedFeedsChanged FINAL)
    Q_PROPERTY(bool updateSavedFeedsModelInProgress READ getUpdateSavedFeedsModelInProgress NOTIFY updateSavedFeedsModelInProgressChanged FINAL)

public:
    explicit FavoriteFeeds(Skywalker* skywalker, QObject* parent = nullptr);
    ~FavoriteFeeds();

    void clear();
    void reset(const ATProto::UserPreferences::SavedFeedsPref& savedFeedsPref);

    Q_INVOKABLE bool isSavedFeed(const QString& uri) const { return mSavedUris.count(uri); }
    Q_INVOKABLE bool isPinnedFeed(const QString& uri) const { return mPinnedUris.count(uri); }

    Q_INVOKABLE void addFeed(const GeneratorView& feed);
    Q_INVOKABLE void removeFeed(const GeneratorView& feed);
    Q_INVOKABLE void pinFeed(const GeneratorView& feed, bool pin);

    const QList<FavoriteFeedView>& getPinnedFeeds() const { return mPinnedFeeds; }

    bool getUpdateSavedFeedsModelInProgress() const { return mUpdateSavedFeedsModelInProgress; }
    void setUpdateSavedFeedsModelInProgress(bool inProgress);

    Q_INVOKABLE FeedListModel* getSavedFeedsModel();
    Q_INVOKABLE void removeSavedFeedsModel();

    void saveTo(ATProto::UserPreferences& userPreferences) const;

signals:
    void feedSaved();
    void feedPinned();
    void pinnedFeedsChanged();
    void updateSavedFeedsModelInProgressChanged();

private:
    void setFeeds(QList<GeneratorView>& feeds, ATProto::AppBskyFeed::GeneratorViewList&& generators);
    void setFeeds(QList<FavoriteFeedView>& feeds, ATProto::AppBskyFeed::GeneratorViewList&& generators);
    void pinFeed(const GeneratorView& feed);
    void unpinFeed(const GeneratorView& feed);
    void setSavedFeeds(ATProto::AppBskyFeed::GeneratorViewList&& savedGenerators);
    void setPinnedFeeds(ATProto::AppBskyFeed::GeneratorViewList&& pinnedGenerators);
    void addPinnedFeed(const ATProto::AppBskyGraph::ListView::SharedPtr& pinnedList);
    void updateSavedViews();
    void updateSavedGeneratorViews();
    void updateSavedListViews();
    void updateSavedListViews(std::vector<QString> listUris);
    void updatePinnedViews();
    void updatePinnedGeneratorViews();
    void updatePinnedListViews();
    void updatePinnedListViews(std::vector<QString> listUris);
    void updateSavedFeedsModel();
    std::vector<QString> filterUris(const std::vector<QString> uris, char const* collection) const;

    ATProto::UserPreferences::SavedFeedsPref mSavedFeedsPref;
    std::unordered_set<QString> mSavedUris;
    std::unordered_set<QString> mPinnedUris;
    QList<GeneratorView> mSavedFeeds; // sorted by name
    QList<ListView> mSavedLists; // sorted by name
    QList<FavoriteFeedView> mPinnedFeeds; // sorted by name
    int mSavedFeedsModelId = -1;
    bool mUpdateSavedFeedsModelInProgress = false;
    Skywalker* mSkywalker;
};

}
