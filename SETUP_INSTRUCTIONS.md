# TV HomeRun - Detailed Setup Instructions

## Quick Start

Follow these steps to create and run the TV HomeRun AppleTV application:

### Step 1: Open Xcode

1. Launch **Xcode** on your Mac
2. Select **"Create a new Xcode project"** from the welcome screen (or File → New → Project)

### Step 2: Choose Template

1. In the template chooser, select the **tvOS** tab at the top
2. Select **App** template
3. Click **Next**

### Step 3: Configure Project

Fill in the following details:
- **Product Name**: `TVHomeRun`
- **Team**: Select your development team (or leave as None for simulator)
- **Organization Identifier**: Use your reverse domain (e.g., `com.yourname`)
- **Interface**: **SwiftUI** (important!)
- **Language**: **Swift** (important!)
- **Storage**: None
- Uncheck "Include Tests" (optional)

Click **Next**

### Step 4: Save Project

1. Navigate to: `/Users/anders/Documents/src/tivo-appletv/`
2. **Important**: Save it as `TVHomeRun` (it should sit alongside the existing TVHomeRun folder)
3. Click **Create**

Your folder structure should now look like:
```
tivo-appletv/
├── TVHomeRun/              <- The source files (already created)
│   ├── TVHomeRun/
│   ├── Info.plist
│   └── README.md
└── TVHomeRun/              <- The Xcode project (you just created)
    └── TVHomeRun.xcodeproj
```

### Step 5: Remove Default Files

Xcode created some default files we don't need:

1. In the Project Navigator (left sidebar), find and **delete** these files:
   - `ContentView.swift` (the default one Xcode created)
   - `Assets.xcassets` (optional, we'll add it back if needed)

2. When prompted, choose **"Move to Trash"**

### Step 6: Add Source Files

1. In the Project Navigator, **right-click** on the `TVHomeRun` folder (the blue one with the app icon)
2. Select **"Add Files to 'TVHomeRun'..."**
3. Navigate up one level and select the **entire `TVHomeRun` source folder** (the one with Models, Views, Services, etc.)
4. **Important settings in the dialog**:
   - ✅ Check "Copy items if needed"
   - Select "Create groups" (should be selected by default)
   - Under "Add to targets", make sure **TVHomeRun** is checked
5. Click **Add**

### Step 7: Configure Info.plist

1. In Project Navigator, click on the **TVHomeRun project** (the very top item)
2. Select the **TVHomeRun target**
3. Go to the **Info** tab
4. Find **"App Transport Security Settings"** or add it:
   - Click the **+** button next to "Custom tvOS Target Properties"
   - Type "App Transport Security Settings"
   - Expand it and add:
     - **Allow Arbitrary Loads**: YES

   Or simply replace the auto-generated Info.plist with our provided one.

### Step 8: Add Assets Catalog (Optional but Recommended)

1. Right-click on the TVHomeRun group in Project Navigator
2. Select **New File...**
3. Choose **Asset Catalog**
4. Name it `Assets.xcassets`
5. Click **Create**

### Step 9: Build and Run

1. Select the **AppleTV Simulator** from the device menu at the top (any tvOS device works)
2. Click the **Play button** (▶️) or press **⌘R**
3. Wait for the build to complete
4. The app should launch in the AppleTV simulator!

### Step 10: Configure Server URL

1. When the app launches, you'll see the server setup screen
2. Enter your server URL (default test server: `http://localhost:3000`)
3. Press **Accept** to connect
4. Browse your shows and enjoy!

## Troubleshooting

### Build Errors

**"Cannot find 'Show' in scope"** or similar errors:
- Make sure you added all the source files correctly
- Check that files are in the correct folders (Models, Views, Services)
- Clean build folder: Product → Clean Build Folder (⇧⌘K)

**Info.plist errors**:
- Make sure the Info.plist includes the `NSAppTransportSecurity` settings
- This allows HTTP connections to local servers

### Runtime Errors

**"Cannot connect to server"**:
- Make sure your test server is running at `http://localhost:3000`
- Check that the `/health` endpoint returns a valid response
- Try using the actual IP address instead of localhost

**Video won't play**:
- Check that the `play_url` in the API response is accessible
- Verify the video format is supported by AVPlayer (MPEG, MP4, etc.)
- Check network connectivity

### Simulator Issues

**App crashes on launch**:
- Reset the simulator: Device → Erase All Content and Settings
- Quit Xcode and simulator, then reopen
- Clean build folder and rebuild

**Can't select items with trackpad**:
- Click and hold to simulate the touch surface on the AppleTV remote
- Or use the on-screen remote: Window → Show Remote (if available)

## Alternative: Manual Project File

If you prefer not to create the project manually, you can create a basic `.xcodeproj` structure. However, the method above is more reliable and ensures proper configuration.

## Testing with Local Server

Make sure your test server is running:

```bash
# Terminal 1 - Start your server
cd /path/to/your/server
npm start  # or however you start your server

# Terminal 2 - Test the endpoints
curl http://localhost:3000/health
curl http://localhost:3000/api/shows
```

The server should return valid JSON responses matching the format in the README.

## Next Steps

Once the app is running:

1. Test the server URL configuration
2. Browse through the shows list
3. Select a show and view episodes
4. Play an episode and test:
   - Play/pause
   - Skip forward (+30s)
   - Skip backward (-15s)
   - Progress bar
   - Next/previous episode navigation

## Getting Help

If you encounter issues:

1. Check the Xcode console for error messages
2. Verify all source files are included in the target
3. Ensure the Info.plist is configured correctly
4. Test API endpoints manually with curl
5. Try cleaning and rebuilding the project

## File Checklist

Make sure these files are in your project:

**Models** (3 files):
- ✅ Show.swift
- ✅ Episode.swift
- ✅ Health.swift

**Services** (1 file):
- ✅ APIClient.swift

**Utilities** (1 file):
- ✅ UserSettings.swift

**Views** (5 files):
- ✅ ServerSetupView.swift
- ✅ ShowsListView.swift
- ✅ EpisodesListView.swift
- ✅ VideoPlayerView.swift
- ✅ VideoPlayerViewModel.swift

**Root** (2 files):
- ✅ TVHomeRunApp.swift
- ✅ ContentView.swift

**Total**: 12 Swift files + Info.plist

Enjoy your TV HomeRun app! 🎉
