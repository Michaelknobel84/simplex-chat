# iOS signing and capabilities (Phase D)

No secrets are stored in the repo. Put local values (team ID etc.) in `apps/ios/Local.xcconfig`. Identifier setup, removed entitlements and push requirements: see `IDENTIFIERS.md`.

Per target (app, NSE, SE): Team, unique bundle IDs, provisioning (automatic signing is fine for development).
Capabilities: App Groups (upstream `group.chat.simplex.app` cannot be registered by you; pick your own and update all three `.entitlements` and Swift constants), Keychain Sharing, Push Notifications, Background Modes (see Info.plist).
Upstream `DEVELOPMENT_TEAM = 5NN7GUYB6T` must be overridden.
Push: APNs topic is the bundle ID; the notification server must be configured for it (see BRANDING.md).

# Physical iPhone checklist (Phase F)
1. macOS + current Xcode; follow `apps/ios/README.md` to obtain/build the Haskell core libraries.
2. Open `apps/ios/SimpleX.xcodeproj`; set Team on all app targets.
3. Set unique bundle IDs; register App Group and keychain group; update entitlements consistently.
4. Connect iPhone, enable Developer Mode, register device (automatic signing).
5. Run scheme `SimpleX (iOS)` on device; confirm home-screen name "Fast-Chat".
6. Create profile, exchange invitation link/QR with a second device; test text, media, voice.
7. Test push separately (app in background); needs a notification server for your APNs topic.
8. Review Nightgrey screens: list, chat, composer, Dynamic Type, safe areas.
