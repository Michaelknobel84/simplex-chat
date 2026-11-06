# Identifiers and dependencies (Fast-Chat)

Single source of truth: `apps/ios/FastChat.xcconfig` (included by Debug/Release.xcconfig; override in git-ignored `Local.xcconfig`).

| Variable | Default | Used by |
|---|---|---|
| `FASTCHAT_APP_ID` | `app.fastchat.ios` | app bundle ID; NSE `.SimpleX-NSE`; SE `.SimpleX-SE`; framework `.SimpleXChat`; tests `.Tests-iOS`; keychain group; BG task ID `<id>.receive` |
| `FASTCHAT_APP_GROUP` | `group.$(FASTCHAT_APP_ID)` | all three `.entitlements`, Info.plist key `FastChatAppGroup` |
| `FASTCHAT_DEVELOPMENT_TEAM` | empty | `DEVELOPMENT_TEAM` of all targets |

`app.fastchat.ios` is a placeholder; Apple requires App IDs to be globally unique, so change it if registration fails.

## Every dependency found on the old identifiers
- `project.pbxproj`: PRODUCT_BUNDLE_IDENTIFIER (5 targets x 2 configs), DEVELOPMENT_TEAM (10 entries). Now variables.
- Entitlements (app, NSE, SE): app group and keychain group. Now variables.
- `SimpleXChat/AppGroup.swift`: `APP_GROUP_NAME` (UserDefaults suite and shared container). Now read from Info.plist key `FastChatAppGroup` (all three host plists), falling back to the upstream value.
- `SimpleXChat/KeyChain.swift`: hardcoded `5NN7GUYB6T.chat.simplex.app`, which would make every keychain write (database passphrase, app passcode) fail on any other team. Now read from `FastChatKeychainAccessGroup` (`$(AppIdentifierPrefix)$(FASTCHAT_APP_ID)`).
- `SimpleX--iOS--Info.plist` + `Shared/Model/BGManager.swift`: BGTask ID `chat.simplex.app.receive`. Now `<bundle id>.receive` in both places.
- Left alone (internal labels only, no external effect): dispatch queue labels, `NSAttributedString.Key` names, shared-file names (`chat.simplex.app.messages` etc., inside the app group container), local notification category `chat.simplex.app.notification`, `CFBundleURLName`.
- URL scheme `simplex` kept so SimpleX invitation links keep opening.

## Entitlements removed from the main app
- `com.apple.developer.associated-domains` (`simplex.chat`, `*.simplex.im`, `*.simplexonflux.com`): domains belong to upstream; an app with a different App ID cannot be verified for universal links. `simplex:` links and pasted links still work.
- `com.apple.developer.networking.multicast` and `...user-assigned-device-name`: need special approval from Apple and block provisioning for ordinary developer accounts. Effect: local-network multicast discovery (remote desktop/multicast use) and custom device name may not work; to be verified on device.

## Compatibility
These are local, device-side identifiers; they are not part of the SimpleX protocol, so interoperability with SimpleX clients is unaffected. Existing SimpleX app data is not migrated (different container and keychain group): Fast-Chat starts with a fresh profile.

## Push notifications
The NSE decrypts notifications using the app group database and keychain, so all three IDs must match as above. Fast-Chat's APNs topic is its bundle ID. The notification server used by the app (default: SimpleX's) registers devices by APNs token and pushes with upstream's APNs credentials, which are only valid for the official app's topic. Therefore push will not work until you either run your own SimpleX notification server (ntf-server) with your APNs key and the Fast-Chat bundle ID, or use only background/periodic fetch. This is unverified and must be tested on device. `aps-environment` is `development`; Xcode switches it for distribution builds.

## Signing
Personal (free) teams cannot use Push Notifications or App Groups reliably; use a paid Apple Developer Program team. Set `FASTCHAT_DEVELOPMENT_TEAM` and optionally `FASTCHAT_APP_ID` in `apps/ios/Local.xcconfig`; Xcode automatic signing then registers the App IDs, app group and keychain group.
