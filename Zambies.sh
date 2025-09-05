#!/bin/bash
# build.sh — package only Lua files into Zambies.love

OUTPUT="Zambies.love"
TEMP="game.zip"

# clean up old builds
rm -f "$OUTPUT" "$TEMP"

# zip only .lua files recursively from current dir
find . -type f -name "*.lua" | zip -9 "$TEMP" -@

# rename to .love
mv "$TEMP" "$OUTPUT"

echo "Built $OUTPUT with only Lua files 🎉"
