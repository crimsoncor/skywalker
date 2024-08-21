// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#pragma once
#include "abstract_post_feed_model.h"
#include "generator_view.h"
#include "muted_words.h"
#include <atproto/lib/user_preferences.h>
#include <map>
#include <unordered_map>
#include <unordered_set>

namespace Skywalker {

class PostFeedModel : public AbstractPostFeedModel
{
    Q_OBJECT
    Q_PROPERTY(QString feedName READ getFeedName CONSTANT FINAL)
    Q_PROPERTY(bool languageFilterConfigured READ isLanguageFilterConfigured NOTIFY languageFilterConfiguredChanged FINAL)
    Q_PROPERTY(bool languageFilterEnabled READ isLanguageFilterEnabled WRITE enableLanguageFilter NOTIFY languageFilterEnabledChanged FINAL)
    Q_PROPERTY(LanguageList filteredLanguages READ getFilterdLanguages NOTIFY languageFilterConfiguredChanged FINAL)
    Q_PROPERTY(bool showPostWithMissingLanguage READ showPostWithMissingLanguage NOTIFY languageFilterConfiguredChanged)

public:
    using Ptr = std::unique_ptr<PostFeedModel>;

    explicit PostFeedModel(const QString& feedName,
                           const QString& userDid, const IProfileStore& following,
                           const IProfileStore& mutedReposts,
                           const ContentFilter& contentFilter,
                           const Bookmarks& bookmarks,
                           const MutedWords& mutedWords,
                           const FocusHashtags& focusHashtags,
                           HashtagIndex& hashtags,
                           const ATProto::UserPreferences& userPrefs,
                           const UserSettings& userSettings,
                           QObject* parent = nullptr);

    const QString& getFeedName() const { return mFeedName; }

    Q_INVOKABLE const GeneratorView getGeneratorView() const { return mGeneratorView; }
    void setGeneratorView(const GeneratorView& view) { mGeneratorView = view; }

    Q_INVOKABLE const ListViewBasic getListView() const { return mListView; }
    void setListView(const ListViewBasic& view) { mListView = view; }

    bool isLanguageFilterConfigured() const;
    void enableLanguageFilter(bool enabled);
    bool isLanguageFilterEnabled() const { return mLanguageFilterEnabled; }
    LanguageList getFilterdLanguages() const;
    bool showPostWithMissingLanguage() const;

    // Return the new index of the current top post.
    // If the feed was empty then -1 is returned.
    int setFeed(ATProto::AppBskyFeed::OutputFeed::SharedPtr&& feed);

    void addFeed(ATProto::AppBskyFeed::OutputFeed::SharedPtr&& feed);

    // Returns gap id if prepending created a gap in the feed.
    // Returns 0 otherwise.
    int prependFeed(ATProto::AppBskyFeed::OutputFeed::SharedPtr&& feed);

    // Returns new gap id if the gap was not fully filled, i.e. there is a new gap.
    // Returns 0 otherwise.
    int gapFillFeed(ATProto::AppBskyFeed::OutputFeed::SharedPtr&& feed, int gapId);

    void removeTailPosts(int size);
    void removeHeadPosts(int size);
    void removePosts(int startIndex, int size);

    QString getLastCursor() const;
    const Post* getGapPlaceHolder(int gapId) const;
    void clearLastInsertedRowIndex() { mLastInsertedRowIndex = -1; }
    int getLastInsertedRowIndex() const { return mLastInsertedRowIndex; }

    // Get the timestamp of the last post in the feed
    QDateTime lastTimestamp() const;

    // Returns the index of the first post <= timestamp
    int findTimestamp(QDateTime timestamp) const;

    void clear();

signals:
    void languageFilterConfiguredChanged();
    void languageFilterEnabledChanged();

private:
    struct CidTimestamp
    {
        QString mCid;
        QDateTime mTimestamp;
        QString mRepostedByDid;
        QEnums::PostType mPostType;
    };

    struct Page
    {
        using Ptr = std::unique_ptr<Page>;
        std::vector<Post> mFeed;
        QString mCursorNextPage;
        std::unordered_set<QString> mAddedCids;
        std::unordered_map<QString, int> mParentIndexMap;
        bool mOverlapsWithFeed = false;

        void addPost(const Post& post, bool isParent = false);
        bool cidAdded(const QString& cid) const { return mAddedCids.count(cid); }
        bool tryAddToExistingThread(const Post& post, const PostReplyRef& replyRef);
    };

    virtual bool mustHideContent(const Post& post) const override;
    bool passLanguageFilter(const Post& post) const;
    bool mustShowReply(const Post& post, const std::optional<PostReplyRef>& replyRef) const;
    bool mustShowQuotePost(const Post& post) const;
    Page::Ptr createPage(ATProto::AppBskyFeed::OutputFeed::SharedPtr&& feed);
    void insertPage(const TimelineFeed::iterator& feedInsertIt, const Page& page, int pageSize);

    // Returns gap id if insertion created a gap in the feed.
    int insertFeed(ATProto::AppBskyFeed::OutputFeed::SharedPtr&& feed, int insertIndex);

    // Returns an index in the page feed
    std::optional<size_t> findOverlapStart(const Page& page, size_t feedIndex) const;

    // Return an index in mFeed
    std::optional<size_t> findOverlapEnd(const Page& page, size_t feedIndex) const;

    void addToIndices(size_t offset, size_t startAtIndex);
    void logIndices() const;
    void setTopNCids();
    int topNPostIndex(const Post& post, bool checkTimestamp) const;

    const ATProto::UserPreferences& mUserPreferences;
    const UserSettings& mUserSettings;
    bool mLanguageFilterEnabled = false;

    // The index is the last (non-filtered) post from a received page. The cursor is to get
    // the next page.
    std::map<size_t, QString> mIndexCursorMap; // cursor to post at next index

    // Index of each gap
    std::unordered_map<int, size_t> mGapIdIndexMap;

    // The top N cids from the posts in the feed before last clear.
    std::vector<CidTimestamp> mTopNCids;

    // Number of posts that have been prepended to the feed since the last clear.
    size_t mPrependPostCount = 0;

    int mLastInsertedRowIndex = -1;
    QString mFeedName;
    GeneratorView mGeneratorView;
    ListViewBasic mListView;
};

}
