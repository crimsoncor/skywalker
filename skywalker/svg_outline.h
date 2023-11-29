// Copyright (C) 2023 Michel de Boer

// License: GPLv3
#pragma once
#include "svg_image.h"
#include <QObject>
#include <QtQmlIntegration>

namespace Skywalker {

class SvgOutline : public QObject
{
    Q_OBJECT
    Q_PROPERTY(SvgImage add MEMBER sAdd CONSTANT FINAL)
    Q_PROPERTY(SvgImage addImage MEMBER sAddPhotoAlternate CONSTANT FINAL)
    Q_PROPERTY(SvgImage arrowBack MEMBER sArrowBack CONSTANT FINAL)
    Q_PROPERTY(SvgImage atSign MEMBER sAlternateEmail CONSTANT FINAL)
    Q_PROPERTY(SvgImage block MEMBER sBlock CONSTANT FINAL)
    Q_PROPERTY(SvgImage bookmark MEMBER sBookmark CONSTANT FINAL)
    Q_PROPERTY(SvgImage chat MEMBER sChat CONSTANT FINAL)
    Q_PROPERTY(SvgImage check MEMBER sCheck CONSTANT FINAL)
    Q_PROPERTY(SvgImage close MEMBER sClose CONSTANT FINAL)
    Q_PROPERTY(SvgImage copy MEMBER sContentCopy CONSTANT FINAL)
    Q_PROPERTY(SvgImage delete MEMBER sDelete CONSTANT FINAL)
    Q_PROPERTY(SvgImage edit MEMBER sEdit CONSTANT FINAL)
    Q_PROPERTY(SvgImage group MEMBER sGroup CONSTANT FINAL)
    Q_PROPERTY(SvgImage hideVisibility MEMBER sVisibilityOff CONSTANT FINAL)
    Q_PROPERTY(SvgImage home MEMBER sHome CONSTANT FINAL)
    Q_PROPERTY(SvgImage info MEMBER sInfo CONSTANT FINAL)
    Q_PROPERTY(SvgImage inviteCode MEMBER sPin CONSTANT FINAL)
    Q_PROPERTY(SvgImage like MEMBER sFavorite CONSTANT FINAL)
    Q_PROPERTY(SvgImage moderation MEMBER sVerifiedUser CONSTANT FINAL)
    Q_PROPERTY(SvgImage moreVert MEMBER sMoreVert CONSTANT FINAL)
    Q_PROPERTY(SvgImage mute MEMBER sDoNotDisturbOn CONSTANT FINAL)
    Q_PROPERTY(SvgImage mutedWords MEMBER sSpeakerNotesOff CONSTANT FINAL)
    Q_PROPERTY(SvgImage noPosts MEMBER sSpeakerNotesOff CONSTANT FINAL)
    Q_PROPERTY(SvgImage notifications MEMBER sNotifications CONSTANT FINAL)
    Q_PROPERTY(SvgImage noUsers MEMBER sPersonOff CONSTANT FINAL)
    Q_PROPERTY(SvgImage reply MEMBER sReply CONSTANT FINAL)
    Q_PROPERTY(SvgImage report MEMBER sReport CONSTANT FINAL)
    Q_PROPERTY(SvgImage repost MEMBER sRepeat CONSTANT FINAL)
    Q_PROPERTY(SvgImage search MEMBER sSearch CONSTANT FINAL)
    Q_PROPERTY(SvgImage settings MEMBER sSettings CONSTANT FINAL)
    Q_PROPERTY(SvgImage share MEMBER sShare CONSTANT FINAL)
    Q_PROPERTY(SvgImage signOut MEMBER sLogout CONSTANT FINAL)
    Q_PROPERTY(SvgImage unblock MEMBER sCircle CONSTANT FINAL)
    Q_PROPERTY(SvgImage unmute MEMBER sDoNotDisturbOff CONSTANT FINAL)
    Q_PROPERTY(SvgImage user MEMBER sPerson CONSTANT FINAL)
    Q_PROPERTY(SvgImage visibility MEMBER sVisibility CONSTANT FINAL)
    QML_ELEMENT

public:
    explicit SvgOutline(QObject* parent = nullptr) : QObject(parent) {}

private:
    // fonts.google.com weight=100, grade=0, optical size=24px
    static constexpr SvgImage sAdd{"M466-466H252v-28h214v-214h28v214h214v28H494v214h-28v-214Z"};
    static constexpr SvgImage sAddPhotoAlternate{"M212-172q-24.75 0-42.375-17.625T152-232v-496q0-24.75 17.625-42.375T212-788h328v28H212q-14 0-23 9t-9 23v496q0 14 9 23t23 9h496q14 0 23-9t9-23v-328h28v328q0 24.75-17.625 42.375T708-172H212Zm488-468v-80h-80v-28h80v-80h28v80h80v28h-80v80h-28ZM298-306h332L528-442 428-318l-64-74-66 86ZM180-760v560-560Z"};
    static constexpr SvgImage sAlternateEmail{"M480-132q-72 0-135.558-27.391-63.559-27.392-110.575-74.348-47.015-46.957-74.441-110.435Q132-407.652 132-479.826q0-72.174 27.391-135.732 27.392-63.559 74.348-110.574 46.957-47.016 110.435-74.442Q407.652-828 479.826-828q72.174 0 135.732 27.405 63.559 27.405 110.574 74.385 47.016 46.98 74.442 110.49Q828-552.21 828-480v34q0 48-32.979 81-32.978 33-81.021 33-36 0-65-21t-41-55q-21 34-54.5 55T480-332q-62 0-105-43t-43-105q0-62 43-105t105-43q62 0 105 43t43 105v34q0 35 25.5 60.5T714-360q35 0 60.5-25.5T800-446v-34q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93h200v28H480Zm0-228q50 0 85-35t35-85q0-50-35-85t-85-35q-50 0-85 35t-35 85q0 50 35 85t85 35Z"};
    static constexpr SvgImage sArrowBack{"m266-466 234 234-20 20-268-268 268-268 20 20-234 234h482v28H266Z"};
    static constexpr SvgImage sBlock{"M480.174-132Q408-132 344.442-159.391q-63.559-27.392-110.575-74.348-47.015-46.957-74.441-110.435Q132-407.652 132-479.826q0-72.174 27.391-135.732 27.392-63.559 74.348-110.574 46.957-47.016 110.435-74.442Q407.652-828 479.826-828q72.174 0 135.732 27.391 63.559 27.392 110.574 74.348 47.016 46.957 74.442 110.435Q828-552.348 828-480.174q0 72.174-27.391 135.732-27.392 63.559-74.348 110.575-46.957 47.015-110.435 74.441Q552.348-132 480.174-132ZM480-160q59.961 0 115.481-21.5Q651-203 696-244L244-696q-40 45-62 100.519-22 55.52-22 115.481 0 134 93 227t227 93Zm236-104q41-45 62.5-100.519Q800-420.039 800-480q0-134-93-227t-227-93q-60.312 0-116.156 21Q308-758 264-716l452 452Z"};
    static constexpr SvgImage sBookmark{"M252-198v-530q0-26 17-43t43-17h336q26 0 43 17t17 43v530l-228-98-228 98Zm28-44 200-86 200 86v-486q0-12-10-22t-22-10H312q-12 0-22 10t-10 22v486Zm0-518h400-400Z"};
    static constexpr SvgImage sChat{"M266-426h268v-28H266v28Zm0-120h428v-28H266v28Zm0-120h428v-28H266v28ZM132-180v-588q0-26 17-43t43-17h576q26 0 43 17t17 43v416q0 26-17 43t-43 17H244L132-180Zm100-140h536q12 0 22-10t10-22v-416q0-12-10-22t-22-10H192q-12 0-22 10t-10 22v520l72-72Zm-72 0v-480 480Z"};
    static constexpr SvgImage sCheck{"M382-276 192-466l20-20 170 170 366-366 20 20-386 386Z"};
    static constexpr SvgImage sCircle{"M480.174-132Q408-132 344.442-159.391q-63.559-27.392-110.575-74.348-47.015-46.957-74.441-110.435Q132-407.652 132-479.826q0-72.174 27.391-135.732 27.392-63.559 74.348-110.574 46.957-47.016 110.435-74.442Q407.652-828 479.826-828q72.174 0 135.732 27.391 63.559 27.392 110.574 74.348 47.016 46.957 74.442 110.435Q828-552.348 828-480.174q0 72.174-27.391 135.732-27.392 63.559-74.348 110.575-46.957 47.015-110.435 74.441Q552.348-132 480.174-132ZM480-160q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z"};
    static constexpr SvgImage sClose{"m256-236-20-20 224-224-224-224 20-20 224 224 224-224 20 20-224 224 224 224-20 20-224-224-224 224Z"};
    static constexpr SvgImage sContentCopy{"M366-292q-26 0-43-17t-17-43v-416q0-26 17-43t43-17h296q26 0 43 17t17 43v416q0 26-17 43t-43 17H366Zm0-28h296q12 0 22-10t10-22v-416q0-12-10-22t-22-10H366q-12 0-22 10t-10 22v416q0 12 10 22t22 10ZM258-184q-26 0-43-17t-17-43v-444h28v444q0 12 10 22t22 10h324v28H258Zm76-136v-480 480Z"};
    static constexpr SvgImage sDelete{"M312-172q-25 0-42.5-17.5T252-232v-488h-40v-28h148v-28h240v28h148v28h-40v488q0 26-17 43t-43 17H312Zm368-548H280v488q0 14 9 23t23 9h336q12 0 22-10t10-22v-488ZM402-280h28v-360h-28v360Zm128 0h28v-360h-28v360ZM280-720v520-520Z"};
    static constexpr SvgImage sDoNotDisturbOff{"m606-466-28-28h76v28h-48Zm188 340-89-89q-46 39-103 61t-122 22q-72.21 0-135.72-27.405-63.51-27.405-110.49-74.385-46.98-46.98-74.385-110.49Q132-407.79 132-480q0-65 22-122t61-103l-89-89 20-20 668 668-20 20Zm-18-170-21-21q22-36 33.5-77t11.5-86q0-133-93.5-226.5T480-800q-45 0-86 11.5T317-755l-21-21q40.731-25.212 86.866-38.606Q429-828 480-828q72.21 0 135.72 27.405 63.51 27.405 110.49 74.385 46.98 46.98 74.385 110.49Q828-552.21 828-480q0 51-13.394 97.134Q801.212-336.731 776-296Zm-91 61L454-466H306v-28h120L235-685q-35 42-55 94t-20 111q0 133 93.5 226.5T480-160q59 0 111-20t94-55ZM578-494Zm-118 34Z"};
    static constexpr SvgImage sDoNotDisturbOn{"M306-466h348v-28H306v28Zm174.174 334Q408-132 344.442-159.391q-63.559-27.392-110.575-74.348-47.015-46.957-74.441-110.435Q132-407.652 132-479.826q0-72.174 27.391-135.732 27.392-63.559 74.348-110.574 46.957-47.016 110.435-74.442Q407.652-828 479.826-828q72.174 0 135.732 27.391 63.559 27.392 110.574 74.348 47.016 46.957 74.442 110.435Q828-552.348 828-480.174q0 72.174-27.391 135.732-27.392 63.559-74.348 110.575-46.957 47.015-110.435 74.441Q552.348-132 480.174-132ZM480-160q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z"};
    static constexpr SvgImage sEdit{"M200-200h40l439-439-40-40-439 439v40Zm-28 28v-80l527-528q4.39-3.826 9.695-5.913Q714-788 719.677-788q5.678 0 11 1.5Q736-785 741-780l39 39q5 5 6.5 10.41t1.5 10.819q0 5.771-1.913 11.076Q784.174-703.39 780-699L252-172h-80Zm589-548-41-41 41 41Zm-102.351 61.351L639-679l40 40-20.351-19.649Z"};
    static constexpr SvgImage sFavorite{"m480-190-22-20q-97-89-160.5-152t-100-110.5Q161-520 146.5-558T132-634q0-71 48.5-119.5T300-802q53 0 99 28.5t81 83.5q35-55 81-83.5t99-28.5q71 0 119.5 48.5T828-634q0 38-14.5 76t-51 85.5Q726-425 663-362T502-210l-22 20Zm0-38q96-87 158-149t98-107.5q36-45.5 50-80.5t14-69q0-60-40-100t-100-40q-48 0-88.5 27.5T494-660h-28q-38-60-78-87t-88-27q-59 0-99.5 40T160-634q0 34 14 69t50 80.5q36 45.5 98 107T480-228Zm0-273Z"};
    static constexpr SvgImage sGroup{"M123-232v-52q0-26 13.5-43.5t36.445-28.587Q222-379 269.5-393.5 317-408 391-408t121.5 14.5q47.5 14.5 96.555 37.413Q632-345 645.5-327.5T659-284v52H123Zm616 0v-52q0-32-10.947-59.982T697-392q23 6 45 15.5t45 20.5q23 11 36.5 30.16Q837-306.679 837-284v52h-98ZM391-512q-44.55 0-76.275-31.725Q283-575.45 283-620q0-44.55 31.725-76.275Q346.45-728 391-728q44.55 0 76.275 31.725Q499-664.55 499-620q0 44.55-31.725 76.275Q435.55-512 391-512Zm258-108q0 44.55-31.725 76.275Q585.55-512 541-512q18.321-22.763 28.161-50.505Q579-590.247 579-620.124 579-650 568.5-677 558-704 541-728q44.55 0 76.275 31.725Q649-664.55 649-620ZM151-260h480v-24q0-15-7.5-26T595-332q-42-23-90-35.5T391-380q-66 0-114 12.5T187-332q-21 11-28.5 22t-7.5 26v24Zm240-280q33 0 56.5-23.5T471-620q0-33-23.5-56.5T391-700q-33 0-56.5 23.5T311-620q0 33 23.5 56.5T391-540Zm0 280Zm0-360Z"};
    static constexpr SvgImage sHome{"M240-200h156v-234h168v234h156v-360L480-742 240-560v360Zm-28 28v-402l268-203 268 203v402H536v-234H424v234H212Zm268-299Z"};
    static constexpr SvgImage sInfo{"M466-306h28v-214h-28v214Zm14-264q8.5 0 14.25-5.75T500-590q0-8.5-5.75-14.25T480-610q-8.5 0-14.25 5.75T460-590q0 8.5 5.75 14.25T480-570Zm.174 438Q408-132 344.442-159.391q-63.559-27.392-110.575-74.348-47.015-46.957-74.441-110.435Q132-407.652 132-479.826q0-72.174 27.391-135.732 27.392-63.559 74.348-110.574 46.957-47.016 110.435-74.442Q407.652-828 479.826-828q72.174 0 135.732 27.391 63.559 27.392 110.574 74.348 47.016 46.957 74.442 110.435Q828-552.348 828-480.174q0 72.174-27.391 135.732-27.392 63.559-74.348 110.575-46.957 47.015-110.435 74.441Q552.348-132 480.174-132ZM480-160q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z"};
    static constexpr SvgImage sLogout{"M232-172q-26 0-43-17t-17-43v-496q0-26 17-43t43-17h249v28H232q-12 0-22 10t-10 22v496q0 12 10 22t22 10h249v28H232Zm432-184-20-20 90-90H370v-28h364l-90-90 20-20 124 124-124 124Z"};
    static constexpr SvgImage sMoreVert{"M480-236q-11.55 0-19.775-8.225Q452-252.45 452-264q0-11.55 8.225-19.775Q468.45-292 480-292q11.55 0 19.775 8.225Q508-275.55 508-264q0 11.55-8.225 19.775Q491.55-236 480-236Zm0-216q-11.55 0-19.775-8.225Q452-468.45 452-480q0-11.55 8.225-19.775Q468.45-508 480-508q11.55 0 19.775 8.225Q508-491.55 508-480q0 11.55-8.225 19.775Q491.55-452 480-452Zm0-216q-11.55 0-19.775-8.225Q452-684.45 452-696q0-11.55 8.225-19.775Q468.45-724 480-724q11.55 0 19.775 8.225Q508-707.55 508-696q0 11.55-8.225 19.775Q491.55-668 480-668Z"};
    static constexpr SvgImage sNotifications{"M212-212v-28h60v-328q0-77 49.5-135T446-774v-20q0-14.167 9.882-24.083 9.883-9.917 24-9.917Q494-828 504-818.083q10 9.916 10 24.083v20q75 13 124.5 71T688-568v328h60v28H212Zm268-282Zm-.177 382Q455-112 437.5-129.625T420-172h120q0 25-17.677 42.5t-42.5 17.5ZM300-240h360v-328q0-75-52.5-127.5T480-748q-75 0-127.5 52.5T300-568v328Z"};
    static constexpr SvgImage sPerson{"M480-512q-44.55 0-76.275-31.725Q372-575.45 372-620q0-44.55 31.725-76.275Q435.45-728 480-728q44.55 0 76.275 31.725Q588-664.55 588-620q0 44.55-31.725 76.275Q524.55-512 480-512ZM212-232v-52q0-22 13.5-41.5T262-356q55-26 109.5-39T480-408q54 0 108.5 13T698-356q23 11 36.5 30.5T748-284v52H212Zm28-28h480v-24q0-14-9.5-26.5T684-332q-48-23-99.687-35.5Q532.627-380 480-380q-52.626 0-104.313 12.5Q324-355 276-332q-17 9-26.5 21.5T240-284v24Zm240-280q33 0 56.5-23.5T560-620q0-33-23.5-56.5T480-700q-33 0-56.5 23.5T400-620q0 33 23.5 56.5T480-540Zm0-80Zm0 360Z"};
    static constexpr SvgImage sPersonOff{"M794-126 688-232H212v-52q0-22 13.5-41.5T262-356q55-26 109.5-39T480-408h16.5q8.5 0 16.5 1L126-794l20-20 668 668-20 20ZM240-260h420L545-375q-17-2-32.5-3.5T480-380q-53 0-104.5 12.5T276-332q-17 9-26.5 21.5T240-284v24Zm480-85ZM541-531l-20-20q18-11 28.5-29.5T560-620q0-33-23.5-56.5T480-700q-21 0-39.5 10.5T411-661l-20-20q15-23 38.5-35t50.5-12q45 0 76.5 31.5T588-620q0 27-12 50.5T541-531Zm119 271H240h420ZM466-606Z"};
    static constexpr SvgImage sPin{"M192-212q-26 0-43-17t-17-43v-416q0-26 17-43t43-17h576q26 0 43 17t17 43v416q0 26-17 43t-43 17H192Zm76-154h28v-228h-24l-64 46 16 22 44-30v190Zm122 0h144v-28H432v-4q17-15 32-30.5t32-33.5q16-17 23-33.5t7-36.5q0-27-19-44.5T458-594q-21 0-40 12t-28 32l28 12q6-13 17-20.5t23-7.5q18 0 29 9.5t11 26.5q0 13-5 22.5T474-482q-23 26-41.5 43.5T390-398v32Zm290 0q31 0 50.5-18.5T750-432q0-23-11.5-36.5T706-486v-2q18-3 27-14.5t9-31.5q0-27-17.5-43.5T678-594q-29 0-43.5 14.5T612-554l26 12q5-11 16-17.5t24-6.5q16 0 26 9t10 23q0 16-12 26t-30 10h-12v28h14q23 0 35.5 9.5T722-434q0 16-12.5 28T680-394q-17 0-28.5-7.5T632-426l-26 10q9 23 28.5 36.5T680-366ZM192-240h576q14 0 23-9t9-23v-416q0-14-9-23t-23-9H192q-14 0-23 9t-9 23v416q0 14 9 23t23 9Zm-32 0v-480 480Z"};
    static constexpr SvgImage sRepeat{"M290-126 166-250l124-124 20 20-90 90h476v-160h28v188H220l90 90-20 20Zm-54-410v-188h504l-90-90 20-20 124 124-124 124-20-20 90-90H264v160h-28Z"};
    static constexpr SvgImage sReply{"M760-252v-108q0-60-43-103t-103-43H226l170 170-20 20-204-204 204-204 20 20-170 170h388q72 0 123 51t51 123v108h-28Z"};
    static constexpr SvgImage sReport{"M480-310q8.5 0 14.25-5.75T500-330q0-8.5-5.75-14.25T480-350q-8.5 0-14.25 5.75T460-330q0 8.5 5.75 14.25T480-310Zm-14-106h28v-244h-28v244ZM352-172 172-351.529V-608l179.529-180H608l180 179.529V-352L608.471-172H352Zm12-28h232l164-164v-232L596-760H364L200-596v232l164 164Zm116-280Z"};
    static constexpr SvgImage sSearch{"M778-164 528-414q-30 26-69 40t-77 14q-92.231 0-156.115-63.837Q162-487.675 162-579.837 162-672 225.837-736q63.838-64 156-64Q474-800 538-736.115 602-672.231 602-580q0 41-15 80t-39 66l250 250-20 20ZM382-388q81 0 136.5-55.5T574-580q0-81-55.5-136.5T382-772q-81 0-136.5 55.5T190-580q0 81 55.5 136.5T382-388Z"};
    static constexpr SvgImage sSettings{"m416-132-14-112q-21-6-46.5-20T313-294l-103 44-64-112 89-67q-2-12-3.5-25t-1.5-25q0-11 1.5-23.5T235-531l-89-67 64-110 102 43q20-17 43.5-30.5T401-716l15-112h128l14 113q26 9 45.5 20.5T644-665l106-43 64 110-93 70q4 14 4.5 25.5t.5 22.5q0 10-1 21.5t-4 28.5l91 68-64 112-104-45q-21 18-42 30.5T558-245l-14 113H416Zm24-28h78l15-109q30-8 53.5-21.5T636-329l100 43 40-68-88-66q5-18 6.5-32t1.5-28q0-15-1.5-28t-6.5-30l90-68-40-68-103 43q-17-19-47.5-37T532-691l-12-109h-80l-12 108q-30 6-55 20t-51 40l-100-42-40 68 87 65q-5 13-7 29t-2 33q0 15 2 30t6 29l-86 66 40 68 99-42q24 24 49 38t57 22l13 108Zm38-232q37 0 62.5-25.5T566-480q0-37-25.5-62.5T478-568q-37 0-62.5 25.5T390-480q0 37 25.5 62.5T478-392Zm2-88Z"};
    static constexpr SvgImage sShare{"M720.118-106Q681-106 653.5-133.417 626-160.833 626-200q0-8.273 1.5-17.136Q629-226 632-234L314-422q-14 17-33 26.5t-41 9.5q-39.167 0-66.583-27.382Q146-440.765 146-479.882 146-519 173.417-546.5 200.833-574 240-574q22 0 41 9.5t33 26.5l318-188q-3-8-4.5-16.864Q626-751.727 626-760q0-39.167 27.382-66.583Q680.765-854 719.882-854 759-854 786.5-826.618q27.5 27.383 27.5 66.5Q814-721 786.583-693.5 759.167-666 720-666q-22 0-41-9.5T646-702L328-514q3 8 4.5 16.793t1.5 17Q334-472 332.5-463t-4.5 17l318 188q14-17 33-26.5t41-9.5q39.167 0 66.583 27.382Q814-239.235 814-200.118 814-161 786.618-133.5q-27.383 27.5-66.5 27.5ZM720-694q27 0 46.5-19.5T786-760q0-27-19.5-46.5T720-826q-27 0-46.5 19.5T654-760q0 27 19.5 46.5T720-694ZM240-414q27 0 46.5-19.5T306-480q0-27-19.5-46.5T240-546q-27 0-46.5 19.5T174-480q0 27 19.5 46.5T240-414Zm480 280q27 0 46.5-19.5T786-200q0-27-19.5-46.5T720-266q-27 0-46.5 19.5T654-200q0 27 19.5 46.5T720-134Zm0-626ZM240-480Zm480 280Z"};
    static constexpr SvgImage sSpeakerNotesOff{"M288-412q-11 0-19.5-8t-8.5-20q0-12 8.5-20t19.5-8q11 0 19.5 8t8.5 20q0 12-8.5 20t-19.5 8Zm488 120-22-28h14q14 0 23-9t9-23v-416q0-14-9-23t-23-9H274l-28-28h522q26 0 43 17t17 43v416q0 26-14.5 40.5T776-292ZM528-546l-28-28h194v28H528Zm280 434L628-292H244L132-180v-608l-88-88 20-20 764 764-20 20ZM380-540Zm134-20Zm-226 28q-11 0-19.5-8t-8.5-20q0-12 8.5-20t19.5-8q11 0 19.5 8t8.5 20q0 12-8.5 20t-19.5 8Zm120-134-11-11v-17h297v28H408Zm-248-94v512l72-72h368L160-760Z"};
    static constexpr SvgImage sVerifiedUser{"m438-374 190-190-20-20-170 170-86-86-20 20 106 106Zm42 240q-115-36-191.5-142T212-516v-208l268-100 268 100v208q0 134-76.5 240T480-134Zm0-30q104-33 172-132t68-220v-189l-240-89-240 89v189q0 121 68 220t172 132Zm0-315Z"};
    static constexpr SvgImage sVisibility{"M480.235-364Q537-364 576.5-403.735q39.5-39.736 39.5-96.5Q616-557 576.265-596.5q-39.736-39.5-96.5-39.5Q423-636 383.5-596.265q-39.5 39.736-39.5 96.5Q344-443 383.735-403.5q39.736 39.5 96.5 39.5ZM480-392q-45 0-76.5-31.5T372-500q0-45 31.5-76.5T480-608q45 0 76.5 31.5T588-500q0 45-31.5 76.5T480-392Zm.143 140Q355-252 252-319.5T96-500q53-113 155.857-180.5t228-67.5Q605-748 708-680.5T864-500q-53 113-155.857 180.5t-228 67.5ZM480-500Zm0 220q113 0 207.5-59.5T832-500q-50-101-144.5-160.5T480-720q-113 0-207.5 59.5T128-500q50 101 144.5 160.5T480-280Z"};
    static constexpr SvgImage sVisibilityOff{"m610-462-24-24q9-54-30.5-91.5T466-606l-24-24q8-3 17-4.5t21-1.5q57 0 96.5 39.5T616-500q0 12-1.5 22t-4.5 16Zm126 122-22-18q38-29 67.5-63.5T832-500q-50-101-143.5-160.5T480-720q-29 0-57 4t-55 12l-22-22q33-12 67-17t67-5q124 0 229 68t155 180q-21 45-52.5 85T736-340Zm52 208L636-284q-24 12-64.5 22T480-252q-125 0-229-68T96-500q24-53 64-99.5t84-76.5L132-788l20-20 656 656-20 20ZM264-656q-36 24-75.5 66.5T128-500q50 101 143.5 160.5T480-280q39 0 79-8t57-16l-74-74q-9 6-28 10t-34 4q-57 0-96.5-39.5T344-500q0-14 4-32.5t10-29.5l-94-94Zm277 125Zm-101 51Z"};
};

}
