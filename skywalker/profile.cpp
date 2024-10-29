// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "profile.h"
#include "content_filter.h"
#include "definitions.h"

namespace Skywalker {

static const QString NULL_STRING;

KnownFollowers::KnownFollowers(const ATProto::AppBskyActor::KnownFollowers* knownFollowers)
{
    if (!knownFollowers)
        return;

    mPrivate = std::make_shared<PrivateData>();

    mPrivate->mCount = knownFollowers->mCount;
    mPrivate->mFollowers.reserve(knownFollowers->mFollowers.size());

    for (const auto& follower : knownFollowers->mFollowers)
    {
        mPrivate->mFollowers.push_back(BasicProfile(follower));

        // Cap followers to the maximum to be safe in case the networks gives
        // much more.
        if (mPrivate->mFollowers.size() >= ATProto::AppBskyActor::KnownFollowers::MAX_COUNT)
            break;
    }
}

const QList<BasicProfile>& KnownFollowers::getFollowers() const
{
    if (!mPrivate)
    {
        static const QList<BasicProfile> NULL_LIST;
        return NULL_LIST;
    }

    return mPrivate->mFollowers;
}

ProfileViewerState::ProfileViewerState(const ATProto::AppBskyActor::ViewerState::SharedPtr& viewerState) :
    mPrivate{std::make_shared<PrivateData>(viewerState)}
{
}

bool ProfileViewerState::isValid() const
{
    return mPrivate != nullptr && mPrivate->mViewerState != nullptr;
}

bool ProfileViewerState::isMuted() const
{
    return mPrivate && mPrivate->mViewerState ? mPrivate->mViewerState->mMuted : false;
}

bool ProfileViewerState::isBlockedBy() const
{
    return mPrivate && mPrivate->mViewerState ? mPrivate->mViewerState->mBlockedBy : false;
}

const QString& ProfileViewerState::getBlocking() const
{
    return mPrivate && mPrivate->mViewerState && mPrivate->mViewerState->mBlocking ? *mPrivate->mViewerState->mBlocking : NULL_STRING;
}

const QString& ProfileViewerState::getFollowing() const
{
    return mPrivate && mPrivate->mViewerState && mPrivate->mViewerState->mFollowing ? *mPrivate->mViewerState->mFollowing : NULL_STRING;
}

const QString& ProfileViewerState::getFollowedBy() const
{
    return mPrivate && mPrivate->mViewerState && mPrivate->mViewerState->mFollowedBy ? *mPrivate->mViewerState->mFollowedBy : NULL_STRING;
}

const ListViewBasic& ProfileViewerState::getMutedByList() const
{
    if (mPrivate && mPrivate->mMutedByList)
        return *mPrivate->mMutedByList;

    if (mPrivate)
    {
        if (mPrivate->mViewerState && mPrivate->mViewerState->mMutedByList)
            mPrivate->mMutedByList = ListViewBasic(mPrivate->mViewerState->mMutedByList);
        else
            mPrivate->mMutedByList = ListViewBasic{};
    }
    else
    {
        const_cast<ProfileViewerState*>(this)->mPrivate = std::make_shared<PrivateData>();
        mPrivate->mMutedByList = ListViewBasic{};
    }

    return *mPrivate->mMutedByList;
}

const ListViewBasic& ProfileViewerState::getBlockingByList() const
{
    if (mPrivate && mPrivate->mBlockedByList)
        return *mPrivate->mBlockedByList;

    if (mPrivate)
    {
        if (mPrivate->mViewerState && mPrivate->mViewerState->mBlockingByList)
           mPrivate->mBlockedByList = ListViewBasic(mPrivate->mViewerState->mBlockingByList);
        else
            mPrivate->mBlockedByList = ListViewBasic{};
    }
    else
    {
        const_cast<ProfileViewerState*>(this)->mPrivate = std::make_shared<PrivateData>();
        mPrivate->mBlockedByList = ListViewBasic{};
    }

    return *mPrivate->mBlockedByList;
}

const KnownFollowers& ProfileViewerState::getKnownFollowers() const
{
    if (mPrivate && mPrivate->mKnownFollowers)
        return *mPrivate->mKnownFollowers;

    if (mPrivate)
    {
        mPrivate->mKnownFollowers = mPrivate->mViewerState ? KnownFollowers(mPrivate->mViewerState->mKnownFollowers.get()) : KnownFollowers{};
    }
    else
    {
        const_cast<ProfileViewerState*>(this)->mPrivate = std::make_shared<PrivateData>();
        mPrivate->mKnownFollowers = KnownFollowers{};
    }

    return *mPrivate->mKnownFollowers;
}

ProfileAssociatedChat::ProfileAssociatedChat(const ATProto::AppBskyActor::ProfileAssociatedChat::SharedPtr& associated) :
    mAssociated(associated)
{
}

QEnums::AllowIncomingChat ProfileAssociatedChat::getAllowIncoming() const
{
    // Default bsky setting is following
    return mAssociated ? (QEnums::AllowIncomingChat)mAssociated->mAllowIncoming : QEnums::ALLOW_INCOMING_CHAT_FOLLOWING;
}


ProfileAssociated::ProfileAssociated(const ATProto::AppBskyActor::ProfileAssociated::SharedPtr& associated) :
    mAssociated(associated)
{
}

BasicProfile::BasicProfile(const ATProto::AppBskyActor::ProfileViewBasic::SharedPtr& profile) :
    mPrivate{std::make_shared<PrivateData>(profile)}
{
    Q_ASSERT(mPrivate->mProfileBasicView);
}

BasicProfile::BasicProfile(const ATProto::AppBskyActor::ProfileView::SharedPtr& profile) :
    mProfileView(profile)
{
    Q_ASSERT(mProfileView);
}

BasicProfile::BasicProfile(const ATProto::AppBskyActor::ProfileViewDetailed::SharedPtr& profile) :
    mProfileDetailedView(profile)
{
    Q_ASSERT(mProfileDetailedView);
}

BasicProfile::BasicProfile(const QString& did, const QString& handle, const QString& displayName,
                           const QString& avatarUrl, const ProfileAssociated& associated,
                           const ProfileViewerState& viewer,
                           const ContentLabelList& contentLabels) :
    mPrivate{std::make_shared<PrivateData>(
        nullptr,
        did,
        handle,
        displayName,
        avatarUrl,
        nullptr,
        associated,
        viewer,
        contentLabels)}
{
}

bool BasicProfile::isNull() const
{
    return getDid().isEmpty();
}

const QString& BasicProfile::getDid() const
{
    if (mPrivate)
    {
        if (mPrivate->mDid)
            return *mPrivate->mDid;

        if (mPrivate->mProfileBasicView)
            return mPrivate->mProfileBasicView->mDid;
    }

    if (mProfileView)
        return mProfileView->mDid;

    if (mProfileDetailedView)
        return mProfileDetailedView->mDid;

    return NULL_STRING;
}

static QString createName(const QString& handle, const QString& displayName)
{
    const QString name = displayName.trimmed();
    return name.isEmpty() ? handle : name;
}

QString BasicProfile::getName() const
{
    const QString name = createName(getHandle(), getDisplayName());

    if (hasInvalidHandle())
        return QString("⚠️ %1").arg(name);

    return name;
}

const QString& BasicProfile::getDisplayName() const
{
    if (mPrivate)
    {
        if (mPrivate->mDisplayName)
            return *mPrivate->mDisplayName;

        if (mPrivate->mProfileBasicView)
            return mPrivate->mProfileBasicView->mDisplayName ? *mPrivate->mProfileBasicView->mDisplayName : NULL_STRING;
    }

    if (mProfileView)
        return mProfileView->mDisplayName ? *mProfileView->mDisplayName : NULL_STRING;

    if (mProfileDetailedView)
        return mProfileDetailedView->mDisplayName ? *mProfileDetailedView->mDisplayName : NULL_STRING;

    return NULL_STRING;
}

const QString& BasicProfile::getHandle() const
{
    if (mPrivate)
    {
        if (mPrivate->mHandle)
            return *mPrivate->mHandle;

        if (mPrivate->mProfileBasicView)
            return mPrivate->mProfileBasicView->mHandle;
    }

    if (mProfileView)
        return mProfileView->mHandle;

    if (mProfileDetailedView)
        return mProfileDetailedView->mHandle;

    return NULL_STRING;
}

bool BasicProfile::hasInvalidHandle() const
{
    return getHandle().endsWith(INVALID_HANDLE_SUFFIX);
}

const QString& BasicProfile::getHandleOrDid() const
{
    const QString& handle = getHandle();

    if (handle.isEmpty() || handle.endsWith(INVALID_HANDLE_SUFFIX))
        return getDid();

    return handle;
}

const QString& BasicProfile::getAvatarUrl() const
{
    if (mPrivate)
    {
        if (mPrivate->mAvatarUrl)
            return *mPrivate->mAvatarUrl;

        if (mPrivate->mProfileBasicView)
            return mPrivate->mProfileBasicView->mAvatar ? *mPrivate->mProfileBasicView->mAvatar : NULL_STRING;
    }

    if (mProfileView)
        return mProfileView->mAvatar? *mProfileView->mAvatar : NULL_STRING;

    if (mProfileDetailedView)
        return mProfileDetailedView->mAvatar ? *mProfileDetailedView->mAvatar : NULL_STRING;

    return NULL_STRING;
}

QString BasicProfile::getAvatarThumbUrl() const
{
    return ATProto::createAvatarThumbUrl(getAvatarUrl());
}

ImageView BasicProfile::getImageView() const
{
    return ImageView(getAvatarUrl(), getName());
}

ProfileAssociated BasicProfile::getAssociated() const
{
    if (mPrivate)
    {
        if (mPrivate->mAssociated)
            return *mPrivate->mAssociated;

        if (mPrivate->mProfileBasicView)
            return mPrivate->mProfileBasicView->mAssociated ? ProfileAssociated(mPrivate->mProfileBasicView->mAssociated) : ProfileAssociated{};
    }

    if (mProfileView)
        return mProfileView->mAssociated ? ProfileAssociated(mProfileView->mAssociated) : ProfileAssociated{};

    if (mProfileDetailedView)
        return mProfileDetailedView->mAssociated ? ProfileAssociated(mProfileDetailedView->mAssociated) : ProfileAssociated{};

    return {};
}

const ProfileViewerState& BasicProfile::getViewer() const
{
    if (mPrivate)
    {
        if (mPrivate->mViewer)
            return *mPrivate->mViewer;

        if (mPrivate->mProfileBasicView)
            mPrivate->mViewer = mPrivate->mProfileBasicView->mViewer ? ProfileViewerState(mPrivate->mProfileBasicView->mViewer) : ProfileViewerState{};
        else
            mPrivate->mViewer = ProfileViewerState{};

        return *mPrivate->mViewer;
    }
    else
    {
        const_cast<BasicProfile*>(this)->mPrivate = std::make_shared<PrivateData>();
    }

    if (mProfileView)
        mPrivate->mViewer = mProfileView->mViewer ? ProfileViewerState(mProfileView->mViewer) : ProfileViewerState{};
    else if (mProfileDetailedView)
        mPrivate->mViewer = mProfileDetailedView->mViewer ? ProfileViewerState(mProfileDetailedView->mViewer) : ProfileViewerState{};
    else
        mPrivate->mViewer = ProfileViewerState{};

    return *mPrivate->mViewer;
}

const ContentLabelList& BasicProfile::getContentLabels() const
{
    if (mPrivate && mPrivate->mContentLabels)
        return *mPrivate->mContentLabels;

    const ContentFilter::LabelList* labels = nullptr;

    if (mPrivate && mPrivate->mProfileBasicView)
        labels = &mPrivate->mProfileBasicView->mLabels;
    else if (mProfileView)
        labels = &mProfileView->mLabels;
    else if (mProfileDetailedView)
        labels = &mProfileDetailedView->mLabels;

    if (!mPrivate)
        const_cast<BasicProfile*>(this)->mPrivate = std::make_shared<PrivateData>();

    if (labels)
        mPrivate->mContentLabels = ContentFilter::getContentLabels(*labels);
    else
        mPrivate->mContentLabels = ContentLabelList{};

    return *mPrivate->mContentLabels;
}

void BasicProfile::setDisplayName(const QString& displayName)
{
    if (!mPrivate)
        mPrivate = std::make_shared<PrivateData>();

    mPrivate->mDisplayName = displayName;
}

void BasicProfile::setAvatarUrl(const QString& avatarUrl)
{
    if (!mPrivate)
        mPrivate = std::make_shared<PrivateData>();

    mPrivate->mAvatarUrl = avatarUrl;

    if (avatarUrl.startsWith("image://"))
    {
        auto* provider = SharedImageProvider::getProvider(SharedImageProvider::SHARED_IMAGE);
        mPrivate->mAvatarSource = std::make_shared<SharedImageSource>(avatarUrl, provider);
    }
    else
    {
        mPrivate->mAvatarSource = nullptr;
    }
}

bool BasicProfile::isFixedLabeler() const
{
    return ContentFilter::isFixedLabelerSubscription(getDid());
}

bool BasicProfile::canSendDirectMessage() const
{
    const auto allowIncoming = getAssociated().getChat().getAllowIncoming();

    switch (allowIncoming)
    {
    case QEnums::ALLOW_INCOMING_CHAT_NONE:
        return false;
    case QEnums::ALLOW_INCOMING_CHAT_ALL:
        return true;
    case QEnums::ALLOW_INCOMING_CHAT_FOLLOWING:
        return !getViewer().getFollowedBy().isEmpty();
    }

    qWarning() << "Unknown allow incoming value:" << allowIncoming;
    return false;
}

bool BasicProfile::isBlocked() const
{
    const auto viewer = getViewer();
    return viewer.isBlockedBy() || !viewer.getBlocking().isEmpty() || !viewer.getBlockingByList().isNull();
}

Profile::Profile(const ATProto::AppBskyActor::ProfileView::SharedPtr& profile) :
    BasicProfile(profile)
{
}

Profile::Profile(const ATProto::AppBskyActor::ProfileViewDetailed::SharedPtr& profile) :
    BasicProfile(profile)
{
}

QString Profile::getDescription() const
{
    if (mDescription)
        return *mDescription;

    if (mProfileView)
        return mProfileView->mDescription.value_or("");

    if (mProfileDetailedView)
        return mProfileDetailedView->mDescription.value_or("");

    return {};
}

DetailedProfile::DetailedProfile(const ATProto::AppBskyActor::ProfileViewDetailed::SharedPtr& profile) :
    Profile(profile)
{
}

QString DetailedProfile::getBanner() const
{
    return mProfileDetailedView ? mProfileDetailedView->mBanner.value_or("") : "";
}

int DetailedProfile::getFollowersCount() const
{
    return mProfileDetailedView ? mProfileDetailedView->mFollowersCount : 0;
}

int DetailedProfile::getFollowsCount() const
{
    return mProfileDetailedView ? mProfileDetailedView->mFollowsCount : 0;
}

int DetailedProfile::getPostsCount() const
{
    return mProfileDetailedView ? mProfileDetailedView->mPostsCount : 0;
}

QString DetailedProfile::getPinnedPostUri() const
{
    return mProfileDetailedView && mProfileDetailedView->mPinnedPost ? mProfileDetailedView->mPinnedPost->mUri : "";
}

}
