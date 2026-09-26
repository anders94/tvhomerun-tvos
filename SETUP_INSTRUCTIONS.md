# Setup

## Build and run

1. Open `TVHomeRun/TVHomeRun.xcodeproj` in Xcode 26 or later.
2. Select the `TVHomeRun` target → Signing & Capabilities → choose your team.
3. Pick an Apple TV simulator or a paired Apple TV and press Run.

The project uses a synchronized source folder, so new `.swift` files under `TVHomeRun/TVHomeRun/` join the target automatically.

## First launch

Enter the URL of your tvhomerun-backend server, including the port (for example `http://192.168.1.100:3000`), and press Connect. The app saves the URL once `/health` responds with `"status": "ok"`. You can change it later in the Settings tab.

## Simulator tips

- Arrow keys move focus, Return selects, Esc is Menu.
- Hold Return on an episode to open its context menu.
- ⌘⇧R shows the on-screen remote.

## Troubleshooting

- **Unable to connect**: confirm the backend is running and reachable from the Apple TV's network. Prefer an IP address over `localhost`, which points at the Apple TV itself.
- **Video won't play**: check that the backend's `play_url` and HLS playlists are reachable from the device.
- **Stale data after changing the server**: switch tabs; each tab reloads when it next appears.
