import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  required property var pluginApi

  visible: false
  width: 0
  height: 0

  readonly property string obsctlPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/niri/scripts/obsctl"

  property bool obsRunning: false
  property bool websocket: false
  property bool recording: false
  property bool replayBuffer: false
  readonly property bool connected: obsRunning && websocket

  function applyStatus(payload) {
    obsRunning = Boolean(payload && payload.obsRunning);
    websocket = Boolean(payload && payload.websocket);
    recording = Boolean(payload && payload.recording);
    replayBuffer = Boolean(payload && payload.replayBuffer);
  }

  function refresh() {
    if (!statusProcess.running) {
      statusProcess.running = true;
    }
  }

  function runAction(action) {
    Quickshell.execDetached([obsctlPath, action]);
    actionRefreshTimer.restart();
  }

  function launchObs() {
    runAction("launch");
  }

  function toggleRecord() {
    runAction("toggle-record");
  }

  function toggleReplay() {
    runAction("toggle-replay");
  }

  function saveReplay() {
    runAction("save-replay");
  }

  Component.onCompleted: refresh()

  Timer {
    id: pollTimer
    interval: 2500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    id: actionRefreshTimer
    interval: 900
    running: false
    repeat: false
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    running: false
    command: [root.obsctlPath, "status"]
    stdout: StdioCollector {}

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.applyStatus({
          "obsRunning": false,
          "websocket": false,
          "recording": false,
          "replayBuffer": false
        });
        return;
      }

      try {
        root.applyStatus(JSON.parse(String(stdout.text || "").trim() || "{}"));
      } catch (e) {
        root.applyStatus({
          "obsRunning": false,
          "websocket": false,
          "recording": false,
          "replayBuffer": false
        });
      }
    }
  }
}
