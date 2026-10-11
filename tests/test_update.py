"""Exercise update with fake package managers in a filesystem/network sandbox."""

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1]
UPDATER = SOURCE / "dot_config/zsh/40-update.zsh"
NODE = shutil.which("node")

# The registry boundary supplies eligible releases or structured npm failures.
# No actual npm, mise, package registry, user files, or wall clock are used.
FAKE_MANAGER = r'''#!/usr/bin/python3
import fnmatch
import json
import sys
from pathlib import Path

state_path = Path("/case/state.json")
state = json.loads(state_path.read_text())
args = sys.argv[1:]
manager = Path(sys.argv[0]).name


def save():
    state_path.write_text(json.dumps(state))


def version_key(version):
    return tuple(int(part) for part in version.split("."))


if manager == "date":
    print("2026-10-03T18:04:04Z")
elif manager == "mise":
    if args[0] == "upgrade" and state.get("node_upgrade"):
        # Node's native default-packages install restores into a fresh prefix.
        restored = {}
        for spec in Path("/case/home/.default-npm-packages").read_text().splitlines():
            if "@" in spec[1:]:
                name, version = spec.rsplit("@", 1)
            else:
                name = spec
                version = max(
                    state["releases"][name], key=lambda r: version_key(r["version"])
                )["version"]
            restored[name] = version
        state["installed"] = restored
        state["node_upgraded"] = True
        save()
elif manager == "npm":
    if args[0] == "ls":
        if "--json" in args:
            dependencies = {
                name: {"version": version}
                for name, version in state["installed"].items()
            }
            dependencies.update(state.get("invalid_dependencies", {}))
            dependencies["npm"] = {"version": "11.19.0"}
            dependencies["corepack"] = {"version": "0.36.0"}
            print(json.dumps({"dependencies": dependencies}))
        else:
            print("/fake/node/lib/node_modules")
            for name in state["installed"]:
                print("/fake/node/lib/node_modules/" + name)
    elif args[0] == "install":
        spec = args[-1]
        if "@>=" in spec:
            name, floor = spec.rsplit("@>=", 1)
        else:
            name, floor = spec, "0.0.0"
        age = int(args[args.index("--min-release-age") + 1])
        allowlist = []
        if "--min-release-age-exclude" in args:
            allowlist = args[args.index("--min-release-age-exclude") + 1].split(",")
        exempt = any(fnmatch.fnmatchcase(name, pattern) for pattern in allowlist)
        aged = [
            release for release in state["releases"][name]
            if exempt or release["age_days"] >= age
        ]
        eligible = [
            release for release in aged
            if version_key(release["version"]) >= version_key(floor)
        ]
        code = state.get("install_errors", {}).get(name)
        if not code and not eligible:
            code = "ETARGET" if aged else "ENOVERSIONS"
        if code:
            print(json.dumps({"error": {"code": code, "summary": "No resolution"}}))
            print("npm error " + code, file=sys.stderr)
            sys.exit(1)
        version = max(eligible, key=lambda r: version_key(r["version"]))["version"]
        state["installed"][name] = version
        save()
        print(json.dumps({"changed": 1}))
    else:
        raise SystemExit("Unexpected npm command: " + repr(args))
else:
    raise SystemExit("Unexpected manager: " + manager)
'''


def release(version, age_days):
    return {"version": version, "age_days": age_days}


