// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "skywalker.h"
#include "author_cache.h"
#include "jni_callback.h"
#include "photo_picker.h"
#include "post_utils.h"
#include "shared_image_provider.h"
#include <atproto/lib/at_uri.h>
#include <QClipboard>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QSettings>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QtCore/private/qandroidextras_p.h>
#endif

namespace Skywalker {

using namespace std::chrono_literals;

static constexpr auto SESSION_REFRESH_INTERVAL = 299s;
static constexpr auto NOTIFICATION_REFRESH_INTERVAL = 29s;
static constexpr int TIMELINE_ADD_PAGE_SIZE = 50;
static constexpr int TIMELINE_PREPEND_PAGE_SIZE = 20;
static constexpr int TIMELINE_SYNC_PAGE_SIZE = 100;
static constexpr int TIMELINE_DELETE_SIZE = 100; // must not be smaller than add/sync
static constexpr int NOTIFICATIONS_ADD_PAGE_SIZE = 25;
static constexpr int AUTHOR_FEED_ADD_PAGE_SIZE = 100; // Most posts are replies and are filtered
static constexpr int AUTHOR_LIST_ADD_PAGE_SIZE = 50;

Skywalker::Skywalker(QObject* parent) :
    QObject(parent),
    mContentFilter(mUserPreferences),
    mMutedWords(this),
    mTimelineModel(mUserDid, mUserFollows, mContentFilter, mBookmarks, mMutedWords, mUserPreferences, this),
    mNotificationListModel(mContentFilter, mBookmarks, mMutedWords, this),
    mUserSettings(this)
{
    connect(&mBookmarks, &Bookmarks::sizeChanged, this, [this]{ mBookmarks.save(&mUserSettings); });
    connect(&mRefreshTimer, &QTimer::timeout, this, [this]{ refreshSession(); });
    connect(&mRefreshNotificationTimer, &QTimer::timeout, this, [this]{ refreshNotificationCount(); });
    AuthorCache::instance().addProfileStore(&mUserFollows);

    auto& jniCallbackListener = JNICallbackListener::getInstance();
    connect(&jniCallbackListener, &JNICallbackListener::sharedTextReceived, this,
            [this](const QString& text){ emit sharedTextReceived(text); });
    connect(&jniCallbackListener, &JNICallbackListener::sharedImageReceived, this,
            [this](const QString& contentUri, const QString& text){ shareImage(contentUri, text); });
    connect(&jniCallbackListener, &JNICallbackListener::fcmToken, this,
            [this](const QString& token){ registerPushNotifications(token); });
}

Skywalker::~Skywalker()
{
    Q_ASSERT(mPostThreadModels.empty());
    Q_ASSERT(mAuthorFeedModels.empty());
    Q_ASSERT(mSearchPostFeedModels.empty());
    Q_ASSERT(mAuthorListModels.empty());
}

// NOTE: user can be handle or DID
void Skywalker::login(const QString user, QString password, const QString host)
{
    qDebug() << "Login:" << user << "host:" << host;
    auto xrpc = std::make_unique<Xrpc::Client>(host);
    mBsky = std::make_unique<ATProto::Client>(std::move(xrpc));
    mBsky->createSession(user, password,
        [this, host, user, password]{
            qDebug() << "Login" << user << "succeeded";
            const auto* session = mBsky->getSession();
            updateUser(session->mDid, host, password);
            saveSession(*session);
            emit loginOk();
            startRefreshTimers();
        },
        [this, host, user](const QString& error, const QString& msg){
            qDebug() << "Login" << user << "failed:" << error << " - " << msg;
            mUserSettings.setActiveUserDid({});
            emit loginFailed(msg, host, user);
        });
}

void Skywalker::resumeSession()
{
    qDebug() << "Resume session";
    QString host;
    ATProto::ComATProtoServer::Session session;

    if (!getSession(host, session))
    {
        qWarning() << "No saved session";
        emit resumeSessionFailed("");
        return;
    }

    auto xrpc = std::make_unique<Xrpc::Client>(host);
    mBsky = std::make_unique<ATProto::Client>(std::move(xrpc));

    mBsky->resumeSession(session,
        [this] {
            qInfo() << "Session resumed";
            saveSession(*mBsky->getSession());
            mUserDid = mBsky->getSession()->mDid;
            emit resumeSessionOk();
            refreshSession();
            startRefreshTimers();
        },
        [this](const QString& error, const QString& msg){
            qInfo() << "Session could not be resumed:" << error << " - " << msg;

            if (error == "ExpiredToken")
                emit resumeSessionExpired();
            else
                emit resumeSessionFailed(msg);
        });
}

void Skywalker::startRefreshTimers()
{
    qDebug() << "Refresh timers started";
    mRefreshTimer.start(SESSION_REFRESH_INTERVAL);
    refreshNotificationCount();
    mRefreshNotificationTimer.start(NOTIFICATION_REFRESH_INTERVAL);
}

void Skywalker::stopRefreshTimers()
{
    qInfo() << "Refresh timers stopped";
    mRefreshTimer.stop();
    mRefreshNotificationTimer.stop();
}

void Skywalker::refreshSession()
{
    Q_ASSERT(mBsky);
    qDebug() << "Refresh session";

    const auto* session = mBsky->getSession();
    if (!session)
    {
        qWarning() << "No session to refresh.";
        stopRefreshTimers();
        return;
    }

    mBsky->refreshSession(
        [this]{
            qDebug() << "Session refreshed";
            saveSession(*mBsky->getSession());
        },
        [this](const QString& error, const QString& msg){
            qDebug() << "Session could not be refreshed:" << error << " - " << msg;
            emit sessionExpired(msg);
            stopRefreshTimers();
        });
}

void Skywalker::refreshNotificationCount()
{
    Q_ASSERT(mBsky);
    qDebug() << "Refresh notification count";

    mBsky->getUnreadNotificationCount({},
        [this](int unread){
            qDebug() << "Unread notification count:" << unread;
            setUnreadNotificationCount(unread);
        },
        [](const QString& error, const QString& msg){
            qWarning() << "Failed to get unread notification count:" << error << " - " << msg;
        });
}

void Skywalker::registerPushNotifications(const QString& token)
{
    Q_ASSERT(mBsky);
    qDebug() << "Register push notifications";

    mBsky->registerPushNotifications("did:web:api.bsky.app", token, "android", "com.gmail.mfnboer.skywalker",
        []{
            qDebug() << "Push notifications registered.";
        },
        [](const QString& error, const QString& msg){
            qWarning() << "Failed to register push notifications:" << error << " - " << msg;
        });
}

void Skywalker::getUserProfileAndFollows()
{
    Q_ASSERT(mBsky);
    const auto* session = mBsky->getSession();
    Q_ASSERT(session);
    qDebug() << "Get user profile, handle:" << session->mHandle << "did:" << session->mDid;

    // Get profile and follows in one go. We do not need detailed profile data.
    mBsky->getFollows(session->mDid, 100, {},
        [this](auto follows){
            for (auto& profile : follows->mFollows)
                mUserFollows.add(BasicProfile(*profile));

            const auto& nextCursor = follows->mCursor;
            if (!nextCursor->isEmpty())
                getUserProfileAndFollowsNextPage(*nextCursor);
            else
                signalGetUserProfileOk(*follows->mSubject);
        },
        [this](const QString& error, const QString& msg){
            qWarning() << error << " - " << msg;
            mUserFollows.clear();
            emit getUserProfileFailed(msg);
        });
}

void Skywalker::getUserProfileAndFollowsNextPage(const QString& cursor, int maxPages)
{   
    Q_ASSERT(mBsky);
    const auto* session = mBsky->getSession();
    Q_ASSERT(session);
    qDebug() << "Get user profile next page:" << cursor << ", handle:" << session->mHandle <<
            ", did:" << session->mDid << ", max pages:" << maxPages;

    mBsky->getFollows(session->mDid, 100, cursor,
        [this, maxPages](auto follows){
            for (auto& profile : follows->mFollows)
                mUserFollows.add(BasicProfile(*profile));

            const auto& nextCursor = follows->mCursor;

            if (nextCursor->isEmpty())
            {
                signalGetUserProfileOk(*follows->mSubject);
            }
            else if (maxPages > 0)
            {
                getUserProfileAndFollowsNextPage(*nextCursor, maxPages - 1);
            }
            else
            {
                qWarning() << "Max pages reached!";
                signalGetUserProfileOk(*follows->mSubject);
            }
        },
        [this](const QString& error, const QString& msg){
            qWarning() << error << " - " << msg;
            mUserFollows.clear();
            emit getUserProfileFailed(msg);
        });
}

void Skywalker::signalGetUserProfileOk(const ATProto::AppBskyActor::ProfileView& user)
{
    qDebug() << "Got user:" << user.mHandle << "#follows:" << mUserFollows.size();
    AuthorCache::instance().setUser(BasicProfile(user));
    mUserSettings.saveDisplayName(mUserDid, user.mDisplayName.value_or(""));
    const auto avatar = user.mAvatar ? *user.mAvatar : QString();
    mUserSettings.saveAvatar(mUserDid, avatar);
    setAvatarUrl(avatar);
    emit getUserProfileOK();
}

void Skywalker::getUserPreferences()
{
    Q_ASSERT(mBsky);
    qDebug() << "Get user preferences";

    // Get profile and follows in one go. We do not need detailed profile data.
    mBsky->getPreferences(
        [this](auto prefs){
            mUserPreferences = prefs;
            emit getUserPreferencesOK();
        },
        [this](const QString& error, const QString& msg){
            qWarning() << error << " - " << msg;
            emit getUserPreferencesFailed();
        });
}

void Skywalker::syncTimeline(int maxPages)
{
    const auto timestamp = getSyncTimestamp();

    if (!timestamp.isValid())
    {
        qInfo() << "No timestamp saved";
        getTimeline(TIMELINE_ADD_PAGE_SIZE);
        finishTimelineSync(-1);
        return;
    }

    disableDebugLogging(); // sync can cause a lot of logging
    syncTimeline(timestamp, maxPages);
}

void Skywalker::syncTimeline(QDateTime tillTimestamp, int maxPages, const QString& cursor)
{
    Q_ASSERT(mBsky);
    Q_ASSERT(tillTimestamp.isValid());
    qInfo() << "Sync timeline:" << tillTimestamp << "max pages:" << maxPages;

    if (mGetTimelineInProgress)
    {
        qInfo() << "Get timeline still in progress";
        return;
    }

    setGetTimelineInProgress(true);
    mBsky->getTimeline(TIMELINE_SYNC_PAGE_SIZE, makeOptionalCursor(cursor),
        [this, tillTimestamp, maxPages, cursor](auto feed){
            mTimelineModel.addFeed(std::move(feed));
            setGetTimelineInProgress(false);
            const auto lastTimestamp = mTimelineModel.lastTimestamp();

            if (lastTimestamp.isNull())
            {
                restoreDebugLogging();
                qWarning() << "Feed is empty";
                finishTimelineSyncFailed();
                return;
            }

            if (lastTimestamp < tillTimestamp)
            {
                restoreDebugLogging();
                const auto index = mTimelineModel.findTimestamp(tillTimestamp);
                qDebug() << "Timeline synced, last timestamp:" << lastTimestamp << "index:"
                        << index << ",feed size:" << mTimelineModel.rowCount()
                        << ",pages left:" << maxPages;

                Q_ASSERT(index >= 0);
                const auto& post = mTimelineModel.getPost(index);
                qDebug() << post.getTimelineTimestamp() << post.getText();

                finishTimelineSync(index);
                return;
            }

            if (maxPages == 1)
            {
                restoreDebugLogging();
                qDebug() << "Max pages loaded, failed to sync till:" << tillTimestamp << "last:" << lastTimestamp;
                finishTimelineSync(mTimelineModel.rowCount() - 1);
                return;
            }

            const QString& newCursor = mTimelineModel.getLastCursor();
            if (newCursor.isEmpty())
            {
                restoreDebugLogging();
                qDebug() << "Last page reached, no more cursor";
                finishTimelineSync(mTimelineModel.rowCount() - 1);
                return;
            }

            if (newCursor == cursor)
            {
                restoreDebugLogging();
                qWarning() << "New cursor:" << newCursor << "is same as previous:" << cursor;
                qDebug() << "Failed to sync till:" << tillTimestamp << "last:" << lastTimestamp;
                finishTimelineSync(mTimelineModel.rowCount() - 1);
            }

            qInfo() << "Last timestamp:" << lastTimestamp;
            syncTimeline(tillTimestamp, maxPages - 1, newCursor);
        },
        [this](const QString& error, const QString& msg){
            restoreDebugLogging();
            qWarning() << "syncTimeline FAILED:" << error << " - " << msg;
            setGetTimelineInProgress(false);
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
            finishTimelineSyncFailed();
        }
        );
}

static void finalizeStartup()
{
    JNICallbackListener::getFCMToken();

    // Now we can handle pending intent (content share).
    // If there is any, then this will open the post composition page. This should
    // only been done when the startup sequence in the GUI is finished.
    JNICallbackListener::handlePendingIntent();
}

void Skywalker::finishTimelineSync(int index)
{
    // Inform the GUI about the timeline sync.
    // This will show the timeline to the user.
    emit timelineSyncOK(index);

    finalizeStartup();
}

void Skywalker::finishTimelineSyncFailed()
{
    emit timelineSyncFailed();
    finalizeStartup();
}

void Skywalker::getTimeline(int limit, int maxPages, int minEntries, const QString& cursor)
{
    Q_ASSERT(mBsky);
    qDebug() << "Get timeline:" << cursor;

    if (mGetTimelineInProgress)
    {
        qDebug() << "Get timeline still in progress";
        return;
    }

    if (maxPages <= 0)
    {
        qDebug() << "Max pages reached";
        return;
    }

    setGetTimelineInProgress(true);
    mBsky->getTimeline(limit, makeOptionalCursor(cursor),
       [this, maxPages, minEntries, cursor](auto feed){
            setGetTimelineInProgress(false);
            int topPostIndex = -1;
            int addedPosts = 0;

            if (cursor.isEmpty())
            {
                topPostIndex = mTimelineModel.setFeed(std::move(feed));
                addedPosts = mTimelineModel.rowCount();
            }
            else
            {
                const int oldRowCount = mTimelineModel.rowCount();
                mTimelineModel.addFeed(std::move(feed));
                addedPosts = mTimelineModel.rowCount() - oldRowCount;
            }

            const int postsToAdd = minEntries - addedPosts;

            if (postsToAdd > 0)
                getTimelineNextPage(maxPages - 1, postsToAdd);

            if (topPostIndex >= 0)
                emit timelineRefreshed(topPostIndex);
       },
       [this](const QString& error, const QString& msg){
            qInfo() << "getTimeline FAILED:" << error << " - " << msg;
            setGetTimelineInProgress(false);
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        }
    );
}

void Skywalker::getTimelinePrepend(int autoGapFill)
{
    Q_ASSERT(mBsky);
    qInfo() << "Get timeline prepend";

    if (mGetTimelineInProgress)
    {
        qInfo() << "Get timeline still in progress";
        return;
    }

    if (mTimelineModel.rowCount() >= PostFeedModel::MAX_TIMELINE_SIZE)
    {
        qInfo() << "Timeline is full:" << mTimelineModel.rowCount();
        return;
    }

    setAutoUpdateTimelineInProgress(true);
    setGetTimelineInProgress(true);

    mBsky->getTimeline(TIMELINE_PREPEND_PAGE_SIZE, {},
        [this, autoGapFill](auto feed){
            const int gapId = mTimelineModel.prependFeed(std::move(feed));
            setGetTimelineInProgress(false);
            setAutoUpdateTimelineInProgress(false);

            if (gapId > 0)
            {
                if (autoGapFill > 0)
                    getTimelineForGap(gapId, autoGapFill - 1);
                else
                    qDebug() << "Gap created, no auto gap fill";
            }
        },
        [this](const QString& error, const QString& msg){
            qDebug() << "getTimeline FAILED:" << error << " - " << msg;
            setGetTimelineInProgress(false);
            setAutoUpdateTimelineInProgress(false);
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        }
        );
}

void Skywalker::getTimelineForGap(int gapId, int autoGapFill)
{
    Q_ASSERT(mBsky);
    qInfo() << "Get timeline for gap:" << gapId;

    if (mGetTimelineInProgress)
    {
        qInfo() << "Get timeline still in progress";
        return;
    }

    const Post* post = mTimelineModel.getGapPlaceHolder(gapId);
    if (!post || !post->isGap())
    {
        qWarning() << "NO GAP:" << gapId;
        return;
    }

    std::optional<QString> cur = post->getGapCursor();
    if (!cur || cur->isEmpty())
    {
        qWarning() << "NO CURSOR FOR GAP:" << gapId;
        return;
    }

    qInfo() << "Set gap cursor:" << *cur;

    setGetTimelineInProgress(true);
    mBsky->getTimeline(TIMELINE_ADD_PAGE_SIZE, cur,
        [this, gapId, autoGapFill](auto feed){
            const int newGapId = mTimelineModel.gapFillFeed(std::move(feed), gapId);
            setGetTimelineInProgress(false);

            if (newGapId > 0)
            {
                if (autoGapFill > 0)
                    getTimelineForGap(newGapId, autoGapFill - 1);
                else
                    qInfo() << "Gap created, no auto gap fill";
            }
        },
        [this](const QString& error, const QString& msg){
            qInfo() << "getTimelineForGap FAILED:" << error << " - " << msg;
            setGetTimelineInProgress(false);
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        }
        );
}

void Skywalker::getTimelineNextPage(int maxPages, int minEntries)
{
    if (maxPages <= 0)
    {
        qDebug() << "Max pages reached";
        return;
    }

    const QString& cursor = mTimelineModel.getLastCursor();
    if (cursor.isEmpty())
    {
        qInfo() << "Last page reached, no more cursor";
        return;
    }

    if (mTimelineModel.rowCount() >= PostFeedModel::MAX_TIMELINE_SIZE)
        mTimelineModel.removeHeadPosts(TIMELINE_ADD_PAGE_SIZE);

    getTimeline(TIMELINE_ADD_PAGE_SIZE, maxPages, minEntries, cursor);
}

void Skywalker::setAutoUpdateTimelineInProgress(bool inProgress)
{
    mAutoUpdateTimelineInProgress = inProgress;
    emit autoUpdateTimeLineInProgressChanged();
}

void Skywalker::setGetTimelineInProgress(bool inProgress)
{
    mGetTimelineInProgress = inProgress;
    emit getTimeLineInProgressChanged();
}

void Skywalker::setGetPostThreadInProgress(bool inProgress)
{
    mGetPostThreadInProgress = inProgress;
    emit getPostThreadInProgressChanged();
}

void Skywalker::setGetNotificationsInProgress(bool inProgress)
{
    mGetNotificationsInProgress = inProgress;
    emit getNotificationsInProgressChanged();
}

void Skywalker::setGetAuthorFeedInProgress(bool inProgress)
{
    mGetAuthorFeedInProgress = inProgress;
    emit getAuthorFeedInProgressChanged();
}

void Skywalker::setGetAuthorListInProgress(bool inProgress)
{
    mGetAuthorListInProgress = inProgress;
    emit getAuthorListInProgressChanged();
}

void Skywalker::setAvatarUrl(const QString& avatarUrl)
{
    mAvatarUrl = avatarUrl;
    emit avatarUrlChanged();
}

void Skywalker::setUnreadNotificationCount(int unread)
{
    const int totalUnread = unread + mNotificationListModel.getInviteCodeUsageNotificationCount();

    if (totalUnread != mUnreadNotificationCount)
    {
        mUnreadNotificationCount = totalUnread;
        emit unreadNotificationCountChanged();
    }
}

// NOTE: indices can be -1 if the UI cannot determine the index
void Skywalker::timelineMovementEnded(int firstVisibleIndex, int lastVisibleIndex)
{
    if (mSignOutInProgress)
        return;

    if (lastVisibleIndex > -1)
    {
        if (firstVisibleIndex > -1)
            saveSyncTimestamp((lastVisibleIndex + firstVisibleIndex) / 2);
        else
            saveSyncTimestamp(lastVisibleIndex);
    }

    if (lastVisibleIndex > -1 && mTimelineModel.rowCount() - lastVisibleIndex > 2 * TIMELINE_DELETE_SIZE)
        mTimelineModel.removeTailPosts(TIMELINE_DELETE_SIZE);

    if (lastVisibleIndex > mTimelineModel.rowCount() - 5 && !mGetTimelineInProgress)
        getTimelineNextPage();
}

void Skywalker::getPostThread(const QString& uri)
{
    Q_ASSERT(mBsky);
    qDebug() << "Get post thread:" << uri;

    if (mGetPostThreadInProgress)
    {
        qDebug() << "Get post thread still in progress";
        return;
    }

    setGetPostThreadInProgress(true);
    mBsky->getPostThread(uri, {}, {},
        [this](auto thread){
            setGetPostThreadInProgress(false);
            auto model = std::make_unique<PostThreadModel>(mUserDid, mUserFollows, mContentFilter, mBookmarks, mMutedWords, this);
            int postEntryIndex = model->setPostThread(std::move(thread));

            if (postEntryIndex < 0)
            {
                qDebug() << "No thread posts";
                emit statusMessage("Could not create post thread", QEnums::STATUS_LEVEL_ERROR);
                return;
            }

            int id = mPostThreadModels.put(std::move(model));
            emit postThreadOk(id, postEntryIndex);
        },
        [this](const QString& error, const QString& msg){
            setGetPostThreadInProgress(false);
            qDebug() << "getPostThread FAILED:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

std::optional<QString> Skywalker::makeOptionalCursor(const QString& cursor) const
{
    std::optional<QString> optionalCursor;
    if (!cursor.isEmpty())
        optionalCursor = cursor;

    return optionalCursor;
}

const PostThreadModel* Skywalker::getPostThreadModel(int id) const
{
    qDebug() << "Get model:" << id;
    auto* model = mPostThreadModels.get(id);
    return model ? model->get() : nullptr;
}

void Skywalker::removePostThreadModel(int id)
{
    qDebug() << "Remove model:" << id;
    mPostThreadModels.remove(id);
}

void Skywalker::updatePostIndexTimestamps()
{
    makeLocalModelChange([](LocalPostModelChanges* model){ model->updatePostIndexTimestamps(); });
}

void Skywalker::makeLocalModelChange(const std::function<void(LocalPostModelChanges*)>& update)
{
    // Apply change to all active models. When a model gets refreshed (after clear)
    // or deleted, then the local changes will disapper.

    update(&mTimelineModel);
    update(&mNotificationListModel);

    for (auto& [_, model] : mPostThreadModels.items())
        update(model.get());

    for (auto& [_, model] : mAuthorFeedModels.items())
        update(model.get());

    for (auto& [_, model] : mSearchPostFeedModels.items())
        update(model.get());

    if (mBookmarksModel)
        update(mBookmarksModel.get());
}

void Skywalker::makeLocalModelChange(const std::function<void(LocalAuthorModelChanges*)>& update)
{
    for (auto& [_, model] : mAuthorListModels.items())
        update(model.get());
}

void Skywalker::getNotifications(int limit, bool updateSeen, const QString& cursor)
{
    Q_ASSERT(mBsky);
    qDebug() << "Get notifications:" << cursor;

    if (mGetNotificationsInProgress)
    {
        qDebug() << "Get notifications still in progress";
        return;
    }

    setGetNotificationsInProgress(true);
    mBsky->listNotifications(limit, makeOptionalCursor(cursor), {},
        [this, cursor](auto list){
            const bool clearFirst = cursor.isEmpty();
            mNotificationListModel.addNotifications(std::move(list), *mBsky, clearFirst);
            setGetNotificationsInProgress(false);
        },
        [this](const QString& error, const QString& msg){
            qDebug() << "getNotifications FAILED:" << error << " - " << msg;
            setGetNotificationsInProgress(false);
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        },
        updateSeen);

    if (updateSeen)
        setUnreadNotificationCount(0);
}

void Skywalker::getNotificationsNextPage()
{
    const QString& cursor = mNotificationListModel.getCursor();
    if (cursor.isEmpty())
    {
        qDebug() << "Last page reached, no more cursor";
        return;
    }

    getNotifications(NOTIFICATIONS_ADD_PAGE_SIZE, false, cursor);
}

void Skywalker::getBookmarksPage(bool clearModel)
{
    Q_ASSERT(mBsky);
    Q_ASSERT(mBookmarksModel);

    if (!mBookmarksModel)
        return;

    if (clearModel)
        mBookmarksModel->clear();

    const int pageIndex = mBookmarksModel->rowCount();
    const auto page = mBookmarks.getPage(pageIndex, BookmarksModel::MAX_PAGE_SIZE);

    if (page.empty())
    {
        qDebug() << "No more bookmarks";
        return;
    }

    mBookmarksModel->addBookmarks(page, *mBsky);
}

void Skywalker::getDetailedProfile(const QString& author)
{
    Q_ASSERT(mBsky);
    qDebug() << "Get detailed profile:" << author;

    mBsky->getProfile(author,
        [this](auto profile){
            auto shared = ATProto::AppBskyActor::ProfileViewDetailed::SharedPtr(profile.release());
            emit getDetailedProfileOK(DetailedProfile(shared));
        },
        [this](const QString& error, const QString& msg){
            qDebug() << "getDetailedProfile failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::clearAuthorFeed(int id)
{
    Q_ASSERT(mBsky);
    qDebug() << "Clear author feed model:" << id;

    if (mGetAuthorFeedInProgress)
    {
        qDebug() << "Get author feed still in progress";
        return;
    }

    const auto* model = mAuthorFeedModels.get(id);
    Q_ASSERT(model);

    if (!model)
    {
        qWarning() << "Model does not exist:" << id;
        return;
    }

    (*model)->clear();
}

void Skywalker::getAuthorFeed(int id, int limit, int maxPages, int minEntries, const QString& cursor)
{
    Q_ASSERT(mBsky);
    qDebug() << "Get author feed model:" << id << "cursor:" << cursor << "max pages:"
             << maxPages << "min entries:" << minEntries;

    if (mGetAuthorFeedInProgress)
    {
        qDebug() << "Get author feed still in progress";
        return;
    }

    const auto* model = mAuthorFeedModels.get(id);
    Q_ASSERT(model);

    if (!model)
    {
        qWarning() << "Model does not exist:" << id;
        return;
    }

    const auto& author = (*model)->getAuthor();
    qDebug() << "Get author feed:" << author.getHandle();

    setGetAuthorFeedInProgress(true);
    mBsky->getAuthorFeed(author.getDid(), limit, makeOptionalCursor(cursor),
        [this, id, maxPages, minEntries, cursor](auto feed){
            setGetAuthorFeedInProgress(false);
            const auto* model = mAuthorFeedModels.get(id);

            if (!model)
                return; // user has closed the view

            int added = cursor.isEmpty() ?
                    (*model)->setFeed(std::move(feed)) :
                    (*model)->addFeed(std::move(feed));

            // When replies are filtered out, a page can easily become empty
            int entriesToAdd = minEntries - added;

            if (entriesToAdd > 0)
                getAuthorFeedNextPage(id, maxPages - 1, entriesToAdd);
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorFeedInProgress(false);
            qDebug() << "getAuthorFeed failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getAuthorFeedNextPage(int id, int maxPages, int minEntries)
{
    qDebug() << "Get author feed next page, model:" << id << "max pages:" << maxPages
             << "min entries:" << minEntries;

    if (mGetAuthorFeedInProgress)
    {
        qDebug() << "Get author feed still in progress";
        return;
    }

    if (maxPages <= 0)
    {
        // Protection against infinite loop.
        qWarning() << "Maximum pages reached!";
        return;
    }

    const auto* model = mAuthorFeedModels.get(id);
    Q_ASSERT(model);

    if (!model)
    {
        qWarning() << "Model does not exist:" << id;
        return;
    }

    auto* authorFeedModel = (*model).get();
    const auto& cursor = authorFeedModel->getCursorNextPage();

    if (cursor.isEmpty())
    {
        qDebug() << "End of feed reached.";
        return;
    }

    getAuthorFeed(id, AUTHOR_FEED_ADD_PAGE_SIZE, maxPages, minEntries, cursor);
}

int Skywalker::createAuthorFeedModel(const BasicProfile& author)
{
    auto model = std::make_unique<AuthorFeedModel>(author, mUserDid, mUserFollows, mContentFilter, mBookmarks, mMutedWords, this);
    const int id = mAuthorFeedModels.put(std::move(model));
    return id;
}

const AuthorFeedModel* Skywalker::getAuthorFeedModel(int id) const
{
    qDebug() << "Get model:" << id;
    auto* model = mAuthorFeedModels.get(id);
    return model ? model->get() : nullptr;
}

void Skywalker::removeAuthorFeedModel(int id)
{
    qDebug() << "Remove model:" << id;
    mAuthorFeedModels.remove(id);
}

int Skywalker::createSearchPostFeedModel()
{
    auto model = std::make_unique<SearchPostFeedModel>(mUserDid, mUserFollows, mContentFilter, mBookmarks, mMutedWords, this);
    const int id = mSearchPostFeedModels.put(std::move(model));
    return id;
}

SearchPostFeedModel* Skywalker::getSearchPostFeedModel(int id) const
{
    qDebug() << "Get model:" << id;
    auto* model = mSearchPostFeedModels.get(id);
    return model ? model->get() : nullptr;
}

void Skywalker::removeSearchPostFeedModel(int id)
{
    qDebug() << "Remove model:" << id;
    mSearchPostFeedModels.remove(id);
}

void Skywalker::getFollowsAuthorList(const QString& atId, int limit, const QString& cursor, int modelId)
{
    setGetAuthorListInProgress(true);
    mBsky->getFollows(atId, limit, makeOptionalCursor(cursor),
        [this, modelId](auto output){
            setGetAuthorListInProgress(false);
            const auto* model = mAuthorListModels.get(modelId);

            if (model)
                (*model)->addAuthors(std::move(output->mFollows), output->mCursor.value_or(""));
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorListInProgress(false);
            qDebug() << "getFollowsAuthorList failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getFollowersAuthorList(const QString& atId, int limit, const QString& cursor, int modelId)
{
    setGetAuthorListInProgress(true);
    mBsky->getFollowers(atId, limit, makeOptionalCursor(cursor),
        [this, modelId](auto output){
            setGetAuthorListInProgress(false);
            const auto* model = mAuthorListModels.get(modelId);

            if (model)
                (*model)->addAuthors(std::move(output->mFollowers), output->mCursor.value_or(""));
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorListInProgress(false);
            qDebug() << "getFollowersAuthorList failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getBlocksAuthorList(int limit, const QString& cursor, int modelId)
{
    setGetAuthorListInProgress(true);
    mBsky->getBlocks(limit, makeOptionalCursor(cursor),
        [this, modelId](auto output){
            setGetAuthorListInProgress(false);
            const auto* model = mAuthorListModels.get(modelId);

            if (model)
                (*model)->addAuthors(std::move(output->mBlocks), output->mCursor.value_or(""));
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorListInProgress(false);
            qDebug() << "getBlocksAuthorList failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getMutesAuthorList(int limit, const QString& cursor, int modelId)
{
    setGetAuthorListInProgress(true);
    mBsky->getMutes(limit, makeOptionalCursor(cursor),
        [this, modelId](auto output){
            setGetAuthorListInProgress(false);
            const auto* model = mAuthorListModels.get(modelId);

            if (model)
                (*model)->addAuthors(std::move(output->mMutes), output->mCursor.value_or(""));
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorListInProgress(false);
            qDebug() << "getMutesAuthorList failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getLikesAuthorList(const QString& atId, int limit, const QString& cursor, int modelId)
{
    setGetAuthorListInProgress(true);
    mBsky->getLikes(atId, limit, makeOptionalCursor(cursor),
        [this, modelId](auto output){
            setGetAuthorListInProgress(false);
            const auto* model = mAuthorListModels.get(modelId);

            if (!model)
                return;

            ATProto::AppBskyActor::ProfileViewList profileList;

            for (const auto& like : output->mLikes)
                profileList.push_back(std::move(like->mActor));

            (*model)->addAuthors(std::move(profileList), output->mCursor.value_or(""));
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorListInProgress(false);
            qDebug() << "getLikesAuthorList failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getRepostsAuthorList(const QString& atId, int limit, const QString& cursor, int modelId)
{
    setGetAuthorListInProgress(true);
    mBsky->getRepostedBy(atId, limit, makeOptionalCursor(cursor),
        [this, modelId](auto output){
            setGetAuthorListInProgress(false);
            const auto* model = mAuthorListModels.get(modelId);

            if (model)
                (*model)->addAuthors(std::move(output->mRepostedBy), output->mCursor.value_or(""));
        },
        [this](const QString& error, const QString& msg){
            setGetAuthorListInProgress(false);
            qDebug() << "getRepostsAuthorList failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

void Skywalker::getAuthorList(int id, int limit, const QString& cursor)
{
    Q_ASSERT(mBsky);
    qDebug() << "Get author list model:" << id << "cursor:" << cursor;

    if (mGetAuthorListInProgress)
    {
        qDebug() << "Get author list still in progress";
        return;
    }

    const auto* model = mAuthorListModels.get(id);
    Q_ASSERT(model);

    if (!model)
    {
        qWarning() << "Model does not exist:" << id;
        return;
    }

    const AuthorListModel::Type type = (*model)->getType();
    const auto& atId = (*model)->getAtId();
    qDebug() << "Get author list:" << atId << "type:" << int(type);

    switch (type)
    {
    case AuthorListModel::Type::AUTHOR_LIST_FOLLOWS:
        getFollowsAuthorList(atId, limit, cursor, id);
        break;
    case AuthorListModel::Type::AUTHOR_LIST_FOLLOWERS:
        getFollowersAuthorList(atId, limit, cursor, id);
        break;
    case AuthorListModel::Type::AUTHOR_LIST_BLOCKS:
        getBlocksAuthorList(limit, cursor, id);
        break;
    case AuthorListModel::Type::AUTHOR_LIST_MUTES:
        getMutesAuthorList(limit, cursor, id);
        break;
    case AuthorListModel::Type::AUTHOR_LIST_LIKES:
        getLikesAuthorList(atId, limit, cursor, id);
        break;
    case AuthorListModel::Type::AUTHOR_LIST_REPOSTS:
        getRepostsAuthorList(atId, limit, cursor, id);
        break;
    case AuthorListModel::Type::AUTHOR_LIST_SEARCH_RESULTS:
        Q_ASSERT(false);
        break;
    }
}

void Skywalker::getAuthorListNextPage(int id)
{
    qDebug() << "Get author list next page, model:" << id;

    if (mGetAuthorListInProgress)
    {
        qDebug() << "Get author list still in progress";
        return;
    }

    const auto* model = mAuthorListModels.get(id);
    Q_ASSERT(model);

    if (!model)
    {
        qWarning() << "Model does not exist:" << id;
        return;
    }

    auto* authorListModel = (*model).get();
    const auto& cursor = authorListModel->getCursor();

    if (cursor.isEmpty())
    {
        qDebug() << "End of list reached.";
        return;
    }

    getAuthorList(id, AUTHOR_LIST_ADD_PAGE_SIZE, cursor);
}

int Skywalker::createAuthorListModel(AuthorListModel::Type type, const QString& atId)
{
    auto model = std::make_unique<AuthorListModel>(type, atId, mContentFilter, this);
    const int id = mAuthorListModels.put(std::move(model));
    return id;
}

AuthorListModel* Skywalker::getAuthorListModel(int id) const
{
    qDebug() << "Get model:" << id;
    auto* model = mAuthorListModels.get(id);
    return model ? model->get() : nullptr;
}

void Skywalker::removeAuthorListModel(int id)
{
    qDebug() << "Remove model:" << id;
    mAuthorListModels.remove(id);
}

BasicProfile Skywalker::getUser() const
{
    return AuthorCache::instance().getUser();
}

void Skywalker::sharePost(const QString& postUri, const BasicProfile& author)
{
    qDebug() << "Share post:" << postUri;
    ATProto::ATUri atUri(postUri);

    if (!atUri.isValid())
        return;

    const QString authorId = author.getHandleOrDid();
    const QString shareUri = QString("https://bsky.app/profile/%1/post/%2")
                                .arg(authorId, atUri.getRkey());

#ifdef Q_OS_ANDROID
    QJniObject jShareUri = QJniObject::fromString(shareUri);
    QJniObject jSubject = QJniObject::fromString("post");

    QJniObject::callStaticMethod<void>("com/gmail/mfnboer/ShareUtils",
                                       "shareLink",
                                       "(Ljava/lang/String;Ljava/lang/String;)V",
                                       jShareUri.object<jstring>(),
                                       jSubject.object<jstring>());
#else
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(shareUri);
    emit statusMessage(tr("Post link copied to clipboard"));
#endif
}

void Skywalker::shareAuthor(const BasicProfile& author)
{
    const QString authorId = author.getHandleOrDid();
    const QString shareUri = QString("https://bsky.app/profile/%1").arg(authorId);

#ifdef Q_OS_ANDROID
    QJniObject jShareUri = QJniObject::fromString(shareUri);
    QJniObject jSubject = QJniObject::fromString("author profile");

    QJniObject::callStaticMethod<void>("com/gmail/mfnboer/ShareUtils",
                                       "shareLink",
                                       "(Ljava/lang/String;Ljava/lang/String;)V",
                                       jShareUri.object<jstring>(),
                                       jSubject.object<jstring>());
#else
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(shareUri);
    emit statusMessage(tr("Author link copied to clipboard"));
#endif
}

void Skywalker::copyPostTextToClipboard(const QString& text)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(PostUtils::toPlainText(text));
    emit statusMessage(tr("Post text copied to clipboard"));
}

QEnums::ContentVisibility Skywalker::getContentVisibility(const QStringList& labelTexts) const
{
    const auto [visibility, _] = mContentFilter.getVisibilityAndWarning(labelTexts);
    return visibility;
}

QString Skywalker::getContentWarning(const QStringList& labelTexts) const
{
    const auto [_, warning] = mContentFilter.getVisibilityAndWarning(labelTexts);
    return warning;
}

const ContentGroupListModel* Skywalker::getContentGroupListModel()
{
    mContentGroupListModel = std::make_unique<ContentGroupListModel>(mContentFilter, this);
    mContentGroupListModel->setAdultContent(mUserPreferences.getAdultContent());
    return mContentGroupListModel.get();
}

void Skywalker::saveContentFilterPreferences()
{
    Q_ASSERT(mBsky);
    Q_ASSERT(mContentGroupListModel);

    if (!mContentGroupListModel)
    {
        qWarning() << "No filter preferences to save";
        return;
    }

    if (!mContentGroupListModel->isModified(mUserPreferences))
    {
        qDebug() << "Filter preferences not modified.";
        return;
    }

    auto prefs = mUserPreferences;
    mContentGroupListModel->saveTo(prefs);

    mBsky->putPreferences(prefs,
        [this, prefs]{
            qDebug() << "saveFilterPreferences ok";
            mUserPreferences = prefs;
            emit statusMessage("Content filter saved");
        },
        [this](const QString& error, const QString& msg){
            qDebug() << "saveFilterPreferences failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

EditUserPreferences* Skywalker::getEditUserPreferences()
{
    Q_ASSERT(mBsky);
    const auto* session = mBsky->getSession();
    Q_ASSERT(session);
    mEditUserPreferences = std::make_unique<EditUserPreferences>(this);
    mEditUserPreferences->setEmail(session->mEmail.value_or(""));
    mEditUserPreferences->setEmailConfirmed(session->mEmailConfirmed);
    mEditUserPreferences->setUserPreferences(mUserPreferences);
    mEditUserPreferences->setDisplayMode(mUserSettings.getDisplayMode());
    mEditUserPreferences->setLocalSettingsModified(false);

    if (session->getPDS())
    {
        const QUrl url(*session->getPDS());
        mEditUserPreferences->setPDS(url.host());
    }
    else
    {
        mEditUserPreferences->setPDS(mBsky->getHost());
    }

    return mEditUserPreferences.get();
}

void Skywalker::saveUserPreferences()
{
    Q_ASSERT(mBsky);
    Q_ASSERT(mEditUserPreferences);

    if (!mEditUserPreferences)
    {
        qWarning() << "No preferences to save";
        return;
    }

    if (mEditUserPreferences->isLocalSettingsModified())
    {
        qDebug() << "Changed display mode:" << mEditUserPreferences->getDisplayMode();
        mUserSettings.setDisplayMode(mEditUserPreferences->getDisplayMode());
    }

    if (!mEditUserPreferences->isModified())
    {
        qDebug() << "User preferences not modified.";
        return;
    }

    auto prefs = mUserPreferences;
    mEditUserPreferences->saveTo(prefs);

    mBsky->putPreferences(prefs,
        [this, prefs]{
            qDebug() << "saveUserPreferences ok";
            mUserPreferences = prefs;
            emit statusMessage("Settings saved");
        },
        [this](const QString& error, const QString& msg){
            qDebug() << "saveUserPreferences failed:" << error << " - " << msg;
            emit statusMessage(msg, QEnums::STATUS_LEVEL_ERROR);
        });
}

const BookmarksModel* Skywalker::createBookmarksModel()
{
    mBookmarksModel = std::make_unique<BookmarksModel>(mUserDid, mUserFollows, mContentFilter, mBookmarks, mMutedWords, this);

    connect(mBookmarksModel.get(), &BookmarksModel::failure, this,
            [this](QString error){ showStatusMessage(error, QEnums::STATUS_LEVEL_ERROR); });

    return mBookmarksModel.get();
}

void Skywalker::deleteBookmarksModel()
{
    mBookmarksModel = nullptr;
}

bool Skywalker::sendAppToBackground()
{
#ifdef Q_OS_ANDROID
    if (!QNativeInterface::QAndroidApplication::isActivityContext())
    {
        qWarning() << "Cannot find Android activity";
        return false;
    }

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>("goToBack", "()V");
    return true;
#else
    return false;
#endif
}

void Skywalker::updateUser(const QString& did, const QString& host, const QString& password)
{
    mUserDid = did;
    mUserSettings.addUser(did, host);
    mUserSettings.savePassword(did, password);
    mUserSettings.setActiveUserDid(did);
}

void Skywalker::saveSession(const ATProto::ComATProtoServer::Session& session)
{
    mUserSettings.saveSession(session);
}

bool Skywalker::getSession(QString& host, ATProto::ComATProtoServer::Session& session)
{
    const QString did = mUserSettings.getActiveUserDid();

    if (did.isEmpty())
        return false;

    session = mUserSettings.getSession(did);

    if (session.mAccessJwt.isEmpty() || session.mRefreshJwt.isEmpty())
        return false;

    host = mUserSettings.getHost(did);

    if (host.isEmpty())
        return false;

    return true;
}

void Skywalker::saveSyncTimestamp(int postIndex)
{
    if (postIndex < 0 || postIndex >= mTimelineModel.rowCount())
    {
        qWarning() << "Invalid index:" << postIndex << "size:" << mTimelineModel.rowCount();
        return;
    }

    const auto& post = mTimelineModel.getPost(postIndex);
    mUserSettings.saveSyncTimestamp(mUserDid, post.getTimelineTimestamp());
}

QDateTime Skywalker::getSyncTimestamp() const
{
    return mUserSettings.getSyncTimestamp(mUserDid);
}

void Skywalker::shareImage(const QString& contentUri, const QString& text)
{
    if (!checkReadMediaPermission())
    {
        showStatusMessage(tr("No permission to access images."), QEnums::STATUS_LEVEL_ERROR);
        return;
    }

    int fd = openContentUri(contentUri);
    QImage img = readImageFd(fd);

    if (img.isNull())
    {
        showStatusMessage(tr("Could not read imgage file."), QEnums::STATUS_LEVEL_ERROR);
        return;
    }

    auto* imgProvider = SharedImageProvider::getProvider(SharedImageProvider::SHARED_IMAGE);
    const QString source = imgProvider->addImage(img);
    emit sharedImageReceived(source, text);
}

void Skywalker::disableDebugLogging()
{
    mDebugLogging = QLoggingCategory::defaultCategory()->isDebugEnabled();
    QLoggingCategory::defaultCategory()->setEnabled(QtDebugMsg, false);
}

void Skywalker::restoreDebugLogging()
{
    QLoggingCategory::defaultCategory()->setEnabled(QtDebugMsg, mDebugLogging);
}

void Skywalker::showStatusMessage(const QString& msg, QEnums::StatusLevel level)
{
    emit statusMessage(msg, level);
}

void Skywalker::clearPassword()
{
    if (!mUserDid.isEmpty())
        mUserSettings.clearCredentials(mUserDid);
}

void Skywalker::signOut()
{
    Q_ASSERT(mPostThreadModels.empty());
    Q_ASSERT(mAuthorFeedModels.empty());
    Q_ASSERT(mSearchPostFeedModels.empty());
    Q_ASSERT(mAuthorListModels.empty());

    qDebug() << "Logout:" << mUserDid;
    mSignOutInProgress = true;

    stopRefreshTimers();
    mPostThreadModels.clear();
    mAuthorFeedModels.clear();
    mSearchPostFeedModels.clear(); // TODO: clear model id in SearchUtils
    mAuthorListModels.clear();
    mNotificationListModel.clear();
    mUserPreferences = ATProto::UserPreferences();
    mEditUserPreferences = nullptr;
    mContentGroupListModel = nullptr;
    mTimelineModel.clear();
    setAvatarUrl({});
    mUserDid.clear();
    mUserFollows.clear();
    setUnreadNotificationCount(0);
    mBookmarksModel = nullptr;
    mBookmarks.clear();
    mMutedWords.clear();
    mUserSettings.setActiveUserDid({});
    mBsky = nullptr;
    setAutoUpdateTimelineInProgress(false);
    setGetTimelineInProgress(false);
    setGetPostThreadInProgress(false);
    setGetAuthorFeedInProgress(false);
    setGetAuthorListInProgress(false);

    mSignOutInProgress = false;

    emit bskyClientDeleted();
}

}
