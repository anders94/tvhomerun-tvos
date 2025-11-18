# TV HomeRun - AppleTV Application

A SwiftUI-based AppleTV application for streaming video content from a local network server.

## Features

- 🎯 Server URL configuration with persistence
- 📺 Browse shows with thumbnails and metadata
- 🎬 Episode list with progress indicators and watch status
- ▶️ Custom video player with:
  - Resume playback from last position
  - Skip forward 30 seconds
  - Skip backward 15 seconds
  - Scrubbing controls
  - Episode navigation (next/previous)
- 🔄 Exponential backoff for network errors
- 💾 Automatic URL persistence
- 🎨 Beautiful tvOS-optimized UI

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

The application expects the following API endpoints:

- `GET /health` - Health check
  - Returns: `{"status":"ok","timestamp":"...","uptime":123,...}`

- `GET /api/shows` - List all shows
  - Returns: `{"shows":[...],"count":19}`

- `GET /api/shows/:id/episodes` - List episodes for a show
  - Returns: `{"episodes":[...],"count":23,"show":{...}}`

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

- **Select/Touch Surface**: Show/hide controls, select items
- **Play/Pause**: Toggle playback
- **Menu**: Navigate back
- **Swipe Left/Right**: Navigate through episodes
- The app automatically maps the forward button to +30s skip and backward button to -15s skip

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

- Resume position sync with server (server support needed)
- Mark episodes as watched (server support needed)
- Search functionality
- Filtering by category
- Parental controls
- Multi-user profiles

## License

Created for TV HomeRun project.
