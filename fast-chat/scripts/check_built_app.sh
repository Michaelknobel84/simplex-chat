#!/bin/bash
# macOS only: verifies the RESOLVED configuration of a built Fast-Chat.app (and its extensions).
# Usage: fast-chat/scripts/check_built_app.sh /path/to/Fast-Chat.app   (the .app may still be named SimpleX.app)
set -u
APP="${1:?usage: $0 path/to/App.app}"
fail=0
bad() { echo "FAIL $*"; fail=1; }
ok() { echo "PASS $*"; }
[ "$(uname)" = Darwin ] || { echo "requires macOS (plutil, codesign)"; exit 2; }

read_key() { /usr/bin/plutil -extract "$2" raw -o - "$1" 2>/dev/null; }
ents() { codesign -d --entitlements :- "$1" 2>/dev/null; }

ref_group=""; ref_kc=""
for B in "$APP" "$APP"/PlugIns/*.appex; do
  [ -e "$B" ] || continue
  g=$(read_key "$B/Info.plist" FastChatAppGroup); k=$(read_key "$B/Info.plist" FastChatKeychainAccessGroup)
  case "$g" in group.*[!A-Za-z0-9.-]*|""|*'$'*) bad "$B: FastChatAppGroup invalid: '$g'";; *) ok "$B app group $g";; esac
  case "$k" in ""|*'$'*|.*) bad "$B: FastChatKeychainAccessGroup unresolved or lacks team prefix: '$k'";; *) ok "$B keychain group $k";; esac
  [ -z "$ref_group" ] && ref_group="$g" && ref_kc="$k"
  [ "$g" = "$ref_group" ] && [ "$k" = "$ref_kc" ] || bad "$B: differs from first target"
  e=$(ents "$B")
  echo "$e" | grep -q "<string>$g</string>" && ok "$B entitlement contains app group" || bad "$B: signed entitlements lack app group $g"
  echo "$e" | grep -q "<string>$k</string>" && ok "$B entitlement contains keychain group" || bad "$B: signed entitlements lack keychain group $k"
  echo "$e" | grep -q '\$(' && bad "$B: unresolved variable in entitlements"
done
echo "Display name: $(read_key "$APP/Info.plist" CFBundleDisplayName)"
echo "BG task ids: $(read_key "$APP/Info.plist" BGTaskSchedulerPermittedIdentifiers)"
exit $fail
