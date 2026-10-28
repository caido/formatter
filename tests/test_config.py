import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
TREEFMT = shutil.which('treefmt')


class ConfigurationTests(unittest.TestCase):
    def test_all_presets_parse_and_have_file_patterns(self):
        paths = [ROOT / 'treefmt.toml', *sorted((ROOT / 'profiles').glob('*.toml'))]
        for path in paths:
            with self.subTest(path=path.name):
                data = tomllib.loads(path.read_text())
                for name, formatter in data['formatter'].items():
                    self.assertTrue(formatter['command'], name)
                    self.assertTrue(formatter['includes'], name)
                for name in data.get('formatters', data['formatter']):
                    self.assertIn(name, data['formatter'])

    def test_default_avoids_competing_engines(self):
        data = tomllib.loads((ROOT / 'treefmt.toml').read_text())
        selected = set(data['formatters'])
        self.assertLessEqual(len(selected & {'oxfmt', 'prettier', 'deno'}), 1)
        self.assertLessEqual(len(selected & {'ruff', 'black'}), 1)

    def test_companion_configs_exist(self):
        import re
        for path in [ROOT / 'treefmt.toml', *(ROOT / 'profiles').glob('*.toml')]:
            data = tomllib.loads(path.read_text())
            for formatter in data['formatter'].values():
                for argument in formatter.get('options', []):
                    for name in re.findall(r'\$CAIDO_FORMATTER_ROOT/([^"\s]+)', argument):
                        self.assertTrue((ROOT / name).is_file(), name)


@unittest.skipUnless(TREEFMT, 'treefmt is required for routing tests')
class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='caido formatter ')
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / 'project with spaces'
        self.project.mkdir()
        self.bin = Path(self.temp.name) / 'bin'
        self.bin.mkdir()
        self.log = Path(self.temp.name) / 'calls.jsonl'
        # The real shell and treefmt run; only the underlying formatting tools are stubbed.
        stub = '''#!/usr/bin/env python3
import json, os, pathlib, sys
with open(os.environ['FORMAT_TEST_LOG'], 'a') as log:
    log.write(json.dumps({'tool': pathlib.Path(sys.argv[0]).name, 'args': sys.argv[1:]}) + '\\n')
for arg in sys.argv[1:]:
    path = pathlib.Path(arg)
    if path.is_file() and path.resolve().is_relative_to(pathlib.Path.cwd()):
        text = path.read_text()
        if not text.endswith('\\n'):
            path.write_text(text + '\\n')
'''
        for tool in ['oxfmt', 'prettier', 'rustup', 'ruff', 'tofu', 'shfmt', 'stylua', 'deno', 'nixfmt', 'sqlfluff', 'black']:
            path = self.bin / tool
            path.write_text(stub)
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'], FORMAT_TEST_LOG=str(self.log), XDG_CACHE_HOME=str(Path(self.temp.name) / 'cache'))

    def write(self, name, content='unformatted'):
        path = self.project / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def run_formatter(self, profile, *args):
        return subprocess.run([str(ROOT / 'bin/format'), profile, '--walk', 'filesystem', '--no-cache', *args], cwd=self.project, env=self.env, capture_output=True, text=True)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_default_routes_each_language_once_and_skips_generated_files(self):
        names = ['src/a.ts', 'src/a.rs', 'src/a.py', 'tofu/a.tf', 'scripts/a.sh', 'lua/a.lua']
        for name in names:
            self.write(name)
        ignored = [self.write('node_modules/a.ts'), self.write('src/__generated__/a.ts'), self.write('.formatter/config.json')]
        result = self.run_formatter('default')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual({call['tool'] for call in self.calls()}, {'oxfmt', 'rustup', 'ruff', 'tofu', 'shfmt', 'stylua'})
        for name in names:
            self.assertTrue((self.project / name).read_text().endswith('\n'), name)
        for path in ignored:
            self.assertEqual(path.read_text(), 'unformatted')

    def test_backend_uses_graphql_settings_and_excludes_rust_macros(self):
        self.write('schema.graphql')
        self.write('src/a.rs')
        ignored = self.write('proxy-tests/tests/common/macros/a.rs')
        result = self.run_formatter('proxy-backend')
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertEqual({c['tool'] for c in calls}, {'rustup', 'prettier'})
        self.assertIn(str(ROOT / 'configs/prettier-backend.json'), next(c['args'] for c in calls if c['tool'] == 'prettier'))
        self.assertEqual(ignored.read_text(), 'unformatted')

    def test_frontend_retains_generated_and_type_exclusions(self):
        self.write('packages/ui/src/main.ts')
        self.write('packages/ui/src/main.vue')
        ignored = self.write('packages/ui/src/@types/modules/vue-router.d.ts')
        outside = self.write('unrelated/example.ts')
        result = self.run_formatter('proxy-frontend')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual({c['tool'] for c in self.calls()}, {'oxfmt'})
        self.assertEqual(ignored.read_text(), 'unformatted')
        self.assertEqual(outside.read_text(), 'unformatted')

    def test_analytics_does_not_format_dbt_transform(self):
        self.write('apps/event_consumer/src/a.py')
        ignored = self.write('apps/transform/a.py')
        result = self.run_formatter('analytics')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual({c['tool'] for c in self.calls()}, {'ruff'})
        self.assertEqual(ignored.read_text(), 'unformatted')

    def test_ci_reports_change_then_succeeds_after_formatting(self):
        self.write('a.ts')
        first = self.run_formatter('default', '--ci')
        self.assertNotEqual(first.returncode, 0)
        second = self.run_formatter('default', '--ci')
        self.assertEqual(second.returncode, 0, second.stderr)

    def test_unknown_profile_fails_before_running_tools(self):
        result = self.run_formatter('unknown')
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.calls())

    def test_explicit_root_formats_the_target_from_another_directory(self):
        self.write('a.ts')
        result = subprocess.run([str(ROOT / 'bin/format'), 'default', '--root', str(self.project), '--walk', 'filesystem', '--no-cache'], cwd=Path(self.temp.name), env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.project / 'a.ts').read_text().endswith('\n'))


if __name__ == '__main__':
    unittest.main()
