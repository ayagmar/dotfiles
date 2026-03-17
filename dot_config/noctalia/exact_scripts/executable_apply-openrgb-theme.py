#!/usr/bin/env python3

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


def config_path(*parts: str) -> str:
    base = os.environ.get("XDG_CONFIG_HOME", os.path.join(os.environ["HOME"], ".config"))
    return os.path.join(base, *parts)


def read_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def read_accent_color() -> RGBColor:
    colors = read_json(config_path("noctalia", "colors.json"))
    accent = str(colors.get("mSecondary") or colors.get("mPrimary") or "#a9aefe")
    return RGBColor.fromHEX(accent)


def start_server() -> None:
    subprocess.run(
        ["systemctl", "--user", "start", "openrgb-server.service"],
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
    return devices[0] if devices else None


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
    set_mode(device, "Direct")
    device.set_color(color)
    time.sleep(0.15)


def apply_motherboard(device, color: RGBColor) -> None:
    set_mode(device, "Direct", "Static")

    try:
        device.set_color(color)
        time.sleep(0.15)
    except Exception:  # noqa: BLE001
        pass

    for zone in getattr(device, "zones", []):
        try:
            if len(getattr(zone, "leds", [])) == 0:
                zone.resize(1)
                time.sleep(0.15)
            zone.set_color(color)
            time.sleep(0.1)
        except Exception:  # noqa: BLE001
            continue


def apply_gpu(device, color: RGBColor) -> None:
    set_mode(device, "Direct", "Static")
    device.set_color(color)
    time.sleep(0.15)


def apply_with_client(device_type: DeviceType, pattern: str, apply_fn, color: RGBColor) -> None:
    client = connect_client()
    try:
        device = find_first_by_type(client, device_type, pattern)
        if device is not None:
            apply_fn(device, color)
            time.sleep(0.2)
    finally:
        client.disconnect()


def apply_gpu_with_retry(color: RGBColor) -> None:
    last_error = None
    for _ in range(2):
        client = connect_client()
        try:
            gpu = find_first_by_type(client, DeviceType.GPU, r"5090|waterforce|gigabyte")
            if gpu is None:
                gpu = find_first_by_name(client, r"5090|waterforce|gigabyte")
            if gpu is None:
                return
            apply_gpu(gpu, color)
            time.sleep(0.2)
            return
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            time.sleep(0.3)
        finally:
            client.disconnect()

    raise RuntimeError("failed to apply GPU color via OpenRGB SDK") from last_error


def main() -> int:
    colors_file = config_path("noctalia", "colors.json")
    if not os.path.exists(colors_file):
        return 0

    color = read_accent_color()
    apply_with_client(DeviceType.KEYBOARD, r"apex pro", apply_keyboard, color)
    apply_with_client(DeviceType.MOTHERBOARD, r"msi mystic light|x870|msi", apply_motherboard, color)
    apply_gpu_with_retry(color)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
