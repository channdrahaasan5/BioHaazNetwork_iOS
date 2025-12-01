# BioHaazNetwork iOS SDK - Installation Guide

## Method 1: Swift Package Manager (Recommended)

### Step 1: Add Package Dependency
1. In Xcode, go to **File → Add Packages...**
2. Enter the repository URL: `https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git`
3. Select version: `1.0.4` or later
4. Click **Add Package**

### Step 2: Import and Use
```swift
import BioHaazNetwork

// Initialize the SDK
let config = BioHaazNetworkConfig(
    baseURL: "https://api.example.com",
    debug: true
)

BioHaazNetworkManager.shared.initialize(config: config)
```

**Alternative: Via Package.swift**
```swift
dependencies: [
    .package(url: "https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git", from: "1.0.4")
]
```

## Method 2: Manual Installation (.framework)

### Step 1: Download the Framework
1. Go to the [Releases](https://github.com/channdrahaasan5/BioHaazNetwork_iOS/releases) page
2. Download `BioHaazNetwork-v1.0.4.framework.zip`
3. Extract the zip file

### Step 2: Add to Xcode Project
1. Open your Xcode project
2. Right-click on your project in the Navigator
3. Select "Add Files to [ProjectName]"
4. Navigate to the extracted `BioHaazNetwork.framework`
5. Make sure "Copy items if needed" is checked
6. Select your target and click "Add"

### Step 3: Configure Build Settings
1. Select your project in the Navigator
2. Go to your target's "Build Phases"
3. Expand "Embed Frameworks"
4. Verify `BioHaazNetwork.framework` is listed
5. If not, click "+" and add it

### Step 4: Import and Use
```swift
import BioHaazNetwork

// Initialize the SDK
let config = BioHaazNetworkConfig(
    baseURL: "https://api.example.com",
    debug: true
)

BioHaazNetworkManager.shared.initialize(config: config)
```

## Troubleshooting

### Common Issues

#### 1. "Module not found" error
- Make sure the framework is added to "Embedded Binaries"
- Clean and rebuild your project (Cmd+Shift+K, then Cmd+B)

#### 2. "Code signing" error
- Make sure the framework is added to "Embedded Binaries"
- Check your code signing settings

#### 3. Background processing not working
- Verify `UIBackgroundModes` is added to Info.plist
- Check that the app has background app refresh permission

#### 4. Notifications not showing
- Make sure to request notification permissions in your app
- Check that `offlineNotificationService` is enabled in config

### Minimum Requirements
- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

### Supported Architectures
- arm64 (iOS devices - physical devices only)

## Support
If you encounter any issues during installation, please:
1. Check this troubleshooting guide
2. Create an issue on GitHub
3. Contact support@biohaaz.com




