// Copyright (C) 2023 Michel de Boer
// License: GPLv3
#include "post_utils.h"
#include "jni_callback.h"
#include "photo_picker.h"

namespace Skywalker {

PostUtils::PostUtils(QObject* parent) :
    QObject(parent)
{
    auto& jniCallbackListener = JNICallbackListener::getInstance();
    QObject::connect(&jniCallbackListener, &JNICallbackListener::photoPicked,
                     this, [this](const QString& uri){
                         qDebug() << "PHOTO PICKED:" << uri;
                         QString fileName = resolveContentUriToFile(uri);
                         qDebug() << "PHOTO FILE NAME:" << fileName;
                         QFile file(fileName);
                         qDebug() << "File exists:" << file.exists() << ",size:" << file.size();
                         emit photoPicked(fileName);
                     });
}

ATProto::Client* PostUtils::bskyClient()
{
    Q_ASSERT(mSkywalker);
    auto* client = mSkywalker->getBskyClient();
    Q_ASSERT(client);
    return client;
}

ImageReader* PostUtils::imageReader()
{
    if (!mImageReader)
        mImageReader = std::make_unique<ImageReader>();

    return mImageReader.get();
}

void PostUtils::setSkywalker(Skywalker* skywalker)
{
    mSkywalker = skywalker;
    emit skywalkerChanged();
}

static ATProto::AppBskyFeed::PostReplyRef::Ptr createReplyRef(
        const QString& replyToUri, const QString& replyToCid,
        const QString& replyRootUri, const QString& replyRootCid)
{
    if (replyToUri.isEmpty() || replyToCid.isEmpty())
        return nullptr;

    auto replyRef = std::make_unique<ATProto::AppBskyFeed::PostReplyRef>();

    replyRef->mParent = std::make_unique<ATProto::ComATProtoRepo::StrongRef>();
    replyRef->mParent->mUri = replyToUri;
    replyRef->mParent->mCid = replyToCid;

    replyRef->mRoot = std::make_unique<ATProto::ComATProtoRepo::StrongRef>();
    replyRef->mRoot->mUri = replyRootUri.isEmpty() ? replyToUri : replyRootUri;
    replyRef->mRoot->mCid = replyRootCid.isEmpty() ? replyToCid : replyRootCid;

    return replyRef;
}

void PostUtils::post(QString text, const QStringList& imageFileNames,
                     const QString& replyToUri, const QString& replyToCid,
                     const QString& replyRootUri, const QString& replyRootCid,
                     const QString& quoteUri, const QString& quoteCid)
{
    Q_ASSERT(mSkywalker);
    qDebug() << "Posting:" << text;

    if (replyToUri.isEmpty())
    {
        bskyClient()->createPost(text, nullptr, [this, imageFileNames, quoteUri, quoteCid](auto post){
            continuePost(imageFileNames, post, quoteUri, quoteCid); });
        return;
    }

    bskyClient()->checkPostExists(replyToUri, replyToCid,
        [this, text, imageFileNames, replyToUri, replyToCid, replyRootUri, replyRootCid, quoteUri, quoteCid]
        {
            auto replyRef = createReplyRef(replyToUri, replyToCid, replyRootUri, replyRootCid);

            bskyClient()->createPost(text, std::move(replyRef), [this, imageFileNames, quoteUri, quoteCid](auto post){
                continuePost(imageFileNames, post, quoteUri, quoteCid); });
        },
        [this] (const QString& error){
            qDebug() << "Post not found:" << error;
            emit postFailed(tr("It seems the post you reply to has been deleted."));
        });
}

void PostUtils::post(QString text, const LinkCard* card,
                     const QString& replyToUri, const QString& replyToCid,
                     const QString& replyRootUri, const QString& replyRootCid,
                     const QString& quoteUri, const QString& quoteCid)
{
    Q_ASSERT(card);
    Q_ASSERT(mSkywalker);
    qDebug() << "Posting:" << text;

    if (replyToUri.isEmpty())
    {
        bskyClient()->createPost(text, nullptr, [this, card, quoteUri, quoteCid](auto post){
            continuePost(card, post, quoteUri, quoteCid); });
        return;
    }

    bskyClient()->checkPostExists(replyToUri, replyToCid,
        [this, text, card, replyToUri, replyToCid, replyRootUri, replyRootCid, quoteUri, quoteCid]
        {
            auto replyRef = createReplyRef(replyToUri, replyToCid, replyRootUri, replyRootCid);

            bskyClient()->createPost(text, std::move(replyRef), [this, card, quoteUri, quoteCid](auto post){
                continuePost(card, post, quoteUri, quoteCid); });
        },
        [this](const QString& error){
            qDebug() << "Post not found:" << error;
            emit postFailed(tr("It seems the post you reply to has been deleted."));
        });
}

void PostUtils::continuePost(const QStringList& imageFileNames, ATProto::AppBskyFeed::Record::Post::SharedPtr post,
                             const QString& quoteUri, const QString& quoteCid)
{
    if (quoteUri.isEmpty())
    {
        continuePost(imageFileNames, post);
        return;
    }

    bskyClient()->checkPostExists(quoteUri, quoteCid,
        [this, imageFileNames, post, quoteUri, quoteCid]{
            bskyClient()->addQuoteToPost(*post, quoteUri, quoteCid);
            continuePost(imageFileNames, post);
        },
        [this](const QString& error){
            qDebug() << "Post not found:" << error;
            emit postFailed(tr("It seems the quoted post has been deleted."));
        });
}

void PostUtils::continuePost(const QStringList& imageFileNames, ATProto::AppBskyFeed::Record::Post::SharedPtr post, int imgIndex)
{
    if (imgIndex >= imageFileNames.size())
    {
        continuePost(post);
        return;
    }

    const auto& fileName = imageFileNames[imgIndex];
    QByteArray blob;
    const QString mimeType = createBlob(blob, fileName);

    if (blob.isEmpty())
    {
        const QString error = tr("Could not load image") + ": " + QFileInfo(fileName).fileName();
        emit postFailed(error);
        return;
    }

    emit postProgress(tr("Uploading image") + QString(" #%1").arg(imgIndex + 1));

    bskyClient()->uploadBlob(blob, mimeType,
        [this, imageFileNames, post, imgIndex](auto blob){
            bskyClient()->addImageToPost(*post, std::move(blob));
            continuePost(imageFileNames, post, imgIndex + 1);
        },
        [this](const QString& error){
            qDebug() << "Post failed:" << error;
            emit postFailed(error);
        });
}

void PostUtils::continuePost(const LinkCard* card, ATProto::AppBskyFeed::Record::Post::SharedPtr post,
                             const QString& quoteUri, const QString& quoteCid)
{
    if (quoteUri.isEmpty())
    {
        continuePost(card, post);
        return;
    }

    bskyClient()->checkPostExists(quoteUri, quoteCid,
        [this, card, post, quoteUri, quoteCid]{
            bskyClient()->addQuoteToPost(*post, quoteUri, quoteCid);
            continuePost(card, post);
        },
        [this](const QString& error){
            qDebug() << "Post not found:" << error;
            emit postFailed(tr("It seems the quoted post has been deleted."));
        });
}

void PostUtils::continuePost(const LinkCard* card, ATProto::AppBskyFeed::Record::Post::SharedPtr post)
{
    Q_ASSERT(card);
    if (card->getThumb().isEmpty())
    {
        continuePost(card, QImage(), post);
        return;
    }

    emit postProgress(tr("Retrieving card image"));

    imageReader()->getImage(card->getThumb(),
        [this, card, post](auto image){
            continuePost(card, image, post);
        },
        [this](const QString& error){
            qDebug() << "Post failed:" << error;
            emit postFailed(error);
        });
}

void PostUtils::continuePost(const LinkCard* card, QImage thumb, ATProto::AppBskyFeed::Record::Post::SharedPtr post)
{
    Q_ASSERT(card);
    QByteArray blob;
    QString mimeType;

    if (!thumb.isNull())
        mimeType = createBlob(blob, thumb, card->getThumb());

    if (blob.isEmpty())
    {
        bskyClient()->addExternalToPost(*post, card->getLink(), card->getTitle(), card->getDescription());
        continuePost(post);
        return;
    }

    emit postProgress(tr("Uploading card image"));

    bskyClient()->uploadBlob(blob, mimeType,
        [this, card, post](auto blob){
            bskyClient()->addExternalToPost(*post, card->getLink(), card->getTitle(),
                    card->getDescription(), std::move(blob));
            continuePost(post);
        },
        [this](const QString& error){
            qDebug() << "Post failed:" << error;
            emit postFailed(error);
        });
}

void PostUtils::continuePost(ATProto::AppBskyFeed::Record::Post::SharedPtr post)
{
    emit postProgress(tr("Posting"));
    bskyClient()->post(*post,
        [this]{
            emit postOk();
        },
        [this](const QString& error){
            qDebug() << "Post failed:" << error;
            emit postFailed(error);
        });
}

void PostUtils::pickPhoto() const
{
    ::Skywalker::pickPhoto();
}

void PostUtils::setFirstWebLink(const QString& link)
{
    if (link == mFirstWebLink)
        return;

    mFirstWebLink = link;
    emit firstWebLinkChanged();
}

QString PostUtils::highlightMentionsAndLinks(const QString& text, const QString& preeditText, int cursor)
{
    const QString fullText = text.sliced(0, cursor) + preeditText + text.sliced(cursor);

    const auto facets = bskyClient()->parseFacets(fullText);

    // Keep all white space as the user is editing plain text.
    // We only use HTML for highlighting links and mentions
    QString highlighted = "<span style=\"white-space: pre-wrap\">";

    int pos = 0;
    bool webLinkFound = false;
    mLinkShorteningReduction = 0;

    for (const auto& facet : facets)
    {
        if (facet.mType == ATProto::Client::ParsedMatch::Type::LINK)
        {
            if (!webLinkFound)
            {
                setFirstWebLink(facet.mMatch);
                webLinkFound = true;
            }

            const auto shortLink = ATProto::Client::shortenWebLink(facet.mMatch);
            const int reduction = graphemeLength(facet.mMatch) - graphemeLength(shortLink);
            qDebug() << "SHORT:" << shortLink << "reduction:" << reduction;
            mLinkShorteningReduction += reduction;
        }

        const auto before = fullText.sliced(pos, facet.mStartIndex - pos);
        highlighted.append(before.toHtmlEscaped());
        QString highlight = QString("<font color=\"blue\">%1</font>").arg(facet.mMatch);
        highlighted.append(highlight);
        pos = facet.mEndIndex;
    }

    if (!webLinkFound)
        setFirstWebLink(QString());

    highlighted.append(fullText.sliced(pos).toHtmlEscaped());
    highlighted.append("</span>");
    return highlighted;
}

int PostUtils::graphemeLength(const QString& text) const
{
    QTextBoundaryFinder boundaryFinder(QTextBoundaryFinder::Grapheme, text);
    int length = 0;

    while (boundaryFinder.toNextBoundary() != -1)
        ++length;

    return length;
}

}
