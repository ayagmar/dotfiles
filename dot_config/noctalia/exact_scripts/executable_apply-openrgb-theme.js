#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const sdkRoot = process.argv[2] || path.join(process.env.HOME, ".config/noctalia/openrgb-sdk");
const { Client } = require(path.join(sdkRoot, "node_modules/openrgb-sdk"));

const configDir = path.join(process.env.XDG_CONFIG_HOME || path.join(process.env.HOME, ".config"), "noctalia");
const colorsPath = path.join(configDir, "colors.json");
const settingsPath = path.join(configDir, "settings.json");

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function hexToRgb(hex) {
  const value = String(hex || "").replace(/^#/, "").padStart(6, "0").slice(0, 6);
  return {
    red: parseInt(value.slice(0, 2), 16),
    green: parseInt(value.slice(2, 4), 16),
    blue: parseInt(value.slice(4, 6), 16),
  };
}

function colorFill(count, color) {
  return Array.from({ length: Math.max(1, count) }, () => ({ ...color }));
}

function findMode(device, name) {
  return (device.modes || []).find((mode) => mode.name.toLowerCase() === name.toLowerCase());
}

function findDevice(devices, pattern) {
  return devices.find((device) => pattern.test(device.name));
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function applyDirect(client, device, color) {
  const directMode = findMode(device, "Direct");
  if (directMode) {
    await client.updateMode(device.deviceId, { name: directMode.name });
  } else {
    client.setCustomMode(device.deviceId);
  }

  await sleep(100);

  if ((device.colors || []).length > 0) {
    client.updateLeds(device.deviceId, colorFill(device.colors.length, color));
    return;
  }

  for (let zoneId = 0; zoneId < (device.zones || []).length; zoneId += 1) {
    client.updateZoneLeds(device.deviceId, zoneId, [color]);
  }
}

async function main() {
  if (!fs.existsSync(colorsPath)) return;

  const colors = readJson(colorsPath);
  const accentColor = hexToRgb(colors.mSecondary || colors.mPrimary || "#a9aefe");

  const client = new Client("NoctaliaRGB", 6742, "127.0.0.1");
  client.on("error", (err) => {
    if (!err || err.code === "ECONNRESET" || err.code === "EPIPE") {
      return;
    }

    console.error(err.message || String(err));
  });

  await client.connect(4000);

  try {
    const devices = await client.getAllControllerData();

    const gpu = findDevice(devices, /5090|waterforce/i);
    const keyboard = findDevice(devices, /apex pro/i);
    const motherboard = findDevice(devices, /msi mystic light/i);

    if (gpu) await applyDirect(client, gpu, accentColor);
    if (keyboard) await applyDirect(client, keyboard, accentColor);
    if (motherboard) await applyDirect(client, motherboard, accentColor);

    await sleep(200);
  } finally {
    client.disconnect();
  }
}

main().catch((err) => {
  console.error(err && err.message ? err.message : String(err));
  process.exit(1);
});
