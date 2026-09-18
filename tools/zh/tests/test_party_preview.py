"""Reject invalid preview labels before modifying the staged tree."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import party_preview


class PreviewInputs(unittest.TestCase):
    def test_bad_labels_leave_source_untouched(self):
        cases = [
            {},
            {'name': 'A', 'cancel': '', 'prompt': 'B'},
            {'name': 'ABCDEF', 'cancel': 'A', 'prompt': 'B'},
            {'name': 'A', 'cancel': 'ABC', 'prompt': 'B'},
            {'name': 'A', 'cancel': 'A', 'prompt': 'A' * 13},
            {'name': 'A\nB', 'cancel': 'A', 'prompt': 'B'},
        ]
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'source'
            source.mkdir()
            marker = source / 'unchanged'
            marker.write_bytes(b'original')
            terms = root / 'terms.json'
            with patch.object(party_preview.ImageFont, 'truetype') as font:
                font.return_value.getlength.side_effect = lambda text: len(text) * 12
                for case in cases:
                    terms.write_text(json.dumps(case))
                    with self.subTest(case=case), self.assertRaises(ValueError):
                        party_preview.generate(source, 'font.ttf', terms)
                    self.assertEqual(list(source.iterdir()), [marker])
                    self.assertEqual(marker.read_bytes(), b'original')


if __name__ == '__main__':
    unittest.main()
