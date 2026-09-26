# TVHomeRun for tvOS — Project Summary

A SwiftUI tvOS 26 client for tvhomerun-backend. No third-party dependencies.

## Architecture

- `ContentView` probes the saved server's `/health` and shows either the first-run `ServerSetupView` or `MainTabView`.
- `MainTabView` owns the single `APIClient` and presents four tabs, each in its own `NavigationStack`: Recordings, Live TV, Guide, Settings. One shared alert reports connection errors.
- Screens hold their own `@State` and load in `.task(id: apiClient.baseURL)`, so changing the server in Settings reloads every tab on its next visit.
- `APIClient` is a `@MainActor ObservableObject` wrapping `URLSession` with exponential backoff.
- Playback wraps `AVPlayerViewController` (`NativeVideoPlayer`). `VideoPlayerViewModel` handles resume, 30-second progress saves, mark-as-watched and auto-next; `LiveVideoPlayerViewModel` handles the tuner lease and heartbeat.

## Recordings model

- `Show` is a recorded series; `Episode` is one recording. `Episode.seasonNumber` and `episodeNum` are optional.
- `EpisodeSorting.swift` groups episodes into `SeasonGroup`s (nil when nothing has a season) and sorts by `sortTimestamp` (record time → air date → start time).
- `ShowDetailView` keeps the server list as the source of truth and derives the displayed, sorted slice from the selected `SeasonKey`, so in-place refreshes never reorder rows unexpectedly.

## Conventions

- Standard controls only: `TabView`/`Tab`, `NavigationLink(value:)`, `.buttonStyle(.card)` for focusable content, `.contextMenu` for item actions, `.alert` for confirmation, `Menu` + `Picker` for sort, `Form` for settings, `ContentUnavailableView` for empty states.
- tvOS text styles and semantic colors; one shared card surface (`cardSurface()`), one image loader (`RemoteImage`).
- No `DispatchQueue` focus hacks. Focus is driven by `@FocusState`, `.focusSection()` and `.defaultFocus`.
- Live channels sort with `Channel.compareGuideNumbers`, a numeric major.minor comparison.

## Docs

- `README.md` — features, setup, endpoints, remote mapping.
- `SETUP_INSTRUCTIONS.md` — build and run.
