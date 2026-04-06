.PHONY: help build stop open run debug-logs dmg zip release tag create_release_tag clean

APP_NAME := BTCMenu
APP_PATH := dist/$(APP_NAME).app

help:
	@printf '%s\n' "Available targets:"
	@printf '%s\n' "  make build    Build the .app bundle"
	@printf '%s\n' "  make stop     Stop the running app if needed"
	@printf '%s\n' "  make open     Open the built app"
	@printf '%s\n' "  make run      Build and open the app"
	@printf '%s\n' "  make debug-logs  Stream BTCMenu logs from macOS Console"
	@printf '%s\n' "  make dmg      Build the .dmg package"
	@printf '%s\n' "  make zip      Build the .app zip"
	@printf '%s\n' "  make release  Build the app, .dmg and .zip"
	@printf '%s\n' "  make tag VERSION=1.2.3            Create and push v1.2.3"
	@printf '%s\n' "  make create_release_tag VERSION=1.2.3  Alias for make tag"
	@printf '%s\n' "  make clean    Remove build artifacts"

build:
	@./scripts/build_app.sh

stop:
	@pkill -x "$(APP_NAME)" 2>/dev/null || true

open:
	@open $(APP_PATH)

run: stop build open

debug-logs:
	@log stream --predicate 'subsystem == "com.yuri.btcmenu"' --info --debug

dmg:
	@./scripts/create_dmg.sh

zip:
	@ditto -c -k --sequesterRsrc --keepParent $(APP_PATH) dist/$(APP_NAME).app.zip

release: build dmg zip

tag create_release_tag:
	@test -n "$(VERSION)" || (printf '%s\n' "Usage: make $@ VERSION=1.2.3" && exit 1)
	@./scripts/create_release_tag.sh $(VERSION)

clean:
	@rm -rf .build dist
