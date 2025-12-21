# TV HomeRun - tvOS

A SwiftUI-based TV management and streaming client for AppleTV that connects to a server running [tvhomerun-backend](https://github.com/anders94/tvhomerun-backend). Watch live TV, manage your DVR schedule, and browse recorded content—all from your iPhone or iPad.

## Features

### Live TV & Recording Management
- **Watch Live TV** with seamless channel switching and program information
- **Browse and search the program guide** to discover what's on now and coming up
- **Schedule recordings** directly from the guide or show pages
- **Manage your recording schedule** - add, modify, or cancel recordings on the fly
- **Quick recording controls** from episode views for immediate scheduling

### Content Library & Playback
- **Browse your recorded shows** with rich thumbnails and metadata
- **Episode library** with progress indicators and watch status tracking
- **Advanced video player** featuring:
  - Resume playback from last position
  - Skip forward 30 seconds / Skip backward 15 seconds
  - Precise scrubbing controls
  - Automatic episode navigation (next/previous)
  - Auto-play next episode when current episode ends

### Technical Excellence
- **Server URL configuration** with automatic persistence
- **Intelligent error handling** with exponential backoff for network resilience
- **Beautiful tvOS-optimized UI** following Apple's design guidelines
- **Reliable performance** with efficient API communication

## Project Setup

### Option 1: Create Project in Xcode (Recommended)

1. **Open Xcode** and select "Create a new Xcode project"
2. Choose **tvOS** → **App** template
3. Configure the project:
   - Product Name: `TVHomeRun`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Save location: Choose the parent directory of this folder
4. **Delete** the default files Xcode creates:
   - `ContentView.swift` (if different from ours)
   - Any other default files
5. **Add all source files** from the `TVHomeRun` folder to your project:
   - Right-click on the project in the navigator
   - Select "Add Files to TVHomeRun..."
   - Select the entire `TVHomeRun` folder
   - Check "Copy items if needed"
   - Click "Add"
6. **Replace Info.plist** with the provided one (or merge the `NSAppTransportSecurity` settings)
7. **Build and Run** on AppleTV Simulator or device

### Option 2: Manual Project File Creation

If you prefer, I can generate a complete `.xcodeproj` file structure for you.

## Project Structure

```
TVHomeRun/
├── TVHomeRun/
│   ├── Models/
│   │   ├── Show.swift          # Show data model
│   │   ├── Episode.swift       # Episode data model
│   │   └── Health.swift        # Health check model
│   ├── Services/
│   │   └── APIClient.swift     # Network client with error handling
│   ├── Utilities/
│   │   └── UserSettings.swift  # UserDefaults wrapper
│   ├── Views/
│   │   ├── ServerSetupView.swift       # URL configuration
│   │   ├── ShowsListView.swift         # Shows grid
│   │   ├── EpisodesListView.swift      # Episodes list
│   │   ├── VideoPlayerView.swift       # Custom player UI
│   │   └── VideoPlayerViewModel.swift  # Player logic
│   ├── TVHomeRunApp.swift    # App entry point
│   └── ContentView.swift       # Root navigation
├── Info.plist
└── README.md
```

## API Endpoints

The application integrates with the following backend endpoints:

### System
- `GET /health` - Health check
  - Returns: `{"status":"ok","timestamp":"...","uptime":123,...}`

### Content Library
- `GET /api/shows` - List all recorded shows
  - Returns: `{"shows":[...],"count":19}`

- `GET /api/shows/:id/episodes` - List episodes for a show
  - Returns: `{"episodes":[...],"count":23,"show":{...}}`

### Live TV & Guide
- `GET /api/channels` - List available channels
- `GET /api/guide` - Retrieve program guide data
- `GET /api/guide/search` - Search the program guide
- `GET /api/live/:channelId` - Stream live TV from a channel

### Recording Management
- `GET /api/recordings` - List scheduled recordings
- `POST /api/recordings` - Schedule a new recording
- `PUT /api/recordings/:id` - Modify an existing recording
- `DELETE /api/recordings/:id` - Cancel a scheduled recording

## Configuration

### Server URL

On first launch, the app will prompt for the server URL. The default action is "Accept" which validates the URL and connects to the server.

Example URLs:
- `http://192.168.1.100:3000`
- `http://localhost:3000`
- `http://homerun.local:3000`

### Network Security

The app includes `NSAppTransportSecurity` settings to allow HTTP connections to local servers. For production use, consider using HTTPS.

## Remote Control Mapping

### During Playback
- **Select/Touch Surface**: Show/hide player controls
- **Play/Pause**: Toggle playback
- **Menu**: Exit player and return to previous screen
- **Swipe Left/Right**: Navigate through episodes (recorded content) or channels (live TV)
- **Skip Forward**: Jump ahead 30 seconds
- **Skip Backward**: Jump back 15 seconds

### Navigation
- **Select/Touch Surface**: Select items, activate buttons
- **Swipe**: Navigate through content grids and lists
- **Menu**: Navigate back to previous screen

## Technical Details

### Error Handling

- Exponential backoff with 1s, 2s, 4s intervals (max 5s)
- User notification after 5 seconds of retry attempts
- Graceful degradation on network errors

### Video Playback

- Uses AVPlayer for video streaming
- Supports HTTP streaming protocols
- Auto-resume from last playback position
- Auto-play next episode when current episode ends

### Data Persistence

- Server URL saved to UserDefaults
- Persists between app launches
- Editable from the shows list via settings gear icon

## Development

Built with:
- SwiftUI
- AVKit/AVFoundation
- Combine
- URLSession

Target:
- tvOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Testing

A test server is expected to be running at `http://localhost:3000` during development. The server should implement the API endpoints listed above.

## Future Enhancements

- Resume position sync with server
- Mark episodes as watched
- Content filtering by category and genre
- Series recording management (season passes)
- Picture-in-picture support for tvOS
- Parental controls
- Multi-user profiles with personalized recommendations
- Cloud DVR integration
- Conflict detection and resolution for overlapping recordings

## License

Created for TV HomeRun project.
