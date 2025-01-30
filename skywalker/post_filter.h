// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#pragma once
#include "focus_hashtags.h"
#include "post.h"

namespace Skywalker {

class IPostFilter
{
public:
    using Ptr = std::unique_ptr<IPostFilter>;

    virtual ~IPostFilter() = default;
    virtual QString getName() const = 0;
    virtual QColor getBackgroundColor() const { return "transparent"; }
    virtual BasicProfile getAuthor() const { return BasicProfile{}; }
    virtual QEnums::ContentMode getContentMode() const { return QEnums::CONTENT_MODE_UNSPECIFIED; }
    virtual bool mustAddThread() const { return true; }
    virtual bool match(const Post& post) const = 0;
};

class HashtagPostFilter : public IPostFilter
{
public:
    using Ptr = std::unique_ptr<HashtagPostFilter>;

    explicit HashtagPostFilter(const QString& hashtag);
    QString getName() const override;
    bool match(const Post& post) const override;

private:
    FocusHashtags mFocusHashtags;
};

class FocusHashtagsPostFilter : public IPostFilter
{
public:
    using Ptr = std::unique_ptr<FocusHashtagsPostFilter>;

    explicit FocusHashtagsPostFilter(const FocusHashtagEntry& focusHashtaghEntry);
    QString getName() const override;
    QColor getBackgroundColor() const override;
    bool match(const Post& post) const override;

private:
    const FocusHashtagEntry* getFocusHashtagEntry() const;

    FocusHashtags mFocusHashtags;
};

class AuthorPostFilter : public IPostFilter
{
public:
    using Ptr = std::unique_ptr<AuthorPostFilter>;

    AuthorPostFilter(const BasicProfile& profile);
    QString getName() const override;
    BasicProfile getAuthor() const override;
    bool match(const Post& post) const override;

private:
    BasicProfile mProfile;
};

class VideoPostFilter : public IPostFilter
{
public:
    using Ptr = std::unique_ptr<VideoPostFilter>;

    QString getName() const override;
    QEnums::ContentMode getContentMode() const override { return QEnums::CONTENT_MODE_VIDEO; }
    bool mustAddThread() const override { return false; }
    bool match(const Post& post) const override;
};

class MediaPostFilter : public IPostFilter
{
public:
    using Ptr = std::unique_ptr<MediaPostFilter>;

    QString getName() const override;
    QEnums::ContentMode getContentMode() const override { return QEnums::CONTENT_MODE_MEDIA; }
    bool mustAddThread() const override { return false; }
    bool match(const Post& post) const override;
};

}
