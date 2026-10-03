"""Check palette synchronization without connecting to RGB hardware."""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1]
SCRIPT = SOURCE / "dot_config/noctalia/exact_scripts/executable_apply-openrgb-theme.py"
SPEC = importlib.util.spec_from_file_location("rgb_theme", SCRIPT)
rgb = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(rgb)


class RGBThemeTests(unittest.TestCase):
    def read_color(self, palette):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp) / "noctalia"
            directory.mkdir()
            (directory / "colors.json").write_text(json.dumps(palette))
            with patch.dict(rgb.os.environ, {"XDG_CONFIG_HOME": tmp}):
                return rgb.read_accent_color()

    def test_primary_accent_wins_over_secondary(self):
        color = self.read_color({"mPrimary": "#123456", "mSecondary": "#ffffff"})
        self.assertEqual((color.red, color.green, color.blue), (18, 52, 86))

    def test_invalid_primary_is_rejected(self):
        for value in (None, 123, "#fff", "invalid", "#12345g"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.read_color({"mPrimary": value})

    def test_missing_primary_does_not_apply_a_hardcoded_color(self):
        with self.assertRaises(KeyError):
            self.read_color({"mSecondary": "#ffffff"})

    def test_brightness_boost_clamps_at_full_brightness(self):
        self.assertEqual(rgb.scale_channel(230, 1.5), 255)
        self.assertEqual(rgb.scale_channel(20, 1.5), 30)


if __name__ == "__main__":
    unittest.main()
