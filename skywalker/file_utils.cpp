// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#include "file_utils.h"
#include "temp_file_holder.h"
#include <QDir>
#include <QStandardPaths>

#ifdef Q_OS_ANDROID
#include "android_utils.h"
#include <QJniObject>
#include <QOperatingSystemVersion>
#include <QtCore/private/qandroidextras_p.h>
#endif

namespace {

constexpr char const* APP_DATA_SUB_DIR = "skywalker";

}

namespace Skywalker::FileUtils {

bool checkReadMediaPermission()
{
#if defined(Q_OS_ANDROID)
    static const QString READ_EXTERNAL_STORAGE = "android.permission.READ_EXTERNAL_STORAGE";
    static const QString READ_MEDIA_IMAGES = "android.permission.READ_MEDIA_IMAGES";

    // Seems to break on Android 14. Retry when using the photo picker again.
    // static const QString READ_MEDIA_VISUAL_USER_SELECTED = "android.permission.READ_MEDIA_VISUAL_USER_SELECTED";

    const auto osVersion = QOperatingSystemVersion::current();

    if (osVersion > QOperatingSystemVersion::Android13)
        return AndroidUtils::checkPermission(READ_MEDIA_IMAGES); // && checkPermission(READ_MEDIA_VISUAL_USER_SELECTED);

    if (osVersion >= QOperatingSystemVersion::Android13)
        return AndroidUtils::checkPermission(READ_MEDIA_IMAGES);

    return AndroidUtils::checkPermission(READ_EXTERNAL_STORAGE);
#else
    return true;
#endif
}

bool checkWriteMediaPermission()
{
#if defined(Q_OS_ANDROID)
    static const QString WRITE_EXTERNAL_STORAGE = "android.permission.WRITE_EXTERNAL_STORAGE";

    const auto osVersion = QOperatingSystemVersion::current();

    if (osVersion < QOperatingSystemVersion::Android11)
        return AndroidUtils::checkPermission(WRITE_EXTERNAL_STORAGE);
#endif
    return true;
}

QString getAppDataPath(const QString& subDir)
{
#if defined(Q_OS_ANDROID)
    QJniObject jsSubDir = QJniObject::fromString(QString("%1/%2").arg(APP_DATA_SUB_DIR, subDir));
    auto pathObj = QJniObject::callStaticMethod<jstring>(
        "com/gmail/mfnboer/FileUtils",
        "getAppDataPath",
        "(Ljava/lang/String;)Ljava/lang/String;",
        jsSubDir.object<jstring>());

    if (!pathObj.isValid())
    {
        qWarning() << "Could not get app data path:" << subDir;
        return {};
    }

    return pathObj.toString();
#else
    auto path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    const QString appDataPath = path + "/" + APP_DATA_SUB_DIR + "/" + subDir;

    if (!QDir().mkpath(appDataPath))
    {
        qWarning() << "Failed to create path:" << appDataPath;
        return {};
    }

    return appDataPath;
#endif
}

QString getPicturesPath()
{
#if defined(Q_OS_ANDROID)
    auto pathObj = QJniObject::callStaticMethod<jstring>("com/gmail/mfnboer/FileUtils",
                                                         "getPicturesPath",
                                                         "()Ljava/lang/String;");

    if (!pathObj.isValid())
    {
        qWarning() << "Invalid path object.";
        return {};
    }

    return pathObj.toString();
#else
    return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
#endif
}

QString getPicturesPath(const QString& subDir)
{
    Q_ASSERT(!subDir.isEmpty());
#if defined(Q_OS_ANDROID)
    auto jsSubDir = QJniObject::fromString(subDir);
    auto pathObj = QJniObject::callStaticMethod<jstring>(
        "com/gmail/mfnboer/FileUtils",
        "getPicturesPath",
        "(Ljava/lang/String;)Ljava/lang/String;",
        jsSubDir.object<jstring>());

    if (!pathObj.isValid())
    {
        qWarning() << "Failed to create pictures path:" << subDir;
        return {};
    }

    const QString picPath = pathObj.toString();
    qDebug() << "Pictures path:" << picPath;
#else
    auto path = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    QString picPath = path + "/" + subDir;

    if (!QDir().mkpath(picPath))
    {
        qWarning() << "Failed to create pictures path:" << picPath;
        return {};
    }
#endif
    return picPath;
}

QString getMoviesPath()
{
#if defined(Q_OS_ANDROID)
    auto pathObj = QJniObject::callStaticMethod<jstring>("com/gmail/mfnboer/FileUtils",
                                                         "getMoviesPath",
                                                         "()Ljava/lang/String;");

    if (!pathObj.isValid())
    {
        qWarning() << "Invalid path object.";
        return {};
    }

    return pathObj.toString();
#else
    return QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
#endif
}

QString getCachePath(const QString& subDir)
{
    Q_ASSERT(!subDir.isEmpty());
#if defined(Q_OS_ANDROID)
    auto jsSubDir = QJniObject::fromString(subDir);
    auto pathObj = QJniObject::callStaticMethod<jstring>(
        "com/gmail/mfnboer/FileUtils",
        "getCachePath",
        "(Ljava/lang/String;)Ljava/lang/String;",
        jsSubDir.object<jstring>());

    if (!pathObj.isValid())
    {
        qWarning() << "Failed to create cache path:" << subDir;
        return {};
    }

    const QString cachePath = pathObj.toString();
    qDebug() << "Cache path:" << cachePath;
    return cachePath;
#else
    auto path = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    const QString cachePath = path + "/" + APP_DATA_SUB_DIR + "/" + subDir;

    if (!QDir().mkpath(cachePath))
    {
        qWarning() << "Failed to create path:" << cachePath;
        return {};
    }

    return cachePath;
#endif
}

int openContentUri(const QString& contentUri)
{
#if defined(Q_OS_ANDROID)
    QJniObject uri = QJniObject::fromString(contentUri);

    int fd = QJniObject::callStaticMethod<int>(
        "com/gmail/mfnboer/FileUtils",
        "openContentUriString",
        "(Ljava/lang/String;)I",
        uri.object<jstring>());

    return fd;
#else
    qWarning() << "Cannot handle content-URI:" << contentUri;
    return -1;
#endif
}

QString resolveContentUriToFile(const QString &contentUriString) {
#ifdef Q_OS_ANDROID
    QJniObject uri = QJniObject::fromString(contentUriString);

    // Call the Java method
    QJniObject result = QJniObject::callStaticObjectMethod(
        "com/gmail/mfnboer/FileUtils",
        "resolveContentUriToFile",
        "(Ljava/lang/String;)Ljava/lang/String;",
        uri.object<jstring>());

    if (!result.isValid())
    {
        qWarning() << "Could not resolve content-uri:" << contentUriString;
        return {};
    }

    return result.toString();
#else
    Q_UNUSED(contentUriString)
    return {};
#endif
}

std::unique_ptr<QTemporaryFile> makeTempFile(const QString& fileExtension, bool cache)
{
    const QString nameTemplate = TempFileHolder::getNameTemplate(fileExtension, cache);
    auto tmpFile = std::make_unique<QTemporaryFile>(nameTemplate);

    if (!tmpFile->open())
    {
        const QString fileError = tmpFile->errorString();
        qWarning() << "Failed to open tmp file:" << fileError;
        return nullptr;
    }

    return tmpFile;
}

std::unique_ptr<QTemporaryFile> createTempFile(const QString& fileUri, const QString& fileExtension)
{
    qDebug() << "Create temp file for:" << fileUri << "ext:" << fileExtension;

    if (!fileUri.startsWith("file://"))
    {
        qWarning() << "Unknow uri scheme:" << fileUri;
        return nullptr;
    }

    const auto fileName = fileUri.sliced(7);
    QFile file(fileName);
    return createTempFile(file, fileExtension);
}

std::unique_ptr<QTemporaryFile> createTempFile(int fd, const QString& fileExtension)
{
    QFile file;

    if (!file.open(fd, QFile::ReadOnly))
    {
        const QString fileError = file.errorString();
        qWarning() << "Failed to open file:" << fileError;
        return nullptr;
    }

    return createTempFile(file, fileExtension);
}

std::unique_ptr<QTemporaryFile> createTempFile(QFile& file, const QString& fileExtension)
{
    qDebug() << "Create temp file, input size:" << file.size();

    if (!file.isOpen())
    {
        if (!file.open(QFile::ReadOnly))
        {
            const QString fileError = file.errorString();
            qWarning() << "Failed to open file:" << fileError;
            return nullptr;
        }
    }

    auto tmpFile = makeTempFile(fileExtension);

    if (!tmpFile)
        return nullptr;

    if (tmpFile->write(file.readAll()) < 0)
    {
        const QString fileError = tmpFile->errorString();
        qWarning() << "Failed to write file to tmp file:" << fileError;
        return nullptr;
    }

    tmpFile->flush();
    tmpFile->close();

    qDebug() << "Created temp file:" << tmpFile->fileName() << tmpFile->size();
    return tmpFile;
}

QString createDateTimeName(QDateTime timestamp)
{
    return timestamp.toString("yyyyMMddhhmmss");
}

void scanMediaFile(const QString& fileName)
{
#if defined(Q_OS_ANDROID)
    auto jsFileName = QJniObject::fromString(fileName);
    QJniObject::callStaticMethod<void>("com/gmail/mfnboer/FileUtils",
                                       "scanMediaFile",
                                       "(Ljava/lang/String;)V",
                                       jsFileName.object<jstring>());
#else
    qDebug() << "No need to scan media:" << fileName;
#endif
}

}
