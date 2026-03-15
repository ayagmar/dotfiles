import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property bool connected: obsRunning && websocket

  property bool allowAttach: true
  property real contentPreferredWidth: Math.round(372 * Style.uiScaleRatio)
  property real contentPreferredHeight: content.implicitHeight + (Style.margin2L * 2)

  Item {
    id: panelContainer
    anchors.fill: parent

    ColumnLayout {
      id: content
      x: Style.marginL
      y: Style.marginL
      width: parent.width - (Style.margin2L)
      spacing: Style.marginL

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "video"
          pointSize: Style.fontSizeXXL
          color: recording ? Color.mError : (replayBuffer ? Color.mSecondary : Color.mPrimary)
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS

          NText {
            text: "OBS Control"
            pointSize: Style.fontSizeXL
            font.weight: Style.fontWeightSemiBold
            color: Color.mPrimary
          }

          NText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: {
              if (recording) {
                return "Recording is running. Save replays or stop the capture from here.";
              }
              if (replayBuffer) {
                return "Replay buffer is active. You can save the latest replay at any time.";
              }
              if (connected) {
                return "OBS is connected and ready for recording or replay.";
              }
              if (obsRunning) {
                return "OBS is open, but websocket control is unavailable until it is restarted once.";
              }
              return "OBS is offline. Launch it here and the widget will track its state.";
            }
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        implicitHeight: statusColumn.implicitHeight + (Style.marginXL)

        ColumnLayout {
          id: statusColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginXS

          NText {
            Layout.fillWidth: true
            text: "Status: " + (recording ? "Recording" : (replayBuffer ? "Replay Buffer" : (connected ? "Ready" : (obsRunning ? "Needs OBS Restart" : "Offline"))))
            font.weight: Style.fontWeightSemiBold
            color: recording ? Color.mError : (replayBuffer ? Color.mSecondary : Color.mOnSurface)
          }

          NText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Color.mOnSurfaceVariant
            text: websocket
                  ? "Bar widget appears while recording. Left click opens this panel, right click toggles recording, middle click toggles replay."
                  : "Websocket control is unavailable right now. Launch or restart OBS to restore quick actions."
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Style.marginM
        rowSpacing: Style.marginM

        NButton {
          Layout.fillWidth: true
          icon: obsRunning ? "refresh" : "player-play"
          text: obsRunning ? "Refresh OBS" : "Launch OBS"
          enabled: !obsRunning || !websocket
          onClicked: {
            if (!service) {
              return;
            }
            if (obsRunning) {
              service.refresh();
            } else {
              service.launchObs();
            }
          }
        }

        NButton {
          Layout.fillWidth: true
          icon: "player-record"
          text: recording ? "Stop Recording" : "Start Recording"
          enabled: connected
          backgroundColor: recording ? Color.mError : Color.mPrimary
          textColor: recording ? Color.mOnError : Color.mOnPrimary
          onClicked: service && service.toggleRecord()
        }

        NButton {
          Layout.fillWidth: true
          icon: "history"
          text: replayBuffer ? "Stop Replay" : "Start Replay"
          enabled: connected
          backgroundColor: replayBuffer ? Color.mSecondary : Color.mSurfaceVariant
          textColor: replayBuffer ? Color.mOnSecondary : Color.mOnSurface
          onClicked: service && service.toggleReplay()
        }

        NButton {
          Layout.fillWidth: true
          icon: "device-floppy"
          text: "Save Replay"
          enabled: replayBuffer
          outlined: !replayBuffer
          onClicked: service && service.saveReplay()
        }
      }

      NButton {
        Layout.fillWidth: true
        icon: "refresh"
        text: "Refresh Status"
        outlined: true
        onClicked: service && service.refresh()
      }
    }
  }
}