@unittest.skipUnless(
    shutil.which("bwrap") and shutil.which("zsh") and NODE,
    "requires bubblewrap, zsh, and Node to run without host-state access",
)
class UpdateTests(unittest.TestCase):
    def run_update(self, state):
        with tempfile.TemporaryDirectory() as tmp:
            case = Path(tmp)
            (case / "home").mkdir()
            (case / "bin").mkdir()
            (case / "state.json").write_text(json.dumps(state))
            (case / "home/.default-npm-packages").write_text(
                "\n".join(state["installed"])
            )
            manager = case / "manager"
            manager.write_text(FAKE_MANAGER)
            manager.chmod(0o755)
            for name in ("npm", "mise", "date"):
                (case / "bin" / name).symlink_to("/case/manager")
            (case / "bin/node").symlink_to("/node")
            for name in ("sed", "grep"):
                (case / "bin" / name).symlink_to("/usr/bin/" + name)
            result = subprocess.run(
                [
                    "/usr/bin/bwrap",
                    "--unshare-all",
                    "--die-with-parent",
                    "--ro-bind", "/usr", "/usr",
                    "--symlink", "usr/lib", "/lib",
                    "--symlink", "usr/lib64", "/lib64",
                    "--proc", "/proc",
                    "--dev", "/dev",
                    "--tmpfs", "/tmp",
                    "--tmpfs", "/var",
                    "--bind", str(case), "/case",
                    "--ro-bind", str(UPDATER), "/updater.zsh",
                    "--ro-bind", str(Path(NODE).resolve()), "/node",
                    "--chdir", "/case/home",
                    "--", "/usr/bin/zsh", "-f", "-c",
                    "source /updater.zsh; update --yes",
                ],
                env={
                    "PATH": "/case/bin",
                    "HOME": "/case/home",
                    "XDG_CONFIG_HOME": "/case/home/.config",
                    "LC_ALL": "C",
                    "TERM": "dumb",
                },
                capture_output=True,
                text=True,
                timeout=15,
            )
            self.assertNotIn("bwrap:", result.stderr, result.stderr)
            final_state = json.loads((case / "state.json").read_text())
            restore_path = case / "home/.default-npm-packages"
            restore_list = (
                restore_path.read_text().splitlines() if restore_path.exists() else []
            )
            return result, final_state, restore_list

    def test_owned_package_bypasses_cooldown_but_third_party_releases_wait(self):
        result, state, restore_list = self.run_update({
            "installed": {"llm-usage-metrics": "0.10.2", "third-party": "2.0.0"},
            "releases": {
                "llm-usage-metrics": [release("0.10.2", 1), release("0.10.3", 0)],
                "third-party": [release("2.1.0", 10), release("2.2.0", 1)],
            },
        })
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(state["installed"], {
            "llm-usage-metrics": "0.10.3", "third-party": "2.1.0",
        })
        self.assertCountEqual(restore_list, [
            "llm-usage-metrics@0.10.3", "third-party@2.1.0",
        ])

    def test_manually_updated_scoped_package_is_held_without_a_downgrade(self):
        for older_releases in ([release("2.0.0", 30)], []):
            with self.subTest(older_releases=older_releases):
                result, state, _ = self.run_update({
                    "installed": {"@scope/tool": "3.0.0"},
                    "releases": {
                        "@scope/tool": older_releases + [release("3.0.0", 1)],
                    },
                })
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(state["installed"]["@scope/tool"], "3.0.0")
                self.assertIn("Held @scope/tool@3.0.0", result.stdout)

    def test_node_upgrade_restores_manual_versions_before_attempting_updates(self):
        result, state, restore_list = self.run_update({
            "node_upgrade": True,
            "installed": {"third-party": "3.0.0"},
            "releases": {"third-party": [release("2.0.0", 30), release("3.0.0", 1)]},
        })
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(state["node_upgraded"])
        self.assertEqual(state["installed"]["third-party"], "3.0.0")
        self.assertEqual(restore_list, ["third-party@3.0.0"])

    def test_registry_failure_is_not_misreported_as_a_successful_hold(self):
        result, state, _ = self.run_update({
            "installed": {"third-party": "2.0.0"},
            "releases": {"third-party": [release("2.1.0", 30)]},
            "install_errors": {"third-party": "ENETUNREACH"},
        })
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(state["installed"]["third-party"], "2.0.0")
        self.assertIn("npm globals (third-party)", result.stdout)
        self.assertIn("ENETUNREACH", result.stderr)

    def test_missing_installed_version_stops_before_changing_node_or_restore_list(self):
        result, state, restore_list = self.run_update({
            "node_upgrade": True,
            "installed": {},
            "invalid_dependencies": {"broken-package": {}},
            "releases": {},
        })
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertNotIn("node_upgraded", state)
        self.assertEqual(restore_list, [])
        self.assertIn("no updates started", result.stderr)


if __name__ == "__main__":
    unittest.main()
