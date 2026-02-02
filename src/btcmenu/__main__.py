import sys
from pathlib import Path

# Support running both as `python -m btcmenu` and `python btcmenu/__main__.py`
if __package__ is None:
    package_root = Path(__file__).resolve().parent.parent
    if str(package_root) not in sys.path:
        sys.path.insert(0, str(package_root))
    from btcmenu.app import main
else:
    from .app import main


if __name__ == "__main__":
    main()
