"""Exercise installer decisions without installing packages or authenticating."""
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'install_codex.sh'


class InstallerTests(unittest.TestCase):
    def run_shell(self, body, *args):
        return subprocess.run(
            ['bash', '-c', 'source "$1"; shift\n' + body, 'test', str(SCRIPT), *map(str, args)],
            check=True, capture_output=True, text=True,
        ).stdout

    def test_node_readiness(self):
        for available, version_status in (('node npm', 0), ('node npm', 1), ('node', 0), ('npm', 0), ('', 0)):
            with self.subTest(available=available, version_status=version_status):
                output = self.run_shell('''
available="$1"
version_status="$2"
command() { [[ "$1" == -v && " $available " == *" $2 "* ]]; }
node() { return "$version_status"; }
if node_is_ready; then printf ready; else printf missing; fi
''', available, version_status)
                self.assertEqual(output, 'ready' if available == 'node npm' and version_status == 0 else 'missing')

    def test_existing_node_needs_no_nvm(self):
        self.run_shell('''
node_is_ready() { return 0; }
curl() { return 99; }
ensure_node
''')

    def test_load_existing_nvm_or_upgrade_old_node(self):
        for ready_after_source in (True, False):
            with self.subTest(ready=ready_after_source), tempfile.TemporaryDirectory() as tmp:
                nvm = Path(tmp) / 'nvm.sh'
                nvm.write_text('''
node_is_ready() { return READY; }
nvm() { printf '%s\n' "$*"; if [[ "$1" == use ]]; then node_is_ready() { return 0; }; fi; }
'''.replace('READY', '0' if ready_after_source else '1'))
                output = self.run_shell('''
export NVM_DIR="$1"
node_is_ready() { return 1; }
curl() { return 99; }
ensure_node
''', tmp)
                if ready_after_source:
                    self.assertEqual(output, '')
                else:
                    self.assertIn('install 22', output)
                    self.assertIn('alias default 22', output)

    def test_fresh_nvm_install(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = self.run_shell('''
export NVM_DIR="$1"
node_is_ready() { return 1; }
curl() {
    [[ "$1" == -fsSL && "$3" == -o ]]
    cat > "$4" <<'INSTALLER'
mkdir -p "$NVM_DIR"
cat > "$NVM_DIR/nvm.sh" <<'NVM'
nvm() { printf '%s\n' "$*"; if [[ "$1" == use ]]; then node_is_ready() { return 0; }; fi; }
NVM
INSTALLER
}
ensure_node
''', Path(tmp) / 'nvm')
            self.assertIn('install 22', output)
            self.assertIn('use 22', output)

    def test_package_managers(self):
        for manager in ('apt-get', 'dnf', 'pacman', 'brew'):
            with self.subTest(manager=manager):
                output = self.run_shell('''
manager="$1"
command() { [[ "$1" == -v && "$2" == "$manager" ]]; }
run_as_root() { printf '%s\n' "$*"; }
brew() { printf 'brew %s\n' "$*"; }
install_prerequisites
''', manager)
                self.assertIn(manager, output)
                self.assertIn('python-pipx' if manager == 'pacman' else 'pipx', output)
                self.assertIn('curl', output)

    def test_installed_prerequisites_skip_package_manager(self):
        self.run_shell('''
command() { [[ "$1" == -v && ( "$2" == curl || "$2" == pipx ) ]]; }
run_as_root() { return 99; }
install_prerequisites
''')

    def test_config_creation_and_preservation(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / 'config.toml'
            self.run_shell('write_codex_config "$1"', config)
            parsed = tomllib.loads(config.read_text())
            self.assertIn(parsed['model_provider'], parsed['model_providers'])
            config.write_text('# user config\n')
            self.run_shell('write_codex_config "$1"', config)
            self.assertEqual(config.read_text(), '# user config\n')
            link = Path(tmp) / 'dangling.toml'
            link.symlink_to(Path(tmp) / 'missing.toml')
            self.run_shell('write_codex_config "$1"', link)
            self.assertTrue(link.is_symlink())
            self.assertFalse(link.exists())

    def test_help_has_no_install_side_effects(self):
        self.run_shell('''
install_prerequisites() { return 99; }
ensure_node() { return 99; }
main --help
''')


if __name__ == '__main__':
    unittest.main()
