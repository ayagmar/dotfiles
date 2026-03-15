import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

NIconButtonHot {
  id: root

  property ShellScreen screen
  property var pluginApi

  readonly property var service: pluginApi ? pluginApi.mainInstance : null
  readonly property bool obsRunning: Boolean(service && service.obsRunning)
  readonly property bool websocket: Boolean(service && service.websocket)
  readonly property bool recording: Boolean(service && service.recording)
  readonly property bool replayBuffer: Boolean(service && service.replayBuffer)
  readonly property bool connected: obsRunning && websocket
  readonly property string obsLogoSource: "file:///usr/share/icons/hicolor/scalable/apps/com.obsproject.Studio.svg"

  icon: ""
  hot: recording || replayBuffer
  colorBgHot: recording ? Color.mError : Color.mSecondary
  colorFgHot: recording ? Color.mOnError : Color.mOnSecondary

  tooltipText: {
    if (recording) {
      return "OBS is recording\nLeft click opens controls\nRight click stops recording\nMiddle click toggles replay buffer";
    }
    if (replayBuffer) {
      return "OBS replay buffer is active\nLeft click opens controls\nRight click starts recording\nMiddle click stops replay buffer";
    }
    if (connected) {
      return "OBS is ready\nLeft click opens controls\nRight click starts recording\nMiddle click toggles replay buffer";
    }
    if (obsRunning) {
      return "OBS is running, but websocket control is unavailable\nRestart OBS once to re-enable controls";
    }
    return "OBS is offline\nLeft click opens controls\nRight click launches OBS";
  }

  NIcon {
    anchors.centerIn: parent
    visible: recording || replayBuffer
    icon: recording ? "player-record" : "history"
    pointSize: Math.max(1, Math.round(root.width * 0.48))
    color: {
      if ((root.enabled && root.hovering) || root.pressed) {
        return Color.mOnHover;
      }
      return recording ? Color.mOnError : Color.mOnSecondary;
    }
  }

  Image {
    anchors.centerIn: parent
    visible: !recording && !replayBuffer
    source: root.obsLogoSource
    sourceSize.width: Math.round(root.width * 0.56)
    sourceSize.height: Math.round(root.height * 0.56)
    width: Math.round(root.width * 0.56)
    height: Math.round(root.height * 0.56)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: true
    opacity: ((root.enabled && root.hovering) || root.pressed) ? 0.96 : 0.9
  }

  onClicked: {
    if (!service || !pluginApi || !screen) {
      return;
    }

    pluginApi.openPanel(screen, root);
  }

  onRightClicked: {
    if (!service) {
      return;
    }

    if (!obsRunning) {
      service.launchObs();
    } else if (connected) {
      service.toggleRecord();
    } else {
      service.refresh();
    }
  }

  onMiddleClicked: {
    if (service && connected) {
      service.toggleReplay();
    }
  }
}
