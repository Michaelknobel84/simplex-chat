# Branding (Phase B) and theme (Phase C)

## Changed
- `CFBundleDisplayName` = `Fast-Chat` for the main app (`INFOPLIST_KEY_CFBundleDisplayName` in both build configs of target "SimpleX (iOS)"). `PRODUCT_NAME` stays `SimpleX`, so module/binary names are unaffected.
- Nightgrey theme: the existing dark palette (`DarkColorPalette`, `DarkColorPaletteApp` in `SimpleXChat/Theme/ThemeTypes.swift`) now uses: background #111215, surface #202227, text #F2F3F5, secondary text #A5A9B0, borders/secondaryVariant #3A3D43, incoming bubble #33363C, outgoing bubble #444850, quotes #3A3D43 / #292C31. Because the chat list, chat view, composer and navigation use the theme system, they pick this up. Accent stays upstream blue. Light and other built-in themes are unchanged. Not visually verified (no simulator).

## Intentionally untouched
- Bundle IDs, App Group, keychain group, `simplex:` URL scheme, APNs, NSE/SE display names.
- In-app strings, localizations, About/Settings copy, app icons, splash: still SimpleX. Icons need original Fast-Chat artwork (no SimpleX or other brand assets); strings need per-string review.
- All protocol, FFI and crypto code.

## AGPL-3.0 obligations
Keep `LICENSE`, copyright headers and third-party notices. Distributed or network-offered modified versions must provide corresponding source under AGPLv3 and mark changes. Keep a visible source link (e.g. in About) to this fork. Review SimpleX name/logo trademark use before public distribution; keep "based on SimpleX Chat" attribution.

## Identifier migration plan (not executed)
- App Group / keychain group: change app, NSE and SE together, plus any Swift constant referencing the group; otherwise the existing database/keys are orphaned and extensions break. Use a fresh install.
- Bundle IDs: must be unique to your Apple team; NSE/SE IDs must be prefixed by the app ID.
- Push: default SimpleX notification servers only serve the official app's APNs topic; Fast-Chat needs its own/self-hosted notification server and APNs key.
- URL scheme `simplex`: keep (invitation links); optionally add `fastchat`.
