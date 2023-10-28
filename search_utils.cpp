// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "search_utils.h"
#include <QTextBoundaryFinder>

namespace Skywalker {

QString SearchUtils::normalizeText(const QString& text)
{
    QLocale locale;
    const QString lowerCase = locale.toLower(text);
    const QString NFKD = lowerCase.normalized(QString::NormalizationForm_KD);
    QString normalized;

    for (const auto ch : NFKD)
    {
        switch (ch.category())
        {
        case QChar::Mark_NonSpacing:
        case QChar::Mark_SpacingCombining:
        case QChar::Mark_Enclosing:
            continue;
        default:
            break;
        }

        normalized.append(ch);
    }

    return normalized;
}

std::vector<QString> SearchUtils::getWords(const QString& text)
{
    if (text.isEmpty())
        return {};

    const QString normalized = SearchUtils::normalizeText(text);
    std::vector<QString> words;
    QTextBoundaryFinder boundaryFinder(QTextBoundaryFinder::Word, normalized);
    int startWordPos = 0;

    while (!(boundaryFinder.boundaryReasons() & QTextBoundaryFinder::StartOfItem) && startWordPos != -1)
        startWordPos = boundaryFinder.toNextBoundary();

    while (startWordPos != -1)
    {
        const int endWordPos = boundaryFinder.toNextBoundary();

        Q_ASSERT(endWordPos != -1);
        if (endWordPos == -1)
            break;

        const QString word = normalized.sliced(startWordPos, endWordPos - startWordPos);
        words.push_back(word);

        startWordPos = boundaryFinder.toNextBoundary();
        while (!(boundaryFinder.boundaryReasons() & QTextBoundaryFinder::StartOfItem) && startWordPos != -1)
            startWordPos = boundaryFinder.toNextBoundary();
    }

    return words;
}

SearchUtils::SearchUtils(QObject* parent) :
    Presence(),
    QObject(parent)
{
}

SearchUtils::~SearchUtils()
{
    removeModels();
}

void SearchUtils::removeModels()
{
    if (mSearchPostFeedModelId >= 0)
    {
        mSkywalker->removeSearchPostFeedModel(mSearchPostFeedModelId);
        mSearchPostFeedModelId = -1;
    }

    if (mSearchUsersModelId >= 0) {
        mSkywalker->removeAuthorListModel(mSearchUsersModelId);
        mSearchUsersModelId = -1;
    }
}

void SearchUtils::setSkywalker(Skywalker* skywalker)
{
    Q_ASSERT(skywalker);
    mSkywalker = skywalker;
    emit skywalkerChanged();
}

void SearchUtils::setAuthorTypeaheadList(const BasicProfileList& list)
{
    mAuthorTypeaheadList = list;
    emit authorTypeaheadListChanged();
}

void SearchUtils::addAuthorTypeaheadList(const ATProto::AppBskyActor::ProfileViewBasicList& profileViewBasicList)
{
    if (profileViewBasicList.empty())
        return;

    std::unordered_set<QString> alreadyFoundDids;

    for (const auto& basicProfile : mAuthorTypeaheadList)
        alreadyFoundDids.insert(basicProfile.getDid());

    for (const auto& profile : profileViewBasicList)
    {
        if (alreadyFoundDids.count(profile->mDid))
            continue;

        BasicProfile basicProfile(profile.get());
        mAuthorTypeaheadList.append(basicProfile.nonVolatileCopy());
    }

    emit authorTypeaheadListChanged();
}

void SearchUtils::searchAuthorsTypeahead(const QString& typed)
{
    localSearchAuthorsTypeahead(typed);

    bskyClient()->searchActorsTypeahead(typed, 10,
        [this, presence=getPresence()](auto searchOutput){
            if (!presence)
                return;

            addAuthorTypeaheadList(searchOutput->mActors);
        },
        [this, presence=getPresence()](const QString& error){
            if (!presence)
                return;

            qWarning() << "Type ahead search failed:" << error;
        });
}

void SearchUtils::localSearchAuthorsTypeahead(const QString& typed)
{
    const IndexedProfileStore& following = mSkywalker->getUserFollows();
    const std::unordered_set<const BasicProfile*> profiles = following.findProfiles(typed);
    BasicProfileList profileList;

    for (const auto* profile : profiles)
        profileList.append(*profile);

    setAuthorTypeaheadList(profileList);
}

void SearchUtils::searchPosts(const QString& text, int maxPages, int minEntries, const QString& cursor)
{
    qDebug() << "Search posts:" << text << "cursor:" << cursor << "max pages:"
             << maxPages << "min entries:" << minEntries;

    if (mSearchPostsInProgress)
    {
        qDebug() << "Search posts still in progress";
        return;
    }

    mSearchPostsInProgress = true;
    bskyClient()->searchPosts(text, {}, mSkywalker->makeOptionalCursor(cursor),
        [this, presence=getPresence(), text, maxPages, minEntries, cursor](auto feed){
            if (!presence)
                return;

            mSearchPostsInProgress = false;
            auto& model = *getSearchPostFeedModel();

            int added = cursor.isEmpty() ?
                            model.setFeed(std::move(feed)) :
                            model.addFeed(std::move(feed));

            // Due to content filtering the feed may go empty
            int entriesToAdd = minEntries - added;

            if (entriesToAdd > 0)
                getNextPageSearchPosts(text, maxPages - 1, entriesToAdd);
        },
        [this, presence=getPresence()](const QString& error){
            if (!presence)
                return;

            mSearchPostsInProgress = false;
            qDebug() << "searchPosts failed:" << error;
            mSkywalker->showStatusMessage(error, QEnums::STATUS_LEVEL_ERROR);
        });
}

void SearchUtils::getNextPageSearchPosts(const QString& text, int maxPages, int minEntries)
{
    qDebug() << "Get next page search posts:" << "max pages:" << maxPages
             << "min entries:" << minEntries;

    if (mSearchPostsInProgress)
    {
        qDebug() << "Search posts still in progress";
        return;
    }

    if (maxPages <= 0)
    {
        // Protection against infinite loop.
        qWarning() << "Maximum pages reached!";
        return;
    }

    const auto& model = *getSearchPostFeedModel();
    const auto& cursor = model.getCursorNextPage();

    if (cursor.isEmpty())
    {
        qDebug() << "End of feed reached.";
        return;
    }

    searchPosts(text, maxPages, minEntries, cursor);
}

void SearchUtils::legacySearchPosts(const QString& text)
{
    qDebug() << "Legacy search posts:" << text;

    if (mSearchPostsInProgress)
    {
        qDebug() << "Search posts still in progress";
        return;
    }

    mSearchPostsInProgress = true;
    bskyClient()->legacySearchPosts(text,
        [this, presence=getPresence()](auto feed){
            if (!presence)
                return;

            mSearchPostsInProgress = false;
            getPosts(feed->mUris);
        },
        [this, presence=getPresence()](const QString& error){
            if (!presence)
                return;

            mSearchPostsInProgress = false;
            qDebug() << "searchPosts failed:" << error;
            mSkywalker->showStatusMessage(error, QEnums::STATUS_LEVEL_ERROR);
        });
}

void SearchUtils::legacySearchActors(const QString& text)
{
    qDebug() << "Legacy search actors:" << text;

    if (mSearchActorsInProgress)
    {
        qDebug() << "Search posts still in progress";
        return;
    }

    mSearchActorsInProgress = true;
    bskyClient()->legacySearchActors(text,
        [this, presence=getPresence()](auto feed){
            if (!presence)
                return;

            mSearchActorsInProgress = false;
            getProfiles(feed->mDids);
        },
        [this, presence=getPresence()](const QString& error){
            if (!presence)
                return;

            mSearchActorsInProgress = false;
            qDebug() << "searchactors failed:" << error;
            mSkywalker->showStatusMessage(error, QEnums::STATUS_LEVEL_ERROR);
        });
}

void SearchUtils::getPosts(const std::vector<QString>& uris)
{
    qDebug() << "Get posts:" << uris.size();

    if (uris.empty())
        return;

    // Truncate the list. MAX is enough for the legacy search.
    const int count = std::min(int(uris.size()), bskyClient()->MAX_URIS_GET_POSTS);
    const std::vector<QString> uriList(uris.begin(), uris.begin() + count);

    bskyClient()->getPosts(uriList,
        [this, presence=getPresence()](auto postViewList)
        {
            if (!presence)
                return;

            auto output = std::make_unique<ATProto::AppBskyFeed::SearchPostsOutput>();
            output->mPosts = std::move(postViewList);
            auto& model = *getSearchPostFeedModel();
            model.setFeed(std::move(output));
        },
        [this, presence=getPresence()](const QString& error)
        {
            if (!presence)
                return;

            qWarning() << "Failed to get posts:" << error;
            mSkywalker->showStatusMessage(error, QEnums::STATUS_LEVEL_ERROR);
        });
}

void SearchUtils::getProfiles(const std::vector<QString>& users)
{
    qDebug() << "Get profiles:" << users.size();

    if (users.empty())
        return;

    // Truncate the list. MAX is enough for the legacy search.
    const int count = std::min(int(users.size()), bskyClient()->MAX_IDS_GET_PROFILES);
    const std::vector<QString> userList(users.begin(), users.begin() + count);

    bskyClient()->getProfiles(userList,
        [this, presence=getPresence()](auto profilesViewDetailedList)
        {
            if (!presence)
                return;

            ATProto::AppBskyActor::ProfileViewList profileViewList;

            for (auto& profileViewDetailed : profilesViewDetailedList)
            {
                auto profileView = std::make_unique<ATProto::AppBskyActor::ProfileView>();
                profileView->mDid = std::move(profileViewDetailed->mDid);
                profileView->mHandle = std::move(profileViewDetailed->mHandle);
                profileView->mDisplayName = std::move(profileViewDetailed->mDisplayName);
                profileView->mAvatar = std::move(profileViewDetailed->mAvatar);
                profileView->mDescription = std::move(profileViewDetailed->mDescription);
                profileView->mIndexedAt = std::move(profileViewDetailed->mIndexedAt);
                profileView->mViewer = std::move(profileViewDetailed->mViewer);
                profileView->mLabels = std::move(profileViewDetailed->mLabels);

                profileViewList.push_back(std::move(profileView));
            }

            auto& model = *getSearchUsersModel();
            model.clear();
            model.addAuthors(std::move(profileViewList), "");
        },
        [this, presence=getPresence()](const QString& error)
        {
            if (!presence)
                return;

            qWarning() << "Failed to get posts:" << error;
            mSkywalker->showStatusMessage(error, QEnums::STATUS_LEVEL_ERROR);
        });
}

ATProto::Client* SearchUtils::bskyClient()
{
    Q_ASSERT(mSkywalker);
    auto* client = mSkywalker->getBskyClient();
    Q_ASSERT(client);
    return client;
}

SearchPostFeedModel* SearchUtils::getSearchPostFeedModel()
{
    Q_ASSERT(mSkywalker);

    if (mSearchPostFeedModelId < 0)
        mSearchPostFeedModelId = mSkywalker->createSearchPostFeedModel();

    return mSkywalker->getSearchPostFeedModel(mSearchPostFeedModelId);
}

AuthorListModel* SearchUtils::getSearchUsersModel()
{
    Q_ASSERT(mSkywalker);

    if (mSearchUsersModelId < 0)
    {
        mSearchUsersModelId = mSkywalker->createAuthorListModel(
            AuthorListModel::Type::AUTHOR_LIST_SEARCH_RESULTS, "");
    }

    return mSkywalker->getAuthorListModel(mSearchUsersModelId);
}

}
