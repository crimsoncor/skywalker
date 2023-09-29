// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#pragma once
#include <atproto/lib/lexicon/app_bsky_actor.h>
#include <QObject>
#include <QtQmlIntegration>

namespace Skywalker {

class BasicProfile
{
    Q_GADGET
    Q_PROPERTY(QString handle READ getHandle FINAL)
    Q_PROPERTY(QString name READ getName FINAL)
    Q_PROPERTY(QString avatarUrl READ getAvatarUrl FINAL)
    QML_VALUE_TYPE(basicprofile)

public:
    BasicProfile() = default;
    explicit BasicProfile(const ATProto::AppBskyActor::ProfileViewBasic* profile);
    explicit BasicProfile(const ATProto::AppBskyActor::ProfileView* profile);
    BasicProfile(const QString& did, const QString& handle, const QString& displayName, const QString& avatarUrl);
    BasicProfile(const ATProto::AppBskyActor::ProfileView& profile);

    QString getDid() const;
    QString getName() const;
    std::optional<QString> getDisplayName() const;
    QString getHandle() const;
    QString getAvatarUrl() const;

    // The profile is volatile if it depends on pointers to the raw data.
    bool isVolatile() const;

    BasicProfile nonVolatileCopy() const;

private:
    const ATProto::AppBskyActor::ProfileViewBasic* mProfileBasicView = nullptr;
    const ATProto::AppBskyActor::ProfileView* mProfileView = nullptr;
    QString mDid;
    QString mHandle;
    QString mDisplayName;
    QString mAvatarUrl;
};

class CachedBasicProfile : public QObject
{
public:
    CachedBasicProfile() = default;
    explicit CachedBasicProfile(const BasicProfile& profile);

    const BasicProfile& getProfile() const { return mProfile; }

private:
    BasicProfile mProfile;
};

}

Q_DECLARE_METATYPE(Skywalker::BasicProfile)
