APP      = SayIt
BUILD    = .build/release
APP_BUNDLE = $(APP).app
CONTENTS = $(APP_BUNDLE)/Contents
ICON_SRC = Sources/SayIt/Assets.xcassets/AppIcon.appiconset
CERT     = Developer ID Application: APPETITE STUDIO LTD (PVB264U36R)

.PHONY: build icon app install dmg notarize release uninstall clean

build:
	swift build -c release

icon:
	@rm -rf /tmp/$(APP).iconset
	@mkdir -p /tmp/$(APP).iconset
	@cp $(ICON_SRC)/icon_16x16.png   /tmp/$(APP).iconset/icon_16x16.png
	@cp $(ICON_SRC)/icon_32x32.png   /tmp/$(APP).iconset/icon_16x16@2x.png
	@cp $(ICON_SRC)/icon_32x32.png   /tmp/$(APP).iconset/icon_32x32.png
	@cp $(ICON_SRC)/icon_64x64.png   /tmp/$(APP).iconset/icon_32x32@2x.png
	@cp $(ICON_SRC)/icon_128x128.png /tmp/$(APP).iconset/icon_128x128.png
	@cp $(ICON_SRC)/icon_256x256.png /tmp/$(APP).iconset/icon_128x128@2x.png
	@cp $(ICON_SRC)/icon_256x256.png /tmp/$(APP).iconset/icon_256x256.png
	@cp $(ICON_SRC)/icon_512x512.png /tmp/$(APP).iconset/icon_256x256@2x.png
	@cp $(ICON_SRC)/icon_512x512.png /tmp/$(APP).iconset/icon_512x512.png
	@cp $(ICON_SRC)/icon_1024x1024.png /tmp/$(APP).iconset/icon_512x512@2x.png
	@iconutil -c icns /tmp/$(APP).iconset -o AppIcon.icns
	@echo "Built AppIcon.icns"

app: build icon
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(CONTENTS)/MacOS $(CONTENTS)/Resources
	@cp $(BUILD)/$(APP) $(CONTENTS)/MacOS/
	@strip $(CONTENTS)/MacOS/$(APP)
	@cp Info.plist $(CONTENTS)/
	@cp AppIcon.icns $(CONTENTS)/Resources/
	@if [ -d "$(BUILD)/$(APP)_$(APP).bundle" ]; then \
		cp -r $(BUILD)/$(APP)_$(APP).bundle $(CONTENTS)/Resources/; \
	fi
	@codesign --force --deep --sign "$(CERT)" \
		--options runtime \
		--entitlements entitlements.plist \
		$(APP_BUNDLE)
	@echo "Built and signed $(APP_BUNDLE)"

install: app
	@rm -rf /Applications/$(APP_BUNDLE)
	@cp -r $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_BUNDLE)"
	@open /Applications/$(APP_BUNDLE)

dmg: app
	@rm -f $(APP).dmg
	create-dmg \
		--volname "$(APP)" \
		--background "assets/dmg-background.png" \
		--window-size 660 420 \
		--icon-size 120 \
		--icon "$(APP_BUNDLE)" 175 240 \
		--app-drop-link 485 240 \
		--no-internet-enable \
		"$(APP).dmg" \
		"$(APP_BUNDLE)"
	@echo "Built $(APP).dmg"

notarize: dmg
	@echo "Submitting to Apple for notarization..."
	xcrun notarytool submit $(APP).dmg \
		--keychain-profile "sayit-notarize" \
		--wait
	xcrun stapler staple $(APP).dmg
	@echo "Notarized and stapled $(APP).dmg"

release: notarize
	@echo "Release artifact: $(APP).dmg — ready to upload"

uninstall:
	@rm -rf /Applications/$(APP_BUNDLE)
	@echo "Removed /Applications/$(APP_BUNDLE)"

clean:
	@rm -rf .build $(APP_BUNDLE) AppIcon.icns $(APP).dmg
