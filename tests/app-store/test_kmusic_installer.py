"""Run in a disposable VM: KMUSIC_SOURCE_DIR=/path/to/KMusic python3 -m unittest discover -s tests/app-store -p test_kmusic_installer.py."""
import importlib.util
import os
import pathlib
import tempfile
import unittest
from unittest.mock import patch
source = pathlib.Path(os.environ.get('KMUSIC_SOURCE_DIR', str(pathlib.Path(__file__).resolve().parents[3]/'KMusic')))
installer = source/'packaging/installer.py'
if not installer.is_file():
    raise RuntimeError('Set KMUSIC_SOURCE_DIR to the KMusic checkout containing packaging/installer.py')
spec = importlib.util.spec_from_file_location('installer', installer)
i = importlib.util.module_from_spec(spec); spec.loader.exec_module(i)

class InstallerContract(unittest.TestCase):
    def test_missing_dependencies_are_structured(self):
        with tempfile.TemporaryDirectory() as td, patch.object(i.shutil, 'which', return_value=None):
            with self.assertRaises(i.Failure) as caught:
                i.dependencies(pathlib.Path(td))
        self.assertEqual(caught.exception.code, 'DEPENDENCY_UNSATISFIED')
        self.assertGreater(len(caught.exception.details['dependencies']), 1)
        for dep in caught.exception.details['dependencies']:
            self.assertEqual(set(dep), {'id','required','installed','reason'})
            self.assertEqual(dep['reason'], 'missing')

    def test_mutable_revision_rejected(self):
        with patch.object(i.sys, 'argv', ['install.sh','install','--version','main']):
            with self.assertRaises(i.Failure) as caught: i.main()
        self.assertEqual(caught.exception.code, 'INVALID_ARGUMENT')

    def test_atomic_switch_preserves_old_payload(self):
        with tempfile.TemporaryDirectory() as td:
            root=pathlib.Path(td); old=root/'old'; new=root/'new'; link=root/'current'
            old.mkdir(); new.mkdir(); i.atomic_link(link,old); i.atomic_link(link,new)
            self.assertEqual(link.resolve(),new)
            self.assertTrue(old.is_dir())

if __name__=='__main__': unittest.main()
