#!/bin/bash

OUTPUT="kairos_flutter_dump.txt"

echo "==============================" > "$OUTPUT"
echo "Kairos Flutter Project Dump" >> "$OUTPUT"
echo "Generated: $(date)" >> "$OUTPUT"
echo "==============================" >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "PROJECT STRUCTURE" >> "$OUTPUT"
echo "==============================" >> "$OUTPUT"

tree . -I ".dart_tool|build|.git|.idea|.vscode|ios/Pods|macos/Pods|android/.gradle|linux/flutter|windows/flutter|coverage|test/.dart_tool" >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "==============================" >> "$OUTPUT"
echo "FILES" >> "$OUTPUT"
echo "==============================" >> "$OUTPUT"

find . -type f \( \
-name "*.dart" -o \
-name "*.yaml" -o \
-name "*.yml" -o \
-name "*.json" -o \
-name "*.md" -o \
-name "*.xml" -o \
-name "*.gradle" -o \
-name "*.properties" -o \
-name "*.plist" -o \
-name "*.xcconfig" -o \
-name "*.html" -o \
-name "*.css" -o \
-name "*.svg" -o \
-name "*.txt" \
\) \
! -path "*/.dart_tool/*" \
! -path "*/build/*" \
! -path "*/.git/*" \
! -path "*/.idea/*" \
! -path "*/.vscode/*" \
! -path "*/ios/Pods/*" \
! -path "*/macos/Pods/*" \
! -path "*/android/.gradle/*" \
! -path "*/linux/flutter/*" \
! -path "*/windows/flutter/*" \
! -path "*/coverage/*" \
! -name "*.g.dart" \
! -name "*.freezed.dart" \
! -name "*.mocks.dart" \
! -name "*.pb.dart" \
! -name "*.pbjson.dart" \
! -name "*.pbenum.dart" \
! -name "*.pbserver.dart" \
! -name ".flutter-plugins" \
! -name ".flutter-plugins-dependencies" \
! -name ".packages" \
! -name "pubspec.lock" \
! -name ".DS_Store" \
! -name ".env" \
! -name ".env.*" \
! -name "$OUTPUT" \
| sort | while read file; do

echo "" >> "$OUTPUT"
echo "============================================================" >> "$OUTPUT"
echo "FILE: $file" >> "$OUTPUT"
echo "============================================================" >> "$OUTPUT"

cat "$file" >> "$OUTPUT"

echo "" >> "$OUTPUT"

done

echo ""
echo "✅ AI dump created:"
echo "$OUTPUT"