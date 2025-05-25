// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#include "gif_utils.h"
#include <QUrl>

namespace Skywalker {

namespace {
constexpr char const* TENOR_PREFIX = "https://tenor.com/";
constexpr char const* TENOR_MEDIA_PREFIX = "https://media.tenor.com/";

constexpr char const* GRAYSKY_PREFIX = "https://graysky.app/gif/";

constexpr char const* GIPHY_GIFS_PREFIX = "https://giphy.com/gifs/";
constexpr char const* GIPHY_DOMAIN = "giphy.com";
}

GifUtils::GifUtils(QObject* parent) :
    QObject(parent)
{
}

bool GifUtils::isTenorLink(const QString& link) const
{
    return link.startsWith(TENOR_PREFIX) ||
           link.startsWith(TENOR_MEDIA_PREFIX) ||
           link.startsWith(GRAYSKY_PREFIX);
}

bool GifUtils::isGiphyLink(const QString& link) const
{
    return link.contains(GIPHY_DOMAIN);
}

Q_INVOKABLE bool GifUtils::isGif(const QString& link) const
{
    return !getGifUrl(link).isEmpty();
}

QString GifUtils::getGifUrl(const QString& link) const
{
    if (link.startsWith(GIPHY_GIFS_PREFIX))
        return getGiphyGifUrl(link);

    // E.g. https://media.giphy.com/media/, https://media0.giphy.com/media/
    if (link.startsWith("https://media") && link.contains(GIPHY_DOMAIN + QString("/media/")))
        return getGiphyMediaUrl(link);

    if (link.startsWith(TENOR_PREFIX))
        return getTenorViewGif(link);

    if (link.startsWith(GRAYSKY_PREFIX))
    {
        const QString tenorLink = convertGrayskyToTenor(link);
        return tenorLink.isEmpty() ? "" : getTenorMediaGif(tenorLink);
    }

    if (link.startsWith(TENOR_MEDIA_PREFIX))
        return getTenorMediaGif(link);

    return {};
}

double GifUtils::gitAspectRatio(const QString& link) const
{
    const QUrl url(link);

    if (!url.hasQuery())
        return 0.0;

    const QUrlQuery query(url.query());

    // These query parameters are available in Tenor links
    if (!query.hasQueryItem("hh") || !query.hasQueryItem("ww"))
        return 0.0;

    const int width = query.queryItemValue("ww").toInt();

    if (width <= 0)
        return 0.0;

    const int height = query.queryItemValue("hh").toInt();

    if (height <= 0)
        return 0.0;

    const double ratio = double(height) / double(width);
    qDebug() << "Aspect ratio:" << ratio << "GIF:" << link;

    return ratio;
}

// Example: https://giphy.com/gifs/ufc-sport-297-ufc297-ycTrWycYMLlUNoHl73
// Result:  https://i.giphy.com/ycTrWycYMLlUNoHl73.gif
QString GifUtils::getGiphyGifUrl(const QString& link) const
{
    const QUrl url(link);
    if (!url.isValid())
        return {};

    const auto pathParts = url.path().split("/", Qt::SkipEmptyParts);
    if (pathParts.isEmpty())
        return {};

    const auto& gifLongId = pathParts.back();
    const auto gifLongIdParts = gifLongId.split("-");
    const auto& gifId = gifLongIdParts.back();
    const QString gifLink = "https://i.giphy.com/" + gifId + ".gif";

    return gifLink;
}

QString GifUtils::getGiphyMediaUrl(const QString& link) const
{
    const QUrl url(link);

    if (!url.isValid())
        return {};

    const QString gifLink = url.toString(QUrl::RemoveQuery);
    return gifLink.endsWith(".gif") ? gifLink : "";
}

// Example: https://tenor.com/view/happy-thursday-mawnin-gif-8975369713728247911
// Result:  https://tenor.com/view/happy-thursday-mawnin-gif-8975369713728247911.gif
// NOTE: there can be a county code between the host and "view", e.g. https://tenor.com/nl/view/
QString GifUtils::getTenorViewGif(const QString& link) const
{
    const QUrl url(link);
    if (!url.isValid())
        return {};

    const QString path = url.path();
    if (!path.contains("/view/"))
        return {};

    const QString gifLink = url.toString(QUrl::RemoveQuery) + ".gif";
    return gifLink;
}

// Qt6 has a bug that blocks playing video from a https source.
// As a workaround we convert the MP4 url from Tenor to GIF (this may not work forever)
// These are examples of Tenor URL's:
//
// https://media.tenor.com/2w1XsfvQD5kAAAPo/hhgf.mp4 (normal MP4 format)
// https://media.tenor.com/2w1XsfvQD5kAAAAd/hhgf.gif (medium GIF format)
//
// The last 2 characters of the TenorId, e.g. 2w1XsfvQD5kAAAPo indicates the format.
//
// Po = normal MP4
// Ad = medium GIF
QString GifUtils::getTenorMediaGif(const QString& link) const
{
    const QUrl url(link);

    if (!url.isValid())
        return {};

    if (url.path().endsWith(".mp4") || url.path().endsWith(".webm"))
    {
        auto pathParts = url.path().split("/", Qt::SkipEmptyParts);

        if (pathParts.size() < 2)
            return {};

        const QString& tenorId = pathParts[pathParts.size() - 2];

        if (tenorId.size() < 3)
        {
            qWarning() << "Unknown Tenor ID:" << tenorId << "link:" << link;
            return {};
        }

        const QString baseTenorId = tenorId.sliced(0, tenorId.length() - 2);
        const QString fileName = pathParts.back();
        const QString baseFileName = fileName.split(".")[0];

        pathParts[pathParts.size() - 2] = baseTenorId + "Ad";
        pathParts[pathParts.size() - 1] = baseFileName + ".gif";
        const QString gifLink = TENOR_MEDIA_PREFIX + pathParts.join("/");
        return gifLink;
    }

    if (url.path().endsWith(".gif"))
        return link;

    return {};
}

// Graysky wraps Tenor media links
// Example: https://graysky.app/gif/nG9mD0Dl8vsAAAPo/yay.mp4?title=Yay%20GIF
// Tenor:   https://media.tenor.com/nG9mD0Dl8vsAAAPo/yay.mp4
QString GifUtils::convertGrayskyToTenor(const QString& link) const
{
    const QUrl url(link);
    if (!url.isValid())
        return {};

    const QString removedQuery = url.toString(QUrl::RemoveQuery);
    const QString gifUrl = TENOR_MEDIA_PREFIX + removedQuery.sliced(QString(GRAYSKY_PREFIX).length());
    qDebug() << "GIF url:" << gifUrl;
    return gifUrl;
}

}
