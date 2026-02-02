from setuptools import setup, find_packages

APP = ["src/btcmenu/__main__.py"]

OPTIONS = {
    # Hide dock icon (menu bar only).
    "plist": {
        "CFBundleName": "BTCMenu",
        "CFBundleDisplayName": "BTCMenu",
        "CFBundleIdentifier": "com.yuri.btcmenu",
        "CFBundleShortVersionString": "1.0.0",
        "CFBundleVersion": "1",
        "LSUIElement": True,
        "LSApplicationCategoryType": "public.app-category.finance",
    },
    "iconfile": "assets/BTCMenu.icns",
    "argv_emulation": False,
    "packages": ["rumps", "requests", "AppKit", "Foundation"],
}

setup(
    app=APP,
    options={"py2app": OPTIONS},
    setup_requires=["py2app"],
    packages=find_packages("src"),
    package_dir={"": "src"},
)
