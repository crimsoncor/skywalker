import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import skywalker

Column {
    required property var videoView // videoView
    required property int contentVisibility // QEnums::ContentVisibility
    required property string contentWarning
    property string controlColor: guiSettings.textColor
    property string disabledColor: guiSettings.disabledColor
    property string backgroundColor: guiSettings.backgroundColor
    property int maxHeight: 0
    property bool isFullViewMode: false
    readonly property bool isPlaying: videoPlayer.playing || videoPlayer.restarting
    property var userSettings: root.getSkywalker().getUserSettings()
    property string videoSource

    id: videoStack
    spacing: isFullViewMode ? -playControls.height : 10

    Rectangle {
        width: parent.width
        height: videoColumn.height
        color: "transparent"
        visible: videoPlayer.videoFound || videoPlayer.error == MediaPlayer.NoError

        FilteredImageWarning {
            id: filter
            x: 10
            y: 10
            width: parent.width - 20
            contentVisibiliy: videoStack.contentVisibility
            contentWarning: videoStack.contentWarning
            imageUrl: videoView.thumbUrl
            isVideo: true
        }

        Column {
            id: videoColumn
            width: parent.width
            topPadding: 1
            spacing: 3

            Rectangle {
                width: parent.width
                height: filter.height > 0 ? filter.height + 20 : 0
                color: "transparent"
            }

            Rectangle {
                id: imgPreview
                width: parent.width
                height: defaultThumbImg.visible ? defaultThumbImg.height : thumbImg.height
                color: "transparent"

                ThumbImageView {
                    property double aspectRatio: height > 0 ? width / height : 0
                    property double maxWidth: maxHeight * aspectRatio

                    id: thumbImg
                    x: (parent.width - width) / 2
                    width: (maxWidth > 0 && parent.width - 2 > maxWidth) ? maxWidth : parent.width - 2
                    imageView: filter.imageVisible() ? videoView.imageView : filter.nullImage
                    fillMode: Image.PreserveAspectFit
                    enableAlt: !isFullViewMode
                }
                Rectangle {
                    property double maxWidth: maxHeight * videoStack.getAspectRatio()

                    id: defaultThumbImg
                    x: (parent.width - width) / 2
                    width: (maxWidth > 0 && parent.width - 2 > maxWidth) ? maxWidth : parent.width - 2
                    height: width / videoStack.getAspectRatio()
                    color: guiSettings.avatarDefaultColor
                    visible: videoView.imageView.isNull() || thumbImg.status != Image.Ready && filter.imageVisible()

                    onHeightChanged: {
                        if (maxHeight && height > maxHeight)
                            Qt.callLater(setMaxHeight)
                    }

                    function setMaxHeight() {
                        const ratio = width / height
                        //height = maxHeight
                        width = Math.floor(maxHeight * ratio)
                    }

                    SvgImage {
                        x: (parent.width - width) / 2
                        y: (parent.height - height) / 2 + height
                        width: Math.min(parent.width, 150)
                        height: width
                        color: "white"
                        svg: svgFilled.film
                    }
                }
            }
        }

        SvgButton {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: 50
            height: width
            opacity: 0.5
            accessibleName: qsTr("play video")
            svg: svgFilled.play
            visible: filter.imageVisible() && !videoPlayer.playing && !videoPlayer.restarting
            enabled: videoPlayer.hasVideo

            onClicked: videoPlayer.start()

            BusyIndicator {
                anchors.fill: parent
                running: parent.visible && !parent.enabled && (videoPlayer.error == MediaPlayer.NoError || videoPlayer.videoFound)
            }
        }

        Item {
            id: player
            width: parent.width
            height: parent.height

            MediaPlayer {
                property bool videoFound: false
                property bool restarting: false

                id: videoPlayer
                source: videoSource
                videoOutput: videoOutput
                audioOutput: audioOutput

                onHasVideoChanged: {
                    if (hasVideo)
                        videoFound = true
                }

                onPlayingChanged: {
                    if (videoPlayer.playing)
                        restartTimer.set(false)
                }

                onErrorOccurred: (error, errorString) => { console.debug("Video error:", source, error, errorString) }

                function playPause() {
                    if (playbackState == MediaPlayer.PausedState)
                        play()
                    else
                        pause()
                }

                function start() {
                    restartTimer.set(true)
                    play()
                }

                function restart() {
                    stopPlaying()
                    start()
                }

                function stopPlaying() {
                    stop()
                    restartTimer.set(false)
                }

                function isLoading() {
                    return [MediaPlayer.LoadingMedia,
                            MediaPlayer.BufferingMedia].includes(mediaStatus)
                }
            }
            VideoOutput {
                id: videoOutput
                anchors.fill: parent
            }
            AudioOutput {
                id: audioOutput
                muted: !userSettings.videoSound

                function toggleSound() {
                    userSettings.videoSound = !userSettings.videoSound
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: (videoPlayer.playing && videoPlayer.isLoading()) || videoPlayer.restarting
            }

            Timer {
                id: restartTimer
                interval: 5000
                onTriggered: {
                    videoPlayer.stop()
                    videoPlayer.restarting = false
                    console.warn("Failed to start video")
                }

                function set(on) {
                    videoPlayer.restarting = on

                    if (on)
                        start()
                    else
                        stop()
                }
            }
        }

        MouseArea {
            width: parent.width
            height: parent.height
            z: -1
            onClicked: {
                if (isFullViewMode)
                    playControls.show = !playControls.show
                else
                    root.viewFullVideo(videoView)
            }
        }

        RoundCornerMask {
            width: parent.width
            height: parent.height
            color: "transparent"
            maskColor: videoStack.backgroundColor
            visible: !isFullViewMode
        }
    }

    Rectangle {
        property bool show: true

        id: playControls
        x: (parent.width - width) / 2
        width: defaultThumbImg.visible ? defaultThumbImg.width : thumbImg.width
        height: playPauseButton.height
        color: "transparent"
        visible: show && (videoPlayer.playbackState == MediaPlayer.PlayingState || videoPlayer.playbackState == MediaPlayer.PausedState || videoPlayer.restarting)

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.3
            visible: isFullViewMode
        }

        SvgTransparentButton {
            id: playPauseButton
            x: isFullViewMode ? 10 : 0
            width: 32
            height: width
            svg: videoPlayer.playing ? svgFilled.pause : svgFilled.play
            accessibleName: videoPlayer.playing ? qsTr("pause video") : qsTr("continue playing video")
            color: controlColor

            onClicked: videoPlayer.playPause()
        }

        SvgTransparentButton {
            id: stopButton
            anchors.left: playPauseButton.right
            anchors.leftMargin: 10
            width: 32
            height: width
            svg: svgFilled.stop
            accessibleName: qsTr("stop video")
            color: controlColor

            onClicked: videoPlayer.stopPlaying()
        }

        SvgTransparentButton {
            id: replayButton
            anchors.left: stopButton.right
            anchors.leftMargin: 10
            width: 32
            height: width
            svg: svgOutline.refresh
            accessibleName: qsTr("restart video")
            color: controlColor

            onClicked: videoPlayer.restart()
        }

        ProgressBar {
            id: playProgress
            anchors.left: replayButton.right
            anchors.leftMargin: 10
            anchors.right: remainingTimeText.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            from: 0
            to: videoPlayer.duration
            value: videoPlayer.position

            background: Rectangle {
                implicitWidth: parent.width
                implicitHeight: 4
                color: disabledColor
            }

            contentItem: Item {
                implicitWidth: parent.width
                implicitHeight: 4

                Rectangle {
                    width: playProgress.visualPosition * parent.width
                    height: parent.height
                    color: controlColor
                }
            }
        }

        MouseArea {
            x: playProgress.x
            width: playProgress.width
            height: playControls.height
            onClicked: (event) => {
                videoPlayer.position = (videoPlayer.duration / width) * event.x
            }
        }

        AccessibleText {
            id: remainingTimeText
            anchors.right: soundButton.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: guiSettings.scaledFont(6/8)
            color: controlColor
            text: guiSettings.videoDurationToString(videoPlayer.duration - videoPlayer.position)
        }

        SvgTransparentButton {
            id: soundButton
            anchors.right: parent.right
            anchors.rightMargin: isFullViewMode ? 10 : 0
            width: 32
            height: width
            svg: audioOutput.muted ? svgOutline.soundOff : svgOutline.soundOn
            accessibleName: audioOutput.muted ? qsTr("turn sound on") : qsTr("turn sound off")
            color: controlColor

            onClicked: audioOutput.toggleSound()
        }
    }

    Rectangle {
        width: parent.width
        height: errorText.height
        radius: 10
        border.width: 1
        border.color: guiSettings.borderColor
        color: "transparent"
        visible: !videoPlayer.videoFound && videoPlayer.error != MediaPlayer.NoError

        AccessibleText {
            id: errorText
            padding: 10
            text: qsTr(`⚠️ Video error: ${videoPlayer.errorString}`)
        }
    }

    M3U8Reader {
        id: m3u8Reader

        onGetVideoStreamOk: (videoStream) => videoSource = videoStream
        onGetVideoStreamFailed: videoSource = videoView.playlistUrl
    }

    GuiSettings {
        id: guiSettings
    }

    function pause() {
        if (videoPlayer.playing)
            videoPlayer.pause()
    }

    function getAspectRatio() {
        if (videoView && videoView.width > 0 && videoView.height > 0)
            return videoView.width / videoView.height
        else
            return 16/9
    }

    Component.onCompleted: {
        if (videoView.playlistUrl.endsWith(".m3u8"))
            m3u8Reader.getVideoStream(videoView.playlistUrl)
        else
            videoSource = videoView.playlistUrl
    }
}
