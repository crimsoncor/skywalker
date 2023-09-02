// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#pragma once
#include "enums.h"
#include "external_view.h"
#include "image_view.h"
#include "profile.h"
#include "record_view.h"
#include "record_with_media_view.h"
#include <atproto/lib/lexicon/app_bsky_feed.h>


namespace Skywalker {

struct PostReplyRef;

class Post
{
public:
    // A gap place holder is created to represent a gap in the timeline, i.e.
    // missing posts that have not been retrieved. The gapCursor can be use
    // to fetch those posts.
    static Post createGapPlaceHolder(const QString& gapCursor);

    explicit Post(const ATProto::AppBskyFeed::FeedViewPost* feedViewPost = nullptr, int rawIndex = -1);
    Post(const ATProto::AppBskyFeed::PostView* postView, int rawIndex);

    bool isPlaceHolder() const { return !mPost; }
    int getRawIndex() const { return mRawIndex; }
    bool isEndOfFeed() const { return mEndOfFeed; }
    int getGapId() const { return mGapId; }
    const QString& getGapCursor() const { return mGapCursor; }
    QEnums::PostType getPostType() const { return mPostType; }
    bool isParentInThread() const { return mParentInThread; }

    const QString& getCid() const;

    // The indexedAt of a post or repost
    QDateTime getTimelineTimestamp() const;

    void setReplyRefTimestamp(const QDateTime& timestamp) { mReplyRefTimestamp = timestamp; }

    QString getText() const;
    BasicProfile getAuthor() const;
    QDateTime getIndexedAt() const;
    bool isRepost() const;
    std::optional<BasicProfile> getRepostedBy() const;
    bool isReply() const;
    std::optional<PostReplyRef> getViewPostReplyRef() const;
    std::optional<BasicProfile> getReplyToAuthor() const;
    QString getReplyToCid() const;
    QString getReplyToAuthorDid() const;

    std::vector<ImageView::Ptr> getImages() const;
    ExternalView::Ptr getExternalView() const;
    RecordView::Ptr getRecordView() const;
    RecordWithMediaView::Ptr getRecordWithMediaView() const;

    void setEndOfFeed(bool end) { mEndOfFeed = end; }
    void setPostType(QEnums::PostType postType) { mPostType = postType; }
    void setParentInThread(bool parentInThread) { mParentInThread = parentInThread; }
    void setReplyToAuthor(const BasicProfile& profile) { mReplyToAuthor = profile; }

private:
    struct HyperLink
    {
        int mStart;
        int mEnd;
        QString mText;
    };

    // null is place holder for more posts (gap)
    const ATProto::AppBskyFeed::PostView* mPost = nullptr;

    // null if the post represents a reply ref.
    const ATProto::AppBskyFeed::FeedViewPost* mFeedViewPost = nullptr;

    // Index in the vector of raw feed view posts
    int mRawIndex = -1;

    int mGapId = 0;

    // cursor to get more posts to fill the gap
    QString mGapCursor;

    bool mEndOfFeed = false;
    QEnums::PostType mPostType = QEnums::POST_STANDALONE;

    // Timestamp to keep reply referenes in time sequence for the timeline
    QDateTime mReplyRefTimestamp;

    // For posts not having all parent informations, the reply-to-author may
    // inferred from through other posts.
    std::optional<BasicProfile> mReplyToAuthor;
    bool mParentInThread = false;

    static int sNextGapId;
};

struct PostReplyRef
{
    Post mRoot;
    Post mParent;
};

}
