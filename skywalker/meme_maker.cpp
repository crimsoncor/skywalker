// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#include "meme_maker.h"
#include "photo_picker.h"
#include "unicode_fonts.h"
#include <QFont>
#include <QPainter>
#include <QPainterPath>

namespace Skywalker {

constexpr int FONT_MAX_PX = 32;
constexpr int FONT_MIN_PX = 20;
constexpr int MARGIN = 10;
constexpr int MAX_TEXT_PATHS = 4;

MemeMaker::MemeMaker(QObject* parent) :
    QObject(parent)
{}

bool MemeMaker::setOrigImage(const QString& imgSource)
{
    mOrigImage = PhotoPicker::loadImage(imgSource);

    if (mOrigImage.isNull())
        return false;

    auto* imageProvider = SharedImageProvider::getProvider(SharedImageProvider::SHARED_IMAGE);
    const QString memeSource = imageProvider->addImage(mOrigImage);
    setMemeImgSource(memeSource, imageProvider);
    setTopText("");
    setBottomText("");
    return true;
}

void MemeMaker::setScreenWidth(int width)
{
    if (width == mScreenWidth)
        return;

    mScreenWidth = width;
    emit screenWidthChanged();
}

QString MemeMaker::getMemeImgSource() const
{
    return mMemeImgSource ? mMemeImgSource->getSource() : "";
}

void MemeMaker::setMemeImgSource(const QString& source, SharedImageProvider* provider)
{
    mMemeImgSource = std::make_unique<SharedImageSource>(source, provider);
    emit memeImgSourceChanged();
}

void MemeMaker::setTopText(const QString& text)
{
    if (text == mTopText)
        return;

    mTopText = text;
    addText();
    emit topTextChanged();
}

void MemeMaker::setBottomText(const QString& text)
{
    if (text == mBottomText)
        return;

    mBottomText = text;
    addText();
    emit bottomTextChanged();
}

double MemeMaker::sizeRatio() const
{
    return mOrigImage.width() / (float)mScreenWidth;
}

void MemeMaker::center(int maxWidth, QPainterPath& path) const
{
    const int dx = std::max((maxWidth - (int)path.boundingRect().width()), 0) / 2.0;
    path.translate(dx, 0);
}

QPainterPath MemeMaker::createTextPath(int x, int y, const QString& text, int maxWidth, int& fontPx) const
{
    QFont font;
    font.setFamily("Impact");
    font.setPixelSize(fontPx * sizeRatio());
    font.setWeight(QFont::Black);

    QPainterPath path;
    path.setFillRule(Qt::WindingFill);
    path.addText(x, y + font.pixelSize(), font, text);

    while (path.boundingRect().width() > maxWidth && fontPx > FONT_MIN_PX)
    {
        --fontPx;
        font.setPixelSize(fontPx * sizeRatio());
        path.clear();
        path.addText(x, y + font.pixelSize(), font, text);
    }

    center(maxWidth, path);
    return path;
}

std::vector<QPainterPath> MemeMaker::createTextMultiPathList(int x, int y, const QString& text, int maxWidth, int pathCount) const
{
    int fontPx = FONT_MAX_PX;
    std::vector<QPainterPath> paths;
    const int maxLength = text.length() / pathCount + 1;
    const auto textList = UnicodeFonts::splitText(text, maxLength, 1, pathCount);
    int lineY = y;
    fontPx = FONT_MAX_PX;
    int firstLineFontPx = 0;
    int smallestFontPx = FONT_MAX_PX;

    for (const auto& line : textList)
    {
        const auto linePath = createTextPath(x, lineY, line, maxWidth, fontPx);
        paths.push_back(linePath);
        lineY += linePath.boundingRect().height();

        if (firstLineFontPx == 0)
        {
            firstLineFontPx = fontPx;
            smallestFontPx = fontPx;
        }
        else if (fontPx < smallestFontPx)
        {
            smallestFontPx = fontPx;
        }
    }

    if (smallestFontPx < firstLineFontPx)
    {
        paths.clear();
        lineY = y;

        for (const auto& line : textList)
        {
            const auto linePath = createTextPath(x, lineY, line, maxWidth, smallestFontPx);
            paths.push_back(linePath);
            lineY += linePath.boundingRect().height();
        }
    }

    return paths;
}

std::vector<QPainterPath> MemeMaker::createTextPathList(int x, int y, const QString& text, int maxWidth) const
{
    int fontPx = FONT_MAX_PX;
    std::vector<QPainterPath> paths;
    const auto path = createTextPath(x, y, text, maxWidth, fontPx);

    if (path.boundingRect().width() <= maxWidth)
    {
        paths.push_back(path);
        return paths;
    }

    int pathCount = 2;
    bool done = false;

    while (!done && pathCount <= MAX_TEXT_PATHS)
    {
        paths = createTextMultiPathList(x, y, text, maxWidth, pathCount);
        done = true;

        for (const auto& p : paths)
        {
            if (p.boundingRect().width() > maxWidth)
            {
                ++pathCount;
                done = false;
                break;
            }
        }
    }

    return paths;
}

static int calcHeight(const std::vector<QPainterPath>& paths)
{
    int height = 0;

    for (const auto& p : paths)
        height += p.boundingRect().height();

    return height;
}

void MemeMaker::moveToBottom(std::vector<QPainterPath>& paths) const
{
    const int height = calcHeight(paths);
    const int dy = mOrigImage.height() - height - MARGIN * sizeRatio();

    for (auto& p : paths)
        p.translate(0, dy);
}

void MemeMaker::addText()
{
    const int x = sizeRatio() * MARGIN;
    const int maxWidth = (mScreenWidth - 2 * MARGIN) * sizeRatio();
    const auto topPaths = createTextPathList(x, 0, mTopText, maxWidth);
    auto bottomPaths = createTextPathList(x, 0, mBottomText, maxWidth);
    moveToBottom(bottomPaths);

    QImage memeImage = mOrigImage;
    QPainter painter;

    if (!painter.begin(&memeImage))
    {
        qWarning() << "Cannot paint on image";
        return;
    }

    QPen pen(Qt::black);
    pen.setWidth(std::max(1.0, sizeRatio()));
    painter.setPen(pen);
    painter.setBrush(Qt::white);

    for (const auto& path : topPaths)
        painter.drawPath(path);

    for (const auto& path : bottomPaths)
        painter.drawPath(path);

    painter.end();

    auto* provider = SharedImageProvider::getProvider(SharedImageProvider::SHARED_IMAGE);
    const QString source = provider->addImage(memeImage);
    setMemeImgSource(source, provider);
}

}
