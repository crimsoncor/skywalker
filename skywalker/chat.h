// Copyright (C) 2024 Michel de Boer
// License: GPLv3
#pragma once
#include "convo_list_model.h"
#include "message_list_model.h"
#include "presence.h"
#include <atproto/lib/chat_master.h>
#include <atproto/lib/client.h>
#include <atproto/lib/post_master.h>

namespace Skywalker {

class Chat : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ConvoListModel* convoListModel READ getConvoListModel CONSTANT FINAL)
    Q_PROPERTY(int unreadCount READ getUnreadCount NOTIFY unreadCountChanged FINAL)
    Q_PROPERTY(bool getConvosInProgress READ isGetConvosInProgress NOTIFY getConvosInProgressChanged FINAL)
    Q_PROPERTY(bool startConvoInProgress READ isStartConvoInProgress NOTIFY startConvoInProgressChanged FINAL)
    Q_PROPERTY(bool getMessagesInProgress READ isGetMessagesInProgress NOTIFY getMessagesInProgressChanged FINAL)

public:
    explicit Chat(ATProto::Client::Ptr& bsky, const QString& mUserDid, QObject* parent = nullptr);

    void reset();

    Q_INVOKABLE void getConvos(const QString& cursor = "");
    Q_INVOKABLE void getConvosNextPage();
    Q_INVOKABLE void updateConvos();
    Q_INVOKABLE void startConvoForMembers(const QStringList& dids);
    Q_INVOKABLE void startConvoForMember(const QString& did);
    Q_INVOKABLE bool convosLoaded() const { return mLoaded; }

    ConvoListModel* getConvoListModel() { return &mConvoListModel; }
    int getUnreadCount() const { return mUnreadCount; }

    bool isGetConvosInProgress() const { return mGetConvosInProgress; }
    void setConvosInProgress(bool inProgress);

    bool isStartConvoInProgress() const { return mStartConvoInProgress; }
    void setStartConvoInProgress(bool inProgress);

    Q_INVOKABLE MessageListModel* getMessageListModel(const QString& convoId);
    Q_INVOKABLE void removeMessageListModel(const QString& convoId);

    Q_INVOKABLE void getMessages(const QString& convoId, const QString& cursor = "");
    Q_INVOKABLE void getMessagesNextPage(const QString& convoId);
    Q_INVOKABLE void updateMessages(const QString& convoId);
    Q_INVOKABLE void updateRead(const QString& convoId, const QString& messageId);

    Q_INVOKABLE void sendMessage(const QString& convoId, const QString& text, const QString& quoteUri, const QString& quoteCid);

    bool isGetMessagesInProgress() const { return mGetMessagesInProgress; }
    void setMessagesInProgress(bool inProgress);

    void pause();
    void resume();

signals:
    void unreadCountChanged();
    void getConvosInProgressChanged();
    void getConvosFailed(QString error);
    void startConvoForMembersOk(ConvoView convo);
    void startConvoForMembersFailed(QString error);
    void startConvoInProgressChanged();
    void getMessagesInProgressChanged();
    void getMessagesFailed(QString error);
    void sendMessageProgress(QString msg);
    void sendMessageFailed(QString error);
    void sendMessageOk();

private:
    ATProto::ChatMaster* chatMaster();
    ATProto::PostMaster* postMaster();
    void setUnreadCount(int unread);
    void updateUnreadCount(const ATProto::ChatBskyConvo::ConvoListOutput& output);
    void updateMessages();
    void startMessagesUpdateTimer();
    void stopMessagesUpdateTimer();
    void startConvosUpdateTimer();
    void stopConvosUpdateTimer();
    bool isMessagesUpdating(const QString& convoId) const { return mConvoIdUpdatingMessages.contains(convoId); }
    void setMessagesUpdating(const QString& convoId, bool updating);
    void continueSendMessage(const QString& convoId, ATProto::ChatBskyConvo::MessageInput::SharedPtr message, const QString& quoteUri, const QString& quoteCid);
    void continueSendMessage(const QString& convoId, ATProto::ChatBskyConvo::MessageInput::SharedPtr message);

    std::unique_ptr<Presence> mPresence;
    ATProto::Client::Ptr& mBsky;
    std::unique_ptr<ATProto::ChatMaster> mChatMaster;
    std::unique_ptr<ATProto::PostMaster> mPostMaster;
    const QString& mUserDid;
    ConvoListModel mConvoListModel;
    int mUnreadCount = 0;
    bool mGetConvosInProgress = false;
    bool mLoaded = false;
    std::unordered_map<QString, MessageListModel::Ptr> mMessageListModels; // convoId -> model
    std::unordered_set<QString> mConvoIdUpdatingMessages;
    bool mGetMessagesInProgress = false;
    bool mStartConvoInProgress = false;
    QTimer mMessagesUpdateTimer;
    QTimer mConvosUpdateTimer;
};

}
