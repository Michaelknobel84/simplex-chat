#!/usr/bin/env python3
"""Source-level consistency checks for Fast-Chat iOS configuration (runs on Linux/macOS, no Xcode needed).

Usage: python3 fast-chat/scripts/check_config.py
Exit code 0 = all checks passed.
"""
import plistlib, re, sys
from pathlib import Path

IOS = Path(__file__).resolve().parents[2] / "apps" / "ios"
fails, passes = [], []

def check(ok, msg):
    (passes if ok else fails).append(msg)

def xcconfig(path, seen=None):
    out = {}
    for line in (IOS / path).read_text().splitlines():
        line = line.split("//")[0].strip()
        m = re.match(r"#include\??\s+\"(.+)\"", line)
        if m:
            if (IOS / m.group(1)).exists():
                out.update(xcconfig(m.group(1)))
        elif "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    return out

def expand(v, env, depth=0):
    def sub(m):
        return env.get(m.group(1), m.group(0))
    for _ in range(10):
        n = re.sub(r"\$\(([A-Za-z0-9_]+)\)", sub, v)
        if n == v: break
        v = n
    return v

env = {}
for cfg in ("Debug.xcconfig", "Release.xcconfig"):
    env = xcconfig(cfg)
    for k in ("FASTCHAT_APP_ID", "FASTCHAT_APP_GROUP", "FASTCHAT_DEVELOPMENT_TEAM"):
        check(k in env, f"{cfg}: {k} defined")
env["AppIdentifierPrefix"] = "TEAMID1234."  # stand-in for the Xcode-provided value
app_id = expand(env.get("FASTCHAT_APP_ID", ""), env)
group = expand(env.get("FASTCHAT_APP_GROUP", ""), env)
check(re.fullmatch(r"[A-Za-z0-9.-]+", app_id) is not None, f"app ID resolves to valid value: {app_id!r}")
check(re.fullmatch(r"group\.[A-Za-z0-9.-]+", group) is not None, f"app group resolves to valid value: {group!r}")

plists = {"app": "SimpleX--iOS--Info.plist", "NSE": "SimpleX NSE/Info.plist", "SE": "SimpleX SE/Info.plist"}
ents = {"app": "SimpleX (iOS).entitlements", "NSE": "SimpleX NSE/SimpleX NSE.entitlements", "SE": "SimpleX SE/SimpleX SE.entitlements"}
resolved = {}
for t, p in plists.items():
    d = plistlib.loads((IOS / p).read_bytes())
    g, k = d.get("FastChatAppGroup"), d.get("FastChatKeychainAccessGroup")
    check(bool(g) and bool(k), f"{t} Info.plist has nonempty FastChatAppGroup and FastChatKeychainAccessGroup")
    rg, rk = expand(g or "", env), expand(k or "", env)
    check("$" not in rg and "$" not in rk, f"{t} Info.plist values resolve with xcconfig variables ({rg!r}, {rk!r})")
    resolved[t] = (rg, rk)
for t, p in ents.items():
    d = plistlib.loads((IOS / p).read_bytes())
    eg = [expand(x, env) for x in d.get("com.apple.security.application-groups", [])]
    ek = [expand(x, env) for x in d.get("keychain-access-groups", [])]
    check(eg == [resolved[t][0]], f"{t} entitlements App Group equals Info.plist value ({eg})")
    check(ek == [resolved[t][1]], f"{t} entitlements keychain group equals Info.plist value ({ek})")
    check(all("$" not in x for x in eg + ek), f"{t} entitlements fully resolve")
check(len(set(resolved.values())) == 1, "app, NSE and SE use identical App Group and Keychain group")
check("$(FASTCHAT_APP_ID)" in plistlib.loads((IOS / plists["app"]).read_bytes())["BGTaskSchedulerPermittedIdentifiers"][0],
      "BGTask identifier derives from FASTCHAT_APP_ID")

pbx = (IOS / "SimpleX.xcodeproj/project.pbxproj").read_text()
ids = set(re.findall(r"PRODUCT_BUNDLE_IDENTIFIER = (.+);", pbx))
check(all("FASTCHAT_APP_ID" in i for i in ids), f"all bundle IDs use FASTCHAT_APP_ID: {sorted(ids)}")
check("5NN7GUYB6T" not in pbx, "no upstream DEVELOPMENT_TEAM in pbxproj")
check(len(re.findall(r'DEVELOPMENT_TEAM = "\$\(FASTCHAT_DEVELOPMENT_TEAM\)"', pbx)) == len(re.findall(r"DEVELOPMENT_TEAM =", pbx)),
      "all DEVELOPMENT_TEAM entries use FASTCHAT_DEVELOPMENT_TEAM")
check('INFOPLIST_KEY_CFBundleDisplayName = "Fast-Chat"' in pbx, "main app display name is Fast-Chat")

# no silent upstream fallback in Swift sources
for f in ("SimpleXChat/AppGroup.swift", "SimpleXChat/KeyChain.swift"):
    src = (IOS / f).read_text()
    check("group.chat.simplex.app" not in src and "5NN7GUYB6T" not in src, f"{f}: no upstream identifier fallback")
check("APP_GROUP_NAME)!" not in (IOS / "SimpleXChat/FileUtils.swift").read_text(), "FileUtils: no force-unwrapped group container")

def lum(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    c = [x / 12.92 if x <= .03928 else ((x + .055) / 1.055) ** 2.4 for x in c]
    return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]
def ratio(a, b):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + .05) / (y + .05)
theme = (IOS / "SimpleXChat/Theme/ThemeTypes.swift").read_text()
dark = theme[theme.index("public let DarkColorPalette = "):theme.index("public let LightColorPalette")]
sec = re.search(r"secondary: Color\(0xFF([0-9A-Fa-f]{6})\)", dark).group(1)
for name, bg in (("outgoing", "444850"), ("incoming", "33363C"), ("background", "111215"), ("surface", "202227")):
    r = ratio(sec, bg)
    check(r >= 4.5, f"secondary text #{sec} on {name} #{bg}: {r:.2f}:1 (>= 4.5)")

for m in passes: print("PASS", m)
for m in fails: print("FAIL", m)
print(f"{len(passes)} passed, {len(fails)} failed")
sys.exit(1 if fails else 0)
