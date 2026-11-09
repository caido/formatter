"""Exercise the one shared configuration with real Nix-packaged formatters."""

import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


PROGRAM = os.environ["CAIDO_FORMATTER"]
CONFIG = tomllib.loads(Path(os.environ["CAIDO_FORMATTER_CONFIG"]).read_text())
SAMPLES = {
    "src/example.ts": 'import z from "z";\nimport fs from "node:fs";\nexport const x={z,fs};',
    "src/example.py": 'answer={"value":1+2}',
    "src/example.rs": 'async fn example(){println!("hello");}',
    "infra/example.tf": 'locals { value="test" }',
    "scripts/example.sh": '#!/bin/sh\ncase "$1" in value) echo "hello";; esac\nif true;then echo "hello";fi',
    "src/example.lua": 'local answer={"hello",2,3}',
    "example.nix": '{ value="test"; }',
    "sql/example.sql": "select  a,b  from test_table  where a=1;\n",
    "src/example.vue": '<template><div class="test">hello</div></template>',
    "schema/example.graphql": "query Example{viewer{id name}}",
}


def write(root, name, content):
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


def run(root, *args, env=None):
    return subprocess.run(
        [
            PROGRAM,
            "--tree-root",
            str(root),
            "--working-dir",
            str(root),
            "--walk",
            "filesystem",
            "--no-cache",
            *args,
        ],
        cwd=root.parent,
        env=dict(os.environ, XDG_CACHE_HOME=str(root.parent / "cache"))
        if env is None
        else env,
        capture_output=True,
        text=True,
    )


class SharedConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="shared formatter ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "checkout with spaces"
        self.root.mkdir()

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_one_engine_per_language_and_store_paths(self):
        self.assertEqual(
            set(CONFIG["formatter"]),
            {
                "oxfmt",
                "ruff-format",
                "rustfmt",
                "terraform",
                "shfmt",
                "stylua",
                "nixfmt",
                "sqlfluff",
            },
        )
        for formatter in CONFIG["formatter"].values():
            self.assertTrue(formatter["command"].startswith("/nix/store/"))
            self.assertTrue(os.access(formatter["command"], os.X_OK))
            self.assertTrue(formatter["includes"])

    def test_all_languages_format_and_are_idempotent(self):
        for name, content in SAMPLES.items():
            write(self.root, name, content)
        self.assert_success(run(self.root))
        for name, before in SAMPLES.items():
            self.assertNotEqual((self.root / name).read_text(), before, name)
        self.assert_success(run(self.root, "--ci"))

    def test_two_repositories_use_identical_settings_despite_local_configs(self):
        other = Path(self.temp.name) / "another checkout"
        other.mkdir()
        for root in [self.root, other]:
            for name, content in SAMPLES.items():
                write(root, name, content)
        write(other, ".oxfmtrc.json", '{"singleQuote":true,"tabWidth":7}')
        write(other, "src/.oxfmtrc.json", '{"semi":false,"printWidth":180}')
        write(other, ".prettierignore", "src/example.ts\n")
        write(
            other,
            ".editorconfig",
            "root=true\n[*]\nindent_size=7\nindent_style=tab\n"
            "binary_next_line=true\nswitch_case_indent=true\nspace_redirects=true\n",
        )
        write(other, "pyproject.toml", '[tool.ruff.format]\nquote-style="single"\n')
        write(other, "rustfmt.toml", "hard_tabs=true\n")
        write(other, "stylua.toml", 'quote_style="ForceSingle"\nindent_type="Tabs"\n')
        write(other, ".styluaignore", "src/example.lua\n")
        write(other, ".sqlfluff", "[sqlfluff]\ndialect=sqlite\nmax_line_length=180\n")
        write(other, ".sqlfluffignore", "sql/example.sql\n")
        self.assert_success(run(self.root, *SAMPLES))
        self.assert_success(run(other, *SAMPLES))
        for name in SAMPLES:
            self.assertEqual(
                (self.root / name).read_bytes(), (other / name).read_bytes(), name
            )

    def test_generic_dependency_and_generated_exclusions(self):
        ignored = [
            write(self.root, name, "invalid code")
            for name in [
                "node_modules/broken.ts",
                "src/__generated__/broken.ts",
                ".venv/broken.py",
                "dist/broken.lua",
            ]
        ]
        write(self.root, "any/directory/valid.ts", "export const x={a:1}")
        self.assert_success(run(self.root))
        for path in ignored:
            self.assertEqual(path.read_text(), "invalid code")

    def test_rustfmt_does_not_touch_unselected_children(self):
        write(self.root, "src/lib.rs", "mod child;\npub fn value()->u32{42}")
        child = write(self.root, "src/child.rs", "pub fn child(){let value=1;}")
        before = child.read_text()
        self.assert_success(run(self.root, "src/lib.rs"))
        self.assertEqual(child.read_text(), before)

    def test_ci_failure_is_detected_formatting_changes(self):
        source = write(self.root, "any/path/example.ts", "export const x={a:1}")
        before = source.read_text()
        first = run(self.root, "--ci")
        self.assertNotEqual(first.returncode, 0)
        self.assertIn("--fail-on-change is enabled", first.stdout + first.stderr)
        self.assertNotEqual(source.read_text(), before)
        self.assert_success(run(self.root, "--ci"))

    def test_runtime_does_not_depend_on_host_formatters(self):
        write(self.root, "src/example.ts", "export const x={a:1}")
        write(self.root, "src/example.rs", "fn main(){let value=1;}")
        empty_path = Path(self.temp.name) / "no host tools"
        empty_path.mkdir()
        self.assert_success(run(self.root, env=dict(os.environ, PATH=str(empty_path))))


if __name__ == "__main__":
    unittest.main()
