"""Contrats de paquets pour l'import GitHub OpenAI (sans dépendance externe).

Exécution : python3 -m unittest discover -s tests -v
Référentiel : https://developers.openai.com/plugins/deploy/submission-errors
"""
import json
import os
from pathlib import Path
import re
import unittest

ROOT = Path(os.environ.get('PLUGIN_REPO', Path(__file__).resolve().parents[1]))


def load_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def skill_field(path, key):
    # Les skills du dépôt utilisent des scalaires sur une ligne, entre guillemets
    # doubles (syntaxe JSON compatible YAML), ou un nom non cité.
    frontmatter = path.read_text(encoding='utf-8').split('---', 2)[1]
    match = re.search(rf'^{key}:\s*(.+)$', frontmatter, re.MULTILINE)
    if not match:
        raise AssertionError(f'{path}: champ {key} absent')
    value = match.group(1).strip()
    return json.loads(value) if value.startswith('"') else value


class PluginPackages(unittest.TestCase):
    def test_catalogs_and_manifests(self):
        native = load_json(ROOT / '.agents/plugins/marketplace.json')
        claude = load_json(ROOT / '.claude-plugin/marketplace.json')
        self.assertEqual(native['name'], claude['name'])
        expected = {'kp-agents', 'jpb-platform'}
        self.assertEqual({p['name'] for p in native['plugins']}, expected)
        self.assertEqual({p['name'] for p in claude['plugins']}, expected)
        self.assertEqual(len(native['plugins']), len(expected))
        for entry in native['plugins']:
            with self.subTest(plugin=entry['name']):
                source = entry['source']
                self.assertEqual(source['source'], 'local')
                self.assertTrue(source['path'].startswith('./'))
                plugin_root = (ROOT / source['path']).resolve()
                self.assertTrue(plugin_root.is_relative_to(ROOT.resolve()))
                manifest = load_json(plugin_root / '.codex-plugin/plugin.json')
                self.assertEqual(manifest['name'], entry['name'])
                # L'import OpenAI exige le dossier skills/ à la racine du paquet.
                self.assertEqual(manifest['skills'], './skills/')
                self.assertTrue((plugin_root / 'skills').is_dir())
                twin = next(p for p in claude['plugins'] if p['name'] == entry['name'])
                cm = load_json(ROOT / twin['source'] / '.claude-plugin/plugin.json')
                self.assertEqual(manifest['version'], cm['version'])
                self.assertEqual(manifest['name'], cm['name'])
                self.assertLessEqual(len(manifest['description']), 1024)
                self.assertEqual(entry['policy']['installation'], 'AVAILABLE')

    def test_skill_descriptions(self):
        for base in ['claude/skills', 'codex', 'jpb-platform/skills', 'jpb-platform/codex']:
            paths = list((ROOT / base).rglob('SKILL.md'))
            self.assertTrue(paths, base)
            for path in paths:
                with self.subTest(skill=str(path.relative_to(ROOT))):
                    description = skill_field(path, 'description')
                    self.assertTrue(description.strip())
                    self.assertLessEqual(len(description), 1024)
                    name = skill_field(path, 'name')
                    self.assertTrue(name.strip())
                    self.assertTrue(path.read_text().split('---', 2)[2].strip())

    def test_native_skill_identities(self):
        native = load_json(ROOT / '.agents/plugins/marketplace.json')
        for entry in native['plugins']:
            root = ROOT / entry['source']['path'] / 'skills'
            paths = list(root.glob('*/SKILL.md'))
            names = [skill_field(path, 'name') for path in paths]
            self.assertEqual(len(names), len(set(names)))
            self.assertEqual(len(names), {'kp-agents': 10, 'jpb-platform': 3}[entry['name']])
            for name in names:
                self.assertLessEqual(len(entry['name'] + ':' + name), 64)


if __name__ == '__main__':
    unittest.main()
