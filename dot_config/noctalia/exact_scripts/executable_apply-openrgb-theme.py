#!/usr/bin/env python3

import fcntl
import json
import os
import re
import subprocess
import sys
import time

from openrgb import OpenRGBClient
from openrgb.utils import DeviceType, RGBColor

HOST = "127.0.0.1"
PORT = 6742
CLIENT_NAME = "NoctaliaRGB"
RETRY_COUNT = 6
RETRY_DELAY_SECONDS = 1.0
LOCK_NAME = "noctalia-openrgb.lock"
ADDRESSABLE_MOTHERBOARD_ZONES = {
    "JARGB 1": 20,  # case strip / cage lighting
    "JARGB 2": 20,  # 3 bottom fans + rear fan
    "JARGB 3": 20,  # top radiator fans
}


def config_path(*parts: str) -> str:
    base = os.environ.get("XDG_CONFIG_HOME", os.path.join(os.environ["HOME"], ".config"))
    return os.path.join(base, *parts)


def lock_path() -> str:
    base = os.environ.get("XDG_RUNTIME_DIR") or config_path("noctalia")
    os.makedirs(base, exist_ok=True)
    return os.path.join(base, LOCK_NAME)


def acquire_lock() -> int:
    fd = os.open(lock_path(), os.O_CREAT | os.O_RDWR, 0o600)
    fcntl.flock(fd, fcntl.LOCK_EX)
    return fd


def read_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def read_accent_color() -> RGBColor:
    colors = read_json(config_path("noctalia", "colors.json"))
    accent = str(colors.get("mSecondary") or colors.get("mPrimary") or "#a9aefe")
    return RGBColor.fromHEX(accent)


def start_server() -> None:
    subprocess.run(
        ["systemctl", "--user", "start", "--no-block", "openrgb-server.service"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def connect_client() -> OpenRGBClient:
    last_error = None

    for attempt in range(RETRY_COUNT):
        try:
            return OpenRGBClient(HOST, PORT, CLIENT_NAME)
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            if attempt == 0:
                start_server()
            if attempt < RETRY_COUNT - 1:
                time.sleep(RETRY_DELAY_SECONDS)

    raise RuntimeError(f"failed to connect to OpenRGB SDK at {HOST}:{PORT}") from last_error


def find_first_by_type(client: OpenRGBClient, device_type: DeviceType, pattern: str | None = None):
    devices = client.get_devices_by_type(device_type)
    if pattern is None:
        return devices[0] if devices else None

    regex = re.compile(pattern, re.IGNORECASE)
    for device in devices:
        if regex.search(device.name):
            return device
    return None


def find_first_by_name(client: OpenRGBClient, pattern: str):
    regex = re.compile(pattern, re.IGNORECASE)
    for device in client.devices:
        if regex.search(device.name):
            return device
    return None


def set_mode(device, *modes: str) -> bool:
    for mode in modes:
        try:
            device.set_mode(mode)
            time.sleep(0.15)
            return True
        except Exception:  # noqa: BLE001
            continue
    return False


def apply_keyboard(device, color: RGBColor) -> None:
    if not set_mode(device, "Direct"):
        return
    device.set_color(color)
    time.sleep(0.15)


def addressable_motherboard_zone_size(zone) -> int | None:
    name = getattr(zone, "name", "")
    return ADDRESSABLE_MOTHERBOARD_ZONES.get(name)


def ensure_zone_size(zone, zone_size: int) -> None:
    if len(getattr(zone, "leds", [])) == zone_size:
        return

    zone.resize(zone_size)
    time.sleep(0.15)


def apply_motherboard(device, color: RGBColor) -> None:
    if not set_mode(device, "Direct", "Static"):
        return

    zones = getattr(device, "zones", [])
    if not zones:
        device.set_color(color)
        time.sleep(0.15)
        return

    for zone in zones:
        zone_size = addressable_motherboard_zone_size(zone)
        if zone_size is None:
            continue

        ensure_zone_size(zone, zone_size)
        zone.set_color(color)
        time.sleep(0.1)


def apply_gpu(device, color: RGBColor) -> None:
    if not set_mode(device, "Direct", "Static"):
        return
    device.set_color(color)
    time.sleep(0.15)


def main() -> int:
    colors_file = config_path("noctalia", "colors.json")
    if not os.path.exists(colors_file):
        return 0

    lock_fd = acquire_lock()
    try:
        color = read_accent_color()
        client = connect_client()
        try:
            keyboard = find_first_by_type(client, DeviceType.KEYBOARD, r"apex pro")
            if keyboard is not None:
                apply_keyboard(keyboard, color)

            motherboard = find_first_by_type(client, DeviceType.MOTHERBOARD, r"msi mystic light|x870|msi")
            if motherboard is not None:
                apply_motherboard(motherboard, color)

            gpu = find_first_by_type(client, DeviceType.GPU, r"5090|waterforce|gigabyte")
            if gpu is None:
                gpu = find_first_by_name(client, r"5090|waterforce|gigabyte")
            if gpu is not None:
                apply_gpu(gpu, color)
        finally:
            client.disconnect()
    finally:
        os.close(lock_fd)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
