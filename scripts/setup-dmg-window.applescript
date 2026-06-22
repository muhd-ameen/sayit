tell application "Finder"
    tell disk "SayIt"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {0, 0, 660, 420}
        set viewOptions to icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 120
        set background picture of viewOptions to (POSIX file "/Volumes/SayIt/.background/background.png")
        set position of item "SayIt.app" to {175, 240}
        set position of item "Applications" to {485, 240}
        close
        open
        update without registering applications
        delay 3
    end tell
end tell
