// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "edit_user_preferences.h"
#include "definitions.h"

namespace Skywalker {

EditUserPreferences::EditUserPreferences(QObject* parent) :
    QObject(parent)
{
}

const QString EditUserPreferences::getBirthDate() const
{
    if (!mBirthDate)
        return {};

    const auto date = mBirthDate->date();
    return date.toString(QLocale().dateFormat(QLocale::ShortFormat));
}

void EditUserPreferences::setUserPreferences(const ATProto::UserPreferences& userPreferences)
{
    mBirthDate = userPreferences.getBirthDate();
    mHomeFeedPref = userPreferences.getFeedViewPref(HOME_FEED);
    mVerificationPrefs = userPreferences.getVerificationPrefs();
}

void EditUserPreferences::saveTo(ATProto::UserPreferences& userPreferences)
{
    userPreferences.setFeedViewPref(mHomeFeedPref);
    userPreferences.setVerificationPrefs(mVerificationPrefs);
}

void EditUserPreferences::setLoggedOutVisibility(bool visibility)
{
    if (visibility != mLoggedOutVisibility)
    {
        mLoggedOutVisibility = visibility;
        emit loggedOutVisibilityChanged();
    }
}

void EditUserPreferences::setHideReplies(bool hide)
{
    if (hide != mHomeFeedPref.mHideReplies)
    {
        mHomeFeedPref.mHideReplies = hide;
        mModified = true;
        emit hideRepliesChanged();
    }
}

void EditUserPreferences::setHideRepliesByUnfollowed(bool hide)
{
    if (hide != mHomeFeedPref.mHideRepliesByUnfollowed)
    {
        mHomeFeedPref.mHideRepliesByUnfollowed = hide;
        mModified = true;
        emit hideRepliesByUnfollowedChanged();
    }
}

void EditUserPreferences::setHideReposts(bool hide)
{
    if (hide != mHomeFeedPref.mHideReposts)
    {
        mHomeFeedPref.mHideReposts = hide;
        mModified = true;
        emit hideRepostsChanged();
    }
}

void EditUserPreferences::setHideQuotePosts(bool hide)
{
    if (hide != mHomeFeedPref.mHideQuotePosts)
    {
        mHomeFeedPref.mHideQuotePosts = hide;
        mModified = true;
        emit hideQuotePostsChanged();
    }
}

void EditUserPreferences::setHideVerificationBadges(bool hide)
{
    if (hide != mVerificationPrefs.mHideBadges)
    {
        mVerificationPrefs.mHideBadges = hide;
        mModified = true;
        emit hideVerificationBadgesChanged();
    }
}

void EditUserPreferences::setAllowIncomingChat(QEnums::AllowIncomingChat allowIncomingChat)
{
    if (allowIncomingChat != mAllowIncomingChat)
    {
        mAllowIncomingChat = allowIncomingChat;
        emit allowIncomingChatChanged();
    }
}

}
