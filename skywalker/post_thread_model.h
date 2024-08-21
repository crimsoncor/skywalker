// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#pragma once
#include "abstract_post_feed_model.h"
#include "muted_words.h"

namespace Skywalker {

class PostThreadModel : public AbstractPostFeedModel
{
    Q_OBJECT
    Q_PROPERTY(QEnums::ReplyRestriction replyRestriction READ getReplyRestriction NOTIFY threadReplyRestrictionChanged FINAL)
    Q_PROPERTY(BasicProfile replyRestrictionAuthor READ getReplyRestrictionAuthor NOTIFY threadReplyRestrictionChanged FINAL)
    Q_PROPERTY(ListViewBasicList replyRestrictionLists READ getReplyRestrictionLists NOTIFY threadReplyRestrictionListsChanged FINAL)

public:
    using Ptr = std::unique_ptr<PostThreadModel>;

    explicit PostThreadModel(const QString& userDid, const IProfileStore& following,
                             const IProfileStore& mutedReposts,
                             const ContentFilter& contentFilter, const Bookmarks& bookmarks,
                             const MutedWords& mutedWords, const FocusHashtags& focusHashtags,
                             HashtagIndex& hashtags,
                             QObject* parent = nullptr);

    // Returns index of the entry post
    int setPostThread(ATProto::AppBskyFeed::PostThread::SharedPtr&& thread);

    // May return UNKNOWN if there are reply restrictions. This will happen
    // if the root is not in the thread, but the first post has replies disabled.
    QEnums::ReplyRestriction getReplyRestriction() const;
    BasicProfile getReplyRestrictionAuthor() const;
    ListViewBasicList getReplyRestrictionLists() const;

    Q_INVOKABLE QVariant getData(int row, AbstractPostFeedModel::Role role);

signals:
    void threadReplyRestrictionChanged();
    void threadReplyRestrictionListsChanged();

protected:
    virtual void replyRestrictionChanged() override;
    virtual void replyRestrictionListsChanged() override;

private:
    struct Page
    {
        using Ptr = std::unique_ptr<Page>;

        explicit Page(PostThreadModel& postFeedModel) : mPostFeedModel(postFeedModel) {}

        std::deque<Post> mFeed;
        ATProto::AppBskyFeed::PostThread::SharedPtr mRawThread;
        int mEntryPostIndex = 0;
        PostThreadModel& mPostFeedModel;

        Post& addPost(const Post& post);
        Post& prependPost(const Post& post);
        void addReplyThread(const ATProto::AppBskyFeed::ThreadElement& reply, bool directReply, bool firstDirectReply);
    };

    void clear();
    void sortReplies(ATProto::AppBskyFeed::ThreadViewPost* viewPost) const;
    Page::Ptr createPage(ATProto::AppBskyFeed::PostThread::SharedPtr&& thread);
    void insertPage(const TimelineFeed::iterator& feedInsertIt, const Page& page, int pageSize);
};

}
