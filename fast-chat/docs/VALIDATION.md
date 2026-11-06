# Validation

## Round 3 (fail-closed configuration)

Tooling: `python3 fast-chat/scripts/check_config.py` (any OS) — result on Linux: 36 passed, 0 failed. It checks: xcconfig variables defined; app, NSE and SE Info.plists contain nonempty `FastChatAppGroup`/`FastChatKeychainAccessGroup` that resolve after xcconfig substitution; all three entitlements files match their Info.plist values and each other; BG task ID and all bundle IDs/team entries use the variables; no upstream identifier fallback in Swift; no force-unwrapped group container; secondary text contrast >= 4.5 on all bubbles/backgrounds.
`fast-chat/scripts/check_built_app.sh <App.app>` (macOS only, not run): checks the resolved Info.plist and signed entitlements of the app and every `.appex`.

Contrast fix: dark `secondary` is now #B8BCC3 (was #A5A9B0): 4.81:1 on outgoing, 6.36 incoming, 9.83 background, 8.35 surface. Timestamps/meta use `theme.colors.secondary` everywhere (`CIMetaView` callers), so this covers outgoing timestamps. Tokens for backgrounds and bubbles are unchanged.

Xcode variable syntax reviewed by reading: xcconfig `KEY = value`, `$(VAR)` references, `#include` of `FastChat.xcconfig` before the optional `Local.xcconfig`; the project-level Debug/Release configs use these xcconfigs, so variables reach all targets; Info.plist and `.entitlements` substitute `$(VAR)`. `$(AppIdentifierPrefix)` is expected to be supplied by Xcode from the signing team. All of this is UNVERIFIED until built.

Still requires macOS/Xcode: compiling the Swift changes (never compiled; `NSLog`/regex code is untested), confirming variable expansion in the built Info.plist and signed entitlements (run `check_built_app.sh`), whether `$(AppIdentifierPrefix)` is populated, runtime behavior of the new `fatalError` paths, Keychain access, App Group sharing between app/NSE/SE, visual check of the contrast change, tests, messaging, push.

## Round 2 (identifiers, display name, theme review)

Display name: `SimpleX--iOS--Info.plist` has no `CFBundleDisplayName`, and `GENERATE_INFOPLIST_FILE = YES` merges `INFOPLIST_KEY_CFBundleDisplayName`, so the build setting supplies the key without conflict. Localized `*.lproj/SimpleX--iOS--InfoPlist.strings` define only `CFBundleName` ("SimpleX"), which does not override the home-screen display name. Source-level conclusion only; confirm in the built `.app` Info.plist.

Contrast (WCAG, computed from the tokens):
| Pair | Ratio |
|---|---|
| primary text on background | 16.9 |
| secondary text on background / surface | 7.9 / 6.8 |
| primary text on incoming / outgoing bubble | 10.9 / 8.3 |
| secondary text on incoming bubble | 5.1 |
| secondary text on outgoing bubble | 3.9 (below 4.5 for small text) |
| secondary text on received quote | 4.6 |
| blue accent on background / surface | 5.3 / 4.5 |
| bubbles vs background | 1.55 / 2.04 (low; bubbles are distinguished by position and tone) |

Issue: timestamps/secondary text inside outgoing bubbles are under 4.5:1. Not changed, to keep the specified tokens; consider a lighter secondary (e.g. #B8BCC3) there.
Unintended effects: the palette is the shared DARK base, so it affects the system dark appearance, theme previews and anything inheriting unset colors from the dark base. The default "school" wallpaper still draws over the background. Light, SimpleX and Black themes are unchanged. Not visually verified.

Checks run: all `.plist` and `.entitlements` files parse (Python `plistlib`); no `5NN7GUYB6T` left in `project.pbxproj`; `git diff` limited to identifiers/config, `AppGroup.swift`, `KeyChain.swift`, `BGManager.swift` and docs. No Haskell core, protocol or crypto code touched (`KeyChain.swift` only changes which access-group string is used).

NOT possible without macOS/Xcode (not run, no result claimed):
- Build of any target; expansion of `$(AppIdentifierPrefix)` and `$(FASTCHAT_*)` in Info.plist and entitlements.
- Resolution of xcconfig variables in the pbxproj; automatic signing and capability registration.
- Merged Info.plist inspection (display name), simulator/device run, visual theme check, unit/UI tests.
- Keychain access, app group sharing between app, NSE and SE, BG task registration.
- Messaging with a SimpleX client, push notification delivery.
- Availability of the Haskell core libraries per `apps/ios/README.md`.

The app is not known to be buildable or installable until a real iOS build succeeds.

## Round 1
Branch created; diff limited to palette values and display-name setting; no core files touched.
