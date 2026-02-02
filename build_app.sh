#!/usr/bin/env bash
set -euo pipefail

python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

python3 scripts/generate_icon.py
python3 - <<'PY'
from PIL import Image
from pathlib import Path

src = Path("assets/BTCMenu.png")
out = Path("assets/BTCMenu.icns")
img = Image.open(src).convert("RGBA")
sizes = [(16,16),(32,32),(64,64),(128,128),(256,256),(512,512),(1024,1024)]
img.save(out, sizes=sizes)
print(f"Icon gerado em {out}")
PY

COPYFILE_DISABLE=1 python3 setup.py py2app

echo "App gerado em ./dist/BTCMenu.app"
