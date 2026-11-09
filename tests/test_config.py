"""Integration tests for the actual Nix-packaged formatters and generated config."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest


PACKAGES = json.loads(os.environ["CAIDO_TEST_CONFIGS"])


class ConfigurationTests(unittest.TestCase):
    def test_commands_and_companion_configs_are_in_the_store(self):
        for name, package in PACKAGES.items():
            data = tomllib.loads(Path(package["config"]).read_text())
            with self.subTest(profile=name):
                self.assertTrue(data["formatter"])
                for formatter in data["formatter"].values():
                    command = formatter["command"]
                    self.assertTrue(command.startswith("/nix/store/"), command)
                    self.assertTrue(os.access(command, os.X_OK), command)
                    self.assertTrue(formatter["includes"])
                    for argument in formatter.get("options", []):
                        self.assertNotIn("CAIDO_FORMATTER_ROOT", argument)
                        if argument.startswith("/nix/store/"):
                            self.assertTrue(Path(argument).exists(), argument)

    def test_default_avoids_competing_engines(self):
        data = tomllib.loads(Path(PACKAGES["default"]["config"]).read_text())
        engines = set(data["formatter"])
        self.assertLessEqual(len(engines & {"oxfmt", "prettier", "deno"}), 1)
        self.assertLessEqual(len(engines & {"ruff-format", "black"}), 1)

    def test_backend_and_python_settings_are_generated(self):
        backend = tomllib.loads(Path(PACKAGES["proxy-backend"]["config"]).read_text())
        args = backend["formatter"]["prettier"]["options"]
        settings = json.loads(Path(args[args.index("--config") + 1]).read_text())
        self.assertEqual(settings["overrides"][0]["options"]["printWidth"], 100)
        private = tomllib.loads(Path(PACKAGES["caido-private"]["config"]).read_text())
        args = private["formatter"]["ruff-format"]["options"]
        settings = tomllib.loads(Path(args[args.index("--config") + 1]).read_text())
        self.assertEqual(settings["target-version"], "py311")


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="caido formatter ")
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / "project with spaces"
        self.project.mkdir()
        self.env = dict(os.environ, XDG_CACHE_HOME=str(Path(self.temp.name) / "cache"))
        self.env.pop("CAIDO_FORMATTER_ROOT", None)

    def write(self, name, content="invalid code that must remain excluded"):
        path = self.project / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def run_formatter(self, profile, *args):
        return subprocess.run(
            [
                PACKAGES[profile]["program"],
                "--tree-root",
                str(self.project),
                "--working-dir",
                str(self.project),
                "--walk",
                "filesystem",
                "--no-cache",
                *args,
            ],
            cwd=self.temp.name,
            env=self.env,
            capture_output=True,
            text=True,
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_default_formats_six_languages_and_skips_generated_files(self):
        samples = {
            "src/a.ts": 'export const value={foo:"bar"}',
            "src/a.rs": 'fn main(){println!("hello");}',
            "src/a.py": "answer=1+2",
            "tofu/a.tf": 'locals { value="test" }',
            "scripts/a.sh": "#!/bin/sh\nif true;then echo ok;fi",
            "lua/a.lua": "local answer={1,2,3}",
        }
        for name, content in samples.items():
            self.write(name, content)
        ignored = [
            self.write("node_modules/a.ts"),
            self.write("src/__generated__/a.ts"),
            self.write(".formatter/config.json"),
        ]
        self.assert_success(self.run_formatter("default"))
        for name, content in samples.items():
            formatted = (self.project / name).read_text()
            self.assertNotEqual(formatted, content, name)
        for path in ignored:
            self.assertEqual(path.read_text(), "invalid code that must remain excluded")
        self.assert_success(self.run_formatter("default", "--ci"))

    def test_backend_preserves_macro_exclusion(self):
        self.write("schema.graphql", "query Example{viewer{id name}}")
        self.write("src/a.rs", "fn main(){let value=1;}")
        ignored = self.write("proxy-tests/tests/common/macros/a.rs")
        self.assert_success(self.run_formatter("proxy-backend"))
        self.assertEqual(ignored.read_text(), "invalid code that must remain excluded")
        self.assert_success(self.run_formatter("proxy-backend", "--ci"))

    def test_rustfmt_does_not_recurse_into_unselected_children(self):
        self.write("src/lib.rs", "mod child;\npub fn main(){let value=1;}")
        child = self.write("src/child.rs", "pub fn child(){let answer=42;}")
        before = child.read_text()
        self.assert_success(self.run_formatter("proxy-backend", "src/lib.rs"))
        self.assertEqual(child.read_text(), before)

    def test_frontend_keeps_source_scopes_and_sorts_imports(self):
        source = self.write(
            "packages/ui/src/main.ts",
            'import z from "z";\nimport fs from "node:fs";\nexport const x={z,fs};',
        )
        self.write("packages/ui/src/main.vue", "<template><div>hello</div></template>")
        ignored = [
            self.write("packages/ui/src/@types/modules/vue-router.d.ts"),
            self.write("unrelated/example.ts"),
        ]
        self.assert_success(self.run_formatter("proxy-frontend"))
        self.assertTrue(source.read_text().startswith('import fs from "node:fs";'))
        for path in ignored:
            self.assertEqual(path.read_text(), "invalid code that must remain excluded")

    def test_analytics_excludes_dbt_and_private_limits_source_scopes(self):
        self.write("apps/event_consumer/src/a.py", "answer=1+2")
        ignored = self.write("apps/transform/a.py")
        self.assert_success(self.run_formatter("analytics"))
        self.assertEqual(ignored.read_text(), "invalid code that must remain excluded")
        self.write("scripts/a.py", "answer=1+2")
        self.write("tests/a.py", "answer=1+2")
        outside = self.write("outside/a.py")
        self.assert_success(self.run_formatter("caido-private"))
        self.assertEqual(outside.read_text(), "invalid code that must remain excluded")

    def test_infrastructure_formats_multiple_files(self):
        for name in ["a.tf", "nested/b.tf"]:
            self.write("tofu/" + name, 'locals { value="test" }')
        self.assert_success(self.run_formatter("infrastructure"))
        self.assert_success(self.run_formatter("infrastructure", "--ci"))

    def test_ci_reports_change_then_succeeds_after_formatting(self):
        source = self.write("packages/ui/src/a.ts", "export const a={b:1}")
        before = source.read_text()
        first = self.run_formatter("proxy-frontend", "--ci")
        self.assertNotEqual(first.returncode, 0)
        self.assertIn(
            "unexpected changes detected, --fail-on-change is enabled",
            first.stdout + first.stderr,
        )
        self.assertNotEqual(source.read_text(), before)
        self.assert_success(self.run_formatter("proxy-frontend", "--ci"))

    def test_packaged_tools_do_not_use_ambient_path(self):
        self.write("schema.graphql", "query Example{viewer{id name}}")
        self.write("src/a.rs", "fn main(){let answer=42;}")
        poison = Path(self.temp.name) / "broken host tools"
        poison.mkdir()
        for name in ["rustup", "rustfmt", "prettier", "sh", "treefmt"]:
            path = poison / name
            path.write_text("#!/bin/sh\nexit 99\n")
            path.chmod(0o755)
        self.env["PATH"] = str(poison)
        self.assert_success(self.run_formatter("proxy-backend"))


class LauncherTests(unittest.TestCase):
    def test_explicit_root_and_arguments_are_forwarded_without_installing_host_tools(
        self,
    ):
        with tempfile.TemporaryDirectory(prefix="caido launcher ") as temp:
            temp = Path(temp)
            target = temp / "project with spaces"
            target.mkdir()
            binary_dir = temp / "bin"
            binary_dir.mkdir()
            capture = temp / "arguments.json"
            fake_nix = binary_dir / "nix"
            fake_nix.write_text(
                f"#!{sys.executable}\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "Path(os.environ['CAPTURE_ARGS']).write_text(json.dumps(sys.argv[1:]))\n"
            )
            fake_nix.chmod(0o755)
            env = dict(
                os.environ,
                PATH=str(binary_dir) + os.pathsep + os.environ["PATH"],
                CAPTURE_ARGS=str(capture),
            )
            launcher = Path(os.environ["CAIDO_TEST_SOURCE"]) / "bin/format"
            result = subprocess.run(
                [
                    os.environ["CAIDO_TEST_SHELL"],
                    str(launcher),
                    "proxy-frontend",
                    "--root",
                    str(target),
                    "--ci",
                    "packages/ui/src/file with spaces.ts",
                ],
                cwd=temp,
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            args = json.loads(capture.read_text())
            self.assertIn("run", args)
            self.assertEqual(args[args.index("run") + 1], "--no-update-lock-file")
            self.assertTrue(args[args.index("run") + 2].endswith("#proxy-frontend"))
            self.assertEqual(args[args.index("--tree-root") + 1], str(target.resolve()))
            self.assertEqual(
                args[args.index("--working-dir") + 1], str(target.resolve())
            )
            self.assertEqual(args[-2:], ["--ci", "packages/ui/src/file with spaces.ts"])


if __name__ == "__main__":
    unittest.main()
