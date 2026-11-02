# Plong - iOS and watchOS app

SwiftUI app for crowd-overflow dispatch. A **manager** sees crowd counts per zone and
delegates extra staff to an overflowing zone. **Staff** receive the task as a push,
accept it, and validate when the overflow is cleared. One app, routed by role after
login. Backend: [elven-plong-be](https://github.com/jonathanbasuki/elven-plong-be).

```text
CCTV --RTSP--> MediaMTX --HLS--> iPhone (live preview)
                  |
                  +--RTSP--> YOLO worker --counts--> FastAPI + Postgres <--REST + polling--> iPhone
                                                          |
                                                          +--APNs--> iPhone (and mirrored to Watch)
```

## Branches (read this first)

The FE has two branches that grew apart. Which one becomes the base is decided at the
**Monday 2 Nov contract meeting** (sprint task TK007). Until then:

| Branch | What it has | Use it for |
|---|---|---|
| `dev/lofi-ui-poc` | Real networking: `APIClient`, Keychain, refresh token, push registration, HLS player. Flat files. | Running against the real backend |
| `lofifullvibe` | Features / Domain / Data structure, repository protocol with a mock, `PlongTests`. No networking. | Screen structure and mock data |
| `main` | Initial project setup only | Nothing yet |

The plan on the table: keep `lofifullvibe`'s structure and port `dev/lofi-ui-poc`'s
networking into a `LiveCrowdFlowRepository`. This README is written against
`dev/lofi-ui-poc` and gets updated once the base is chosen.

### Branch flow from Monday

Same flow as the backend:

```text
dev/<short-topic>  --PR-->  development  --Friday merge-->  main
```

- Branch from `development`, for example `dev/overview-map` or `dev/validation-sheet`.
- One PR per task. The PR template asks which acceptance criteria it covers.
- Code freeze is **Thursday 18:00**. Friday is merge, QA and review only.
- `development` does not exist in this repo yet. It is created from the chosen base on Monday.

## Requirements

- Xcode 27.1 or later. Deployment targets are **iOS 27.0** and **watchOS 27.0**, so test devices must run iOS 27.
- Membership in the team's Apple Developer account, for signing on a device.
- A physical iPhone for push notifications. The Simulator cannot receive real APNs pushes.

## Setup

```bash
git clone https://github.com/jonathanbasuki/elven-plong-fe.git
cd elven-plong-fe
git checkout dev/lofi-ui-poc
open Plong.xcodeproj
```

**Signing:** select the `Plong` target > Signing & Capabilities and pick your team.
The iOS and Watch targets currently have different `DEVELOPMENT_TEAM` values. Do not
commit a change to your personal team; it shows up as a `project.pbxproj` diff.

Run the `Plong` scheme. By default the app talks to the live backend at
`https://api.plong.my.id`.

## Run against a backend on your Mac

1. Start the backend: see the backend README, "Quickstart for iOS developers".
2. In Xcode: **Product > Scheme > Edit Scheme > Run > Arguments**.
3. Tick the environment variables you need:

| Variable | Default (off) value | Meaning |
|---|---|---|
| `PLONG_API_BASE_URL` | `http://127.0.0.1:8080` | Backend API |
| `PLONG_HLS_URL` | `http://127.0.0.1:8888/cam1/index.m3u8` | MediaMTX live preview (only if a camera is running) |

- **Simulator:** `127.0.0.1` works as is.
- **Physical iPhone:** replace `127.0.0.1` with your Mac's LAN IP (`ipconfig getifaddr en0`), with both on the same Wi-Fi. Plain `http` on the local network is allowed by `NSAllowsLocalNetworking` in `Info.plist`.
- Ticking a variable changes the shared scheme file. Untick before you commit, or keep the change out of your PR.
- The variables only apply when Xcode launches the app. Archive and TestFlight builds always use the live server. The logic is in `Plong/AppConfig.swift`.

## Test logins

From the backend's `scripts/seed_dispatch.py` (local backend only). All share the
password `password123`.

| Email | Role |
|---|---|
| `manager@plongelven.io` | Manager (`ops_manager`) |
| `bunga@plongelven.io`, `citra@plongelven.io`, `dedi@plongelven.io` | Staff (`floor_staff`) |

Accounts on the live server are managed by the backend team.

## Simulate an overflow without real crowds

Open the backend's dev page at `http://127.0.0.1:8080/ui/default` > **Dev Tools**, and
post a count for a zone. That drives Safe / Warning / Crowded in the app. Stop the
camera worker first, or it overwrites your value within about a second.

## Push notifications

- Physical iPhone only. The app asks for permission after login, then sends its device token to `POST /api/v1/auth/push-token`.
- Xcode builds use the APNs **sandbox** (`aps-environment = development` in `Plong.entitlements`), so the backend needs `APNS_USE_SANDBOX=true` and an APNs key. See `docs/PUSH_NOTIFICATIONS.md` in the backend repo.
- Logout clears the token on the backend, so a logged-out phone stops getting pushes.
- One token per user: logging in on a second phone replaces the first.
- Apple Watch: standard notifications mirror to a paired Watch automatically. Watch work is planned for the 9-13 Nov sprint.

## Project layout (`dev/lofi-ui-poc`)

```text
Plong/
├── PlongApp.swift           # App entry, wires the push AppDelegate
├── AppConfig.swift          # API / HLS base URL, overridable per scheme
├── APIClient.swift          # REST calls, models, Session (tokens, refresh, logout)
├── Keychain.swift           # Token storage
├── PushNotifications.swift  # Permission prompt, APNs token registration
├── LoginView.swift
├── ContentView.swift        # Role routing, manager and staff screens
├── Info.plist, Plong.entitlements
Plong Watch App/             # Placeholder
```

## Rules for this project

- **API contract:** the backend's `docs/DISPATCH_API.md` is the source of truth. The
  `crowd-broadcast-contract/` folder on `lofifullvibe` is an older POC copy.
- **Polling, not websockets.** Standard push, not Critical Alert.
- **Accessibility from the first line** (Apple requires at least 2 accessibility
  features; VoiceOver is one): use system text styles instead of fixed font sizes,
  give every control and custom element an accessibility label (including map pins),
  and never show a status by color alone.
- **Spec-driven development:** the sprint spec (`specs/SPEC.md`) arrives on Monday.
  Doc comments on public types say which acceptance criterion they cover, for
  example `/// Covers AC3`.

## Cleanup when merging `lofifullvibe`

`lofifullvibe` has personal and system files committed and no `.gitignore`. When it is
merged, keep this branch's `.gitignore` and untrack them:

```bash
git rm -r --cached .DS_Store Plong.xcodeproj/project.xcworkspace/xcuserdata Plong.xcodeproj/xcuserdata
```
