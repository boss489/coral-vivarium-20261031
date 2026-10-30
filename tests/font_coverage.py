"""Report non-ASCII glyphs missing from bundled Nanum Gothic UI font."""
from fontTools.ttLib import TTFont
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
font = TTFont(root / 'assets/NanumGothic-Regular.ttf')
cmap = font.getBestCmap()
source = (root / 'scripts/main.gd').read_text() + (root / 'scripts/simulation.gd').read_text()
chars = {ch for text in re.findall(r'"([^"\\]+)"', source) for ch in text if ord(ch) > 127}
missing = ''.join(sorted(ch for ch in chars if ord(ch) not in cmap))
print('Font:', font['name'].getDebugName(1), 'non-ASCII chars:', len(chars), 'missing:', repr(missing))
assert not missing
