// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#pragma once
#include "bookmarks.h"
#include "content_filter.h"
#include "local_post_model_changes.h"
#include "muted_words.h"
#include "notification.h"
#include "post_cache.h"
#include <atproto/lib/client.h>
#include <QAbstractListModel>
#include <deque>

namespace Skywalker {

class InviteCodeStore;

class NotificationListModel : public QAbstractListModel, public LocalPostModelChanges
{
    Q_OBJECT
    Q_PROPERTY(bool priority READ getPriority NOTIFY priorityChanged FINAL)

public:
    using NotificationList = std::deque<Notification>;

    enum class Role {
        NotificationAuthor = Qt::UserRole + 1,
        NotificationOtherAuthors,
        NotificationAllAuthors,
        NotificationReason,
        NotificationReasonSubjectUri,
        NotificationReasonSubjectCid,
        NotificationReasonPostText,
        NotificationReasonPostPlainText,
        NotificationReasonPostIsReply,
        NotificationReasonPostReplyToAuthor,
        NotificationReasonPostLanguages,
        NotificationReasonPostTimestamp,
        NotificationReasonPostImages,
        NotificationReasonPostExternal,
        NotificationReasonPostRecord,
        NotificationReasonPostRecordWithMedia,
        NotificationReasonPostNotFound,
        NotificationReasonPostLabels,
        NotificationReasonPostLocallyDeleted,
        NotificationTimestamp,
        NotificationIsRead,
        NotificationPostUri,
        NotificationCid,
        NotificationPostAuthor,
        NotificationPostText,
        NotificationPostPlainText,
        NotificationPostLanguages,
        NotificationPostTimestamp,
        NotificationPostImages,
        NotificationPostExternal,
        NotificationPostRecord,
        NotificationPostRecordWithMedia,
        NotificationPostReplyRootUri,
        NotificationPostReplyRootCid,
        NotificationPostRepostUri,
        NotificationPostLikeUri,
        NotificationPostLikeTransient,
        NotificationPostThreadMuted,
        NotificationPostReplyDisabled,
        NotificationPostThreadgateUri,
        NotificationPostReplyRestriction,
        NotificationPostReplyRestrictionLists,
        NotificationPostRepostCount,
        NotificationPostLikeCount,
        NotificationPostReplyCount,
        NotificationPostBookmarked,
        NotificationPostNotFound,
        NotificationPostLabels,
        NotificationPostContentVisibility,
        NotificationPostContentWarning,
        NotificationPostMutedReason,
        NotificationPostIsReply,
        ReplyToAuthor,
        NotificationInviteCode,
        NotificationInviteCodeUsedBy,
        EndOfList
    };

    explicit NotificationListModel(const ContentFilter& contentFilter, const Bookmarks& bookmarks,
                                   const MutedWords& mutedWords, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    void clear();
    bool addNotifications(ATProto::AppBskyNotification::ListNotificationsOutput::SharedPtr notifications,
                          ATProto::Client& bsky, bool clearFirst = false,
                          const std::function<void()>& doneCb = nullptr);
    QString addNotifications(ATProto::ChatBskyConvo::ConvoListOutput::SharedPtr convoListOutput,
                          const QString& lastRev, const QString& userDid);
    const QString& getCursor() const { return mCursor; }
    bool getPriority() const { return mPriority; }
    void setPriority(bool priority);
    bool isEndOfList() const { return mCursor.isEmpty(); }

    Q_INVOKABLE bool notificationsLoaded() const { return !mList.empty(); }

    Q_INVOKABLE void addInviteCodeUsageNofications(InviteCodeStore* inviteCodeStore);
    Q_INVOKABLE void dismissInviteCodeUsageNotification(int index);
    int getInviteCodeUsageNotificationCount() const { return (int)mInviteCodeUsedNotifications.size(); }

    int addNewLabelsNotifications(const std::unordered_map<QString, BasicProfile>& labelerProfiles);
    int getNewLabelsNotificationCount() const { return (int)mNewLabelsNotifications.size(); }

    int getUnreadCount() const;
    void setNotificationsSeen(bool seen);
    Q_INVOKABLE void updateRead();

    const NotificationList& getNotifications() const { return mList; }
    const PostCache& getReasonPostCache() const { return mReasonPostCache; }
    void enableRetrieveNotificationPosts(bool enable) { mRetrieveNotificationPosts = enable; }

signals:
    void priorityChanged();

protected:
    virtual void postIndexTimestampChanged() override;
    virtual void likeCountChanged() override;
    virtual void likeUriChanged() override;
    virtual void likeTransientChanged() override;
    virtual void replyCountChanged() override;
    virtual void repostCountChanged() override;
    virtual void repostUriChanged() override;
    virtual void threadgateUriChanged() override;
    virtual void replyRestrictionChanged() override;
    virtual void replyRestrictionListsChanged() override;
    virtual void threadMutedChanged() override;
    virtual void postDeletedChanged() override;

    QHash<int, QByteArray> roleNames() const override;

private:
    NotificationList createNotificationList(const ATProto::AppBskyNotification::NotificationList& rawList) const;
    void filterNotificationList(NotificationList& list) const;
    void addNotificationList(const NotificationList& list, bool clearFirst);

    // Get the posts for LIKE, FOLLOW and REPOST notifications
    void getPosts(ATProto::Client& bsky, const NotificationList& list, const std::function<void()>& cb);
    void getPosts(ATProto::Client& bsky, std::unordered_set<QString> uris, const std::function<void()>& cb);

    void postBookmarkedChanged();
    void changeData(const QList<int>& roles);
    void clearLocalState();
    void clearRows();
    void addInviteCodeUsageNotificationRows();
    void addNewLabelsNotificationRows();
    void updateNewLabelsNotifications();
    void updateInviteCodeUser(const BasicProfile& profile);

    const ContentFilter& mContentFilter;
    const Bookmarks& mBookmarks;
    const MutedWords& mMutedWords;

    NotificationList mList;
    QString mCursor;
    bool mPriority = false;

    // This cache must be emptied when the notifications are refreshed, because
    // the counts (like, reposts, replies) will change over time and are displayed.
    PostCache mPostCache;
    bool mRetrieveNotificationPosts = true;

    // Posts in this cache can be kept for a long time
    PostCache mReasonPostCache;

    NotificationList mInviteCodeUsedNotifications;
    NotificationList mNewLabelsNotifications;
    bool mNotificationsSeen = false;
};

}
