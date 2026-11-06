# Repository audit (Phase A)

Environment: Linux Codespace, no Xcode/swift. No iOS build or test was run.
Branch `fast-chat/ios-v0.1` created from `stable` (79d91e7), clean tree.

## iOS project (`apps/ios/SimpleX.xcodeproj`)
| Target | Bundle ID | Notes |
|---|---|---|
| SimpleX (iOS) | `chat.simplex.app` | PRODUCT_NAME `SimpleX`, plist `SimpleX--iOS--Info.plist`, URL scheme `simplex` |
| SimpleX NSE | `chat.simplex.app.SimpleX-NSE` | notification service extension |
| SimpleX SE | `chat.simplex.app.SimpleX-SE` | share extension |
| SimpleXChat | `chat.simplex.SimpleXChat` | framework (shared code, theme types, FFI wrapper) |
| Tests iOS | `chat.simplex.Tests-iOS` | only template UI tests (`Tests_iOS.swift`, `Tests_iOSLaunchTests.swift`) |

Schemes: `SimpleX (iOS)`, `SimpleX NSE`, `SimpleX SE`. DEVELOPMENT_TEAM is upstream's `5NN7GUYB6T` (must be replaced; Debug/Release.xcconfig `#include?` a local `Local.xcconfig`).
Entitlements: App Group `group.chat.simplex.app`; keychain group `$(AppIdentifierPrefix)chat.simplex.app` in app, NSE, SE.
Min iOS 15.0, MARKETING_VERSION 7.0.4.

## Key locations
- Theme: `SimpleXChat/Theme/ThemeTypes.swift` (palettes), `Shared/Theme/{Theme,ThemeManager}.swift`
- Views: `Shared/Views/{ChatList,Chat,UserSettings,NewChat,Onboarding,LocalAuth,...}`
- Assets: `Shared/Assets.xcassets` (AppIcon, DarkAppIcon, logos); localization `*.lproj`, `SimpleX Localizations`
- Core: the Haskell library is a prebuilt binary not in the repo; it must be built/downloaded per `apps/ios/README.md` (**unresolved binary dependency**).

## Blockers
- Needs macOS + Xcode + the compiled Haskell core libs.
- Signing, bundle IDs, App Group and APNs need an Apple Developer account.
- License: AGPL-3.0 (`/LICENSE`).
