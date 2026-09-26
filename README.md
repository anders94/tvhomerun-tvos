# TVHomeRun for tvOS

A SwiftUI Apple TV client for [tvhomerun-backend](https://github.com/anders94/tvhomerun-backend). Watch live TV from your HDHomeRun, browse the program guide, schedule series recordings, and play back recorded shows with resume and progress tracking.

The app never talks to HDHomeRun hardware directly. It speaks plain HTTP/JSON to the backend, which handles tuner discovery, DVR control, and HLS transcoding.

## Features

The app is organised as four standard tvOS tabs.

**Recordings**
- Grid of recorded shows with artwork, category, and episode count.
- Show page with a season sidebar on the left and that season's episodes on the right. The latest season is selected on entry; shows without season numbers get a flat list instead. Episodes without a season sit under a "Specials" entry.
- Sort menu: seasons latest-first or earliest-first, episodes newest-first or oldest-first. Preferences persist across launches.
- Long-press an episode for Mark as Watched / Unwatched, Delete, and Delete and Allow Re-record (each delete asks for confirmation).
- Record Series toggle creates or removes the DVR series rule.
- Progress bar and watched badge on each episode, updated in place when you return from playback.

**Live TV**
- Channel lineup sorted numerically by guide number (2.1 before 11.1 before 115), with what's on now.
- Select a channel to watch; the app holds the tuner with a heartbeat and releases it when you leave.

**Guide**
- Upcoming programs grouped by series, searchable, with a recording indicator on series that have a rule.
- Series page lists upcoming airings in order and offers the same Record Series toggle.

**Settings**
- Server URL with a live connection check, plus the app version.

**Playback**
- System `AVPlayerViewController` transport controls (scrub, skip, play/pause, info).
- Resumes from the saved position, saves progress every 30 seconds and on exit, marks the episode watched at the end, and auto-plays the next episode in the order shown on the show page.

## Requirements

- tvOS 26 or later (Apple TV 4K)
- Xcode 26 or later
- A reachable tvhomerun-backend server on your network

## Getting Started

1. Open `TVHomeRun/TVHomeRun.xcodeproj`.
2. Select your development team under Signing & Capabilities.
3. Run on an Apple TV simulator or device.
4. On first launch, enter the backend URL (for example `http://192.168.1.100:3000`) and press Connect. The URL is saved once the server's health check passes.

The app allows arbitrary HTTP loads so it can reach a LAN server without TLS.

## Project Structure

```
TVHomeRun/TVHomeRun/
├── TVHomeRunApp.swift           App entry point
├── ContentView.swift            Launch: health probe → setup or main tabs
├── Models/                      Codable models: Show, Episode, Channel, Guide, RecordingRule, Health
├── Services/APIClient.swift     Backend client with exponential backoff
├── Utilities/
│   ├── UserSettings.swift       Server URL persistence
│   └── EpisodeSorting.swift     Season grouping and date ordering
└── Views/
    ├── MainTabView.swift        Recordings / Live TV / Guide / Settings tabs
    ├── ShowsListView.swift      Recordings grid
    ├── ShowDetailView.swift     Season sidebar, episode list, sort, context menu
    ├── SeasonSidebar.swift
    ├── EpisodeSortMenu.swift
    ├── EpisodeRow.swift
    ├── LiveChannelsView.swift   Live TV lineup
    ├── GuideView.swift          Guide grid and search
    ├── GuideDetailView.swift    Upcoming airings for a series
    ├── SettingsView.swift
    ├── ServerSetupView.swift    First-run screen
    ├── ServerConnectionForm.swift
    ├── VideoPlayerView.swift + VideoPlayerViewModel.swift
    ├── LiveVideoPlayerView.swift + LiveVideoPlayerViewModel.swift
    └── Components/              RemoteImage, CardSurface, RecordSeriesToggle,
                                 NativeVideoPlayer, PreviewData
```

Source files live in a synchronized folder, so adding a file on disk adds it to the target.

## Backend Endpoints Used

| Purpose | Endpoint |
|---|---|
| Health check | `GET /health` |
| Recorded shows | `GET /api/shows` |
| Episodes of a show | `GET /api/shows/{id}/episodes` |
| Save progress / watched | `PUT /api/episodes/{id}/progress` |
| Delete a recording | `DELETE /api/episodes/{id}?rerecord=true\|false` |
| Program guide | `GET /api/guide` |
| What's on now | `GET /api/guide/now` |
| Series recording rules | `GET /api/recording-rules`, `POST /api/recording-rules`, `DELETE /api/recording-rules/{id}` |
| Live channel lineup | `GET /api/live/channels` |
| Live tuner lease | `POST /api/live/watch`, `POST /api/live/heartbeat`, `POST /api/live/stop` |

## Remote Control

- **Tab bar**: swipe up from the top of any tab, or press Menu at a tab's root.
- **Select**: open a show, play an episode or channel, activate a control.
- **Long-press Select** on an episode: Mark as Watched / Unwatched, Delete, Delete and Allow Re-record.
- **Menu**: go back; during playback, return to the list.
- **Left / Right** on a show page: move between the season sidebar and the episode list. Moving up and down in the sidebar changes the season.

## Technical Notes

- Requests retry with 1s, 2s, 4s backoff (capped at 5s). A connection alert appears after roughly five seconds of failures. `DELETE` requests are never retried.
- Sort order uses the recording time, falling back to original air date, then scheduled start; episode number breaks ties.
- Server URL and sort preferences are stored in `UserDefaults`.
- Because episodes default to newest-first, auto-play at the end of an episode advances to the next row shown, which is the older recording. Switch the sort to oldest-first for chronological binge order.
