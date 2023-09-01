// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "post.h"

namespace Skywalker {

int Post::sNextGapId = 1;

Post Post::createGapPlaceHolder(const QString& gapCursor)
{
    Post post;
    post.mGapCursor = gapCursor;
    post.mGapId = sNextGapId++;
    return post;
}

Post::Post(const ATProto::AppBskyFeed::FeedViewPost* feedViewPost, int rawIndex) :
    mFeedViewPost(feedViewPost),
    mRawIndex(rawIndex)
{
    Q_ASSERT((feedViewPost && rawIndex >= 0) || (!feedViewPost && rawIndex == -1));

    if (feedViewPost)
        mPost = feedViewPost->mPost.get();
}

Post::Post(const ATProto::AppBskyFeed::PostView* postView, int rawIndex) :
    mPost(postView),
    mRawIndex(rawIndex)
{
    Q_ASSERT(postView);
}

const QString& Post::getCid() const
{
    static const QString NO_STRING;
    return mPost ? mPost->mCid : NO_STRING;
}

QString Post::getText() const
{
    static const QString NO_STRING;

    if (!mPost)
        return NO_STRING;

    if (mPost->mRecordType == ATProto::RecordType::APP_BSKY_FEED_POST)
    {
        const auto& record = std::get<ATProto::AppBskyFeed::Record::Post::Ptr>(mPost->mRecord);

        if (record->mFacets.empty())
            return record->mText.toHtmlEscaped();
        else
            return ATProto::AppBskyRichtext::applyFacets(record->mText, record->mFacets);
    }

    return NO_STRING;
}

BasicProfile Post::getAuthor() const
{
    return mPost ? BasicProfile(mPost->mAuthor.get()) : BasicProfile();
}

QDateTime Post::getIndexedAt() const
{
    if (!mPost)
        return {};

    // NOTE: the createdAt timestamp is not reliable as clients can put in a local timestamp
    // without timezone (seen in feeds)
    return mPost->mIndexedAt;
}

QDateTime Post::getTimelineTimestamp() const
{
    if (!mReplyRefTimestamp.isNull())
        return mReplyRefTimestamp;

    if (mFeedViewPost && mFeedViewPost->mReason)
        return mFeedViewPost->mReason->mIndexedAt;

    return getIndexedAt();
}

bool Post::isRepost() const
{
    return mFeedViewPost && mFeedViewPost->mReason;
}

std::optional<BasicProfile> Post::getRepostedBy() const
{
    if (!isRepost())
        return {};

    return BasicProfile(mFeedViewPost->mReason->mBy.get());
}

bool Post::isReply() const
{
    return mFeedViewPost && mFeedViewPost->mReply;
}


std::optional<PostReplyRef> Post::getReplyRef() const
{
    if (!mPost)
        return {};

    if (!isReply())
        return {};

    const auto& reply = *mFeedViewPost->mReply;
    PostReplyRef replyRef;
    replyRef.mRoot = Post(reply.mRoot.get(), mRawIndex);
    replyRef.mParent = Post(reply.mParent.get(), mRawIndex);

    // Set the reference timestamp to the timestap of this reply post.
    // They show up together with this reply post.
    replyRef.mRoot.mReplyRefTimestamp = getTimelineTimestamp();
    replyRef.mParent.mReplyRefTimestamp = getTimelineTimestamp();

    return replyRef;
}

std::optional<BasicProfile> Post::getReplyToAuthor() const
{
    if (!mPost)
        return {};

    if (mReplyToAuthor)
        return mReplyToAuthor;

    if (!isReply())
        return {};

    const auto& reply = *mFeedViewPost->mReply;
    return BasicProfile(reply.mParent->mAuthor.get());
}

QString Post::getReplyToCid() const
{
    if (!mPost)
        return {};

    if (isReply())
        return mFeedViewPost->mReply->mParent->mCid;

    if (mPost->mRecordType != ATProto::RecordType::APP_BSKY_FEED_POST)
        return {};

    const auto& record = std::get<ATProto::AppBskyFeed::Record::Post::Ptr>(mPost->mRecord);

    if (!record->mReply)
        return {};

    return record->mReply->mParent->mCid;
}

QString Post::getReplyToAuthorDid() const
{
    if (!mPost)
        return {};

    if (mPost->mRecordType != ATProto::RecordType::APP_BSKY_FEED_POST)
        return {};

    const auto& record = std::get<ATProto::AppBskyFeed::Record::Post::Ptr>(mPost->mRecord);

    if (!record->mReply)
        return {};

    const auto& uri = record->mReply->mParent->mUri;

    if (!uri.startsWith("at://did:"))
        return {};

    const auto did = "TODO";

    qDebug() << "uri:" << uri << "did:" << did;
    return did;
}

std::vector<ImageView::Ptr> Post::getImages() const
{
    if (!mPost)
        return {};

    if (!mPost->mEmbed || mPost->mEmbed->mType != ATProto::AppBskyEmbed::EmbedType::IMAGES_VIEW)
        return {};

    const auto& imagesView = std::get<ATProto::AppBskyEmbed::ImagesView::Ptr>(mPost->mEmbed->mEmbed);
    std::vector<ImageView::Ptr> images;

    for (const auto& img : imagesView->mImages)
        images.push_back(std::make_unique<ImageView>(img.get()));

    return images;
}

ExternalView::Ptr Post::getExternalView() const
{
    if (!mPost)
        return {};

    if (!mPost->mEmbed || mPost->mEmbed->mType != ATProto::AppBskyEmbed::EmbedType::EXTERNAL_VIEW)
        return {};

    const auto& external = std::get<ATProto::AppBskyEmbed::ExternalView::Ptr>(mPost->mEmbed->mEmbed)->mExternal;
    return std::make_unique<ExternalView>(external.get());
}

RecordView::Ptr Post::getRecordView() const
{
    if (!mPost)
        return {};

    if (!mPost->mEmbed || mPost->mEmbed->mType != ATProto::AppBskyEmbed::EmbedType::RECORD_VIEW)
        return {};

    const auto& recordView = std::get<ATProto::AppBskyEmbed::RecordView::Ptr>(mPost->mEmbed->mEmbed);
    return std::make_unique<RecordView>(*recordView);
}

RecordWithMediaView::Ptr Post::getRecordWithMediaView() const
{
    if (!mPost)
        return {};

    if (!mPost->mEmbed || mPost->mEmbed->mType != ATProto::AppBskyEmbed::EmbedType::RECORD_WITH_MEDIA_VIEW)
        return {};

    const auto& recordView = std::get<ATProto::AppBskyEmbed::RecordWithMediaView::Ptr>(mPost->mEmbed->mEmbed);
    return std::make_unique<RecordWithMediaView>(recordView.get());
}

}
