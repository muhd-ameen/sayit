APP      = SayIt
BUILD    = .build/release
APP_BUNDLE = $(APP).app
CONTENTS = $(APP_BUNDLE)/Contents
ICON_SRC = Sources/SayIt/Assets.xcassets/AppIcon.appiconset

.PHONY: build icon app install dmg release uninstall clean

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
	@codesign --force --sign - $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

install: app
	@rm -rf /Applications/$(APP_BUNDLE)
	@cp -r $(APP_BUNDLE) /Applications/
	@xattr -cr /Applications/$(APP_BUNDLE)
	@echo "Installed to /Applications/$(APP_BUNDLE)"
	@open /Applications/$(APP_BUNDLE)

dmg: app
	@rm -rf /tmp/$(APP)-dmg $(APP).dmg
	@mkdir /tmp/$(APP)-dmg
	@cp -r $(APP_BUNDLE) /tmp/$(APP)-dmg/
	@ln -s /Applications /tmp/$(APP)-dmg/Applications
	@hdiutil create -volname "$(APP)" -srcfolder /tmp/$(APP)-dmg -ov -format UDZO $(APP).dmg
	@rm -rf /tmp/$(APP)-dmg
	@echo "Built $(APP).dmg — ready to upload to GitHub Releases"

release: dmg
	@echo "Release artifact: $(APP).dmg"

uninstall:
	@rm -rf /Applications/$(APP_BUNDLE)
	@echo "Removed /Applications/$(APP_BUNDLE)"

clean:
	@rm -rf .build $(APP_BUNDLE)
