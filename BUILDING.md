# Building MenuBarStats

This document provides detailed instructions for building MenuBarStats from source.

## Prerequisites

- **macOS 13.0 or later**: This is required both for building and running the application
- **Xcode 15.0 or later**: Available from the Mac App Store or Apple Developer website
- **Xcode Command Line Tools**: Usually installed with Xcode, but can be installed separately

### Installing Xcode Command Line Tools

If you don't have Xcode installed, you can install just the command line tools:

```bash
xcode-select --install
```

## Building with Xcode (Recommended)

This is the easiest method for most users.

### Step 1: Clone the Repository

```bash
git clone https://github.com/olivertemple/menubar_stats.git
cd menubar_stats
```

### Step 2: Open in Xcode

```bash
open MenuBarStats.xcodeproj
```

Or double-click `MenuBarStats.xcodeproj` in Finder.

### Step 3: Select Build Configuration

1. In Xcode, select the "MenuBarStats" scheme from the scheme dropdown (top-left, next to the play/stop buttons)
2. Select "My Mac" as the destination

### Step 4: Build and Run

- To build and run immediately: Press `⌘R` or click the Play button
- To build only: Press `⌘B` or select Product > Build from the menu

The app will launch and appear in your menu bar.

## Building from Command Line

If you prefer to build without opening Xcode:

### Using the Build Script

```bash
./build.sh
```

This will:
1. Check for required tools
2. Build the Release configuration
3. Place the built app in `./build/Build/Products/Release/`

### Using xcodebuild Directly

```bash
xcodebuild \
    -project MenuBarStats.xcodeproj \
    -scheme MenuBarStats \
    -configuration Release \
    build
```

The built application will be in:
```
./build/Build/Products/Release/MenuBarStats.app
```

## Installing the Built Application

### Option 1: Copy to Applications folder

```bash
cp -r ./build/Build/Products/Release/MenuBarStats.app /Applications/
```

Then launch from Spotlight or Applications folder.

### Option 2: Run directly

```bash
open ./build/Build/Products/Release/MenuBarStats.app
```

## Troubleshooting

### "MenuBarStats can't be opened because Apple cannot check it for malicious software"

This happens because the app is not signed with a Developer ID. To run it:

1. Right-click (or Control-click) the app icon
2. Select "Open" from the menu
3. Click "Open" in the dialog that appears

Alternatively, you can allow it in System Settings:
1. Go to System Settings > Privacy & Security
2. Scroll down to find the blocked app
3. Click "Open Anyway"

### Build Errors

**"Signing for MenuBarStats requires a development team"**

Solution: In Xcode, go to the project settings:
1. Select the MenuBarStats project in the navigator
2. Select the MenuBarStats target
3. Go to "Signing & Capabilities" tab
4. Either:
   - Select your Apple ID team from the dropdown, or
   - Uncheck "Automatically manage signing" and select "Sign to Run Locally"

**"Could not find developer disk image"**

Solution: Update Xcode to the latest version that supports your macOS version.

### Code Signing for Distribution

If you want to distribute the app to others, you'll need:

1. An Apple Developer account ($99/year)
2. A Developer ID certificate
3. Notarization through Apple

Steps:
1. Configure signing in Xcode with your Developer ID
2. Build a Release version
3. Sign the app:
   ```bash
   codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" MenuBarStats.app
   ```
4. Notarize with Apple:
   ```bash
   xcrun notarytool submit MenuBarStats.app.zip --apple-id your@email.com --team-id TEAMID --wait
   ```
5. Staple the notarization:
   ```bash
   xcrun stapler staple MenuBarStats.app
   ```

## Development Build vs Release Build

### Development Build
- Includes debug symbols
- Larger file size
- Better for debugging
- Built with: `-configuration Debug`

### Release Build
- Optimized for performance
- Smaller file size
- No debug symbols
- Built with: `-configuration Release`

## Build Configurations

The project includes two build configurations:

1. **Debug**: For development and testing
2. **Release**: For distribution

You can switch between them in Xcode by selecting Edit Scheme > Run > Build Configuration.

## Clean Build

If you encounter build issues, try cleaning:

### In Xcode:
Product > Clean Build Folder (⇧⌘K)

### From Command Line:
```bash
xcodebuild clean -project MenuBarStats.xcodeproj -scheme MenuBarStats
rm -rf ./build
```

## Architecture Support

MenuBarStats is built as a universal binary supporting:
- Apple Silicon (arm64)
- Intel Macs (x86_64)

The build system automatically creates a universal binary that runs on both architectures.

## Minimum Deployment Target

- macOS 13.0 (Ventura)

This can be changed in the project settings if you need to support older versions, but some features may need adjustment.

## Additional Notes

### App Sandbox

The app is built with App Sandbox **disabled** (`com.apple.security.app-sandbox = false`) to allow access to system information and network monitoring capabilities.

### Entitlements

The app requires the following entitlements:
- `com.apple.security.network.client`: For network monitoring

These are configured in `MenuBarStats.entitlements`.

### LSUIElement

The app is configured as a menu bar-only application (no dock icon) through the `LSUIElement` key in `Info.plist`. If you want a dock icon, change this to `NO`.

## Build Time

Expected build times (approximate):
- Clean build: 30-60 seconds
- Incremental build: 5-15 seconds

Times vary based on your Mac's specifications.

## Support

If you encounter any build issues not covered here, please open an issue on the GitHub repository with:
- Your macOS version
- Your Xcode version
- The complete error message
- Any relevant build logs
