<p align="center">
  <img src="assets/logo.png" alt="Swift Artifact Manager logo" width="180">
</p>

# Artifact Collector

A multi-platform Swift app for managing collections of artifacts (computers, stamps, motorcycles, etc.) with photos/videos, flexible attributes, and iCloud syncing.

## Features

### Core Features
- ✅ Multiple collections support
- ✅ Flexible artifact attributes (customizable per collection)
- ✅ Unlimited photos and videos per artifact
- ✅ Notes on both artifacts and individual images
- ✅ Default attributes: Date Acquired, Cost, Current Value, Manufacturer, Notes
- ✅ Additional custom key-value pairs per artifact
- ⏳ Search and filtering across collections
- ⏳ Export to JSON, PDF, and HTML (with images in zip)

### Platform Support
- iOS (iPhone)
- iPadOS (iPad)
- macOS (Mac)

### Cloud Features
- ✅ Local persistence with SwiftData
- ⏳ iCloud sync via CloudKit (to be enabled)
- ⏳ Shared collections (family/friends sharing)

## Architecture

### Data Models
- **ArtifactCollection**: Top-level container for artifacts
- **Artifact**: Individual items with flexible attributes
- **AttributeDefinition**: Schema for collection-specific fields
- **ArtifactAttribute**: Actual values for each artifact
- **MediaItem**: Photos/videos with notes

### Technology Stack
- SwiftUI for UI
- SwiftData for local persistence
- CloudKit for sync and sharing
- Platform-conditional compilation for device-specific features

## Project Structure

```
ArtifactCollector/
├── Models/
│   ├── Models.swift              # Core data models
│   └── ModelContainer.swift      # SwiftData configuration
├── Views/
│   ├── ContentView.swift         # Main navigation
│   ├── AddCollectionView.swift   # Collection creation
│   ├── ArtifactListView.swift    # Artifact browsing
│   └── StubViews.swift           # Placeholder views
├── CloudKit/
│   └── CloudKitSharingManager.swift  # Sharing logic
└── ArtifactCollectorApp.swift    # App entry point
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- macOS 14.0+ / iOS 17.0+ / iPadOS 17.0+
- Apple Developer account (for CloudKit)

### Opening the Project

The Xcode project has been generated using [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is ready to use.

1. Open the project:
   ```bash
   open ArtifactCollector.xcodeproj
   ```

2. Configure signing:
   - Select the project in Xcode
   - Choose a target (ArtifactCollector_iOS or ArtifactCollector_macOS)
   - Go to "Signing & Capabilities"
   - Select your development team
   - Update the bundle identifier if needed

3. CloudKit is already configured with entitlements:
   - Container ID: `iCloud.com.artifactcollector.app`
   - You'll need to create this container in your Apple Developer account
   - Or update the container ID in `project.yml` and regenerate with `xcodegen generate`

### Regenerating the Project

If you modify `project.yml`, regenerate the Xcode project:
```bash
xcodegen generate
```

## Development Roadmap

### Phase 1: Core Functionality ✅ (Current)
- [x] Data models
- [x] Basic UI structure
- [x] Collection management
- [x] Artifact listing

### Phase 2: Artifact Details
- [ ] Full artifact detail view
- [ ] Media gallery with photos/videos
- [ ] Attribute editing
- [ ] Custom key-value pairs UI

### Phase 3: Media Management
- [ ] Photo capture/import
- [ ] Video recording/import
- [ ] Thumbnail generation
- [ ] Media notes editing

### Phase 4: Search & Filter
- [ ] Full-text search
- [ ] Attribute-based filtering
- [ ] Cross-collection search
- [ ] Saved searches

### Phase 5: Export
- [ ] JSON export
- [ ] PDF generation
- [ ] HTML export with styling
- [ ] Zip packaging with images

### Phase 6: CloudKit Integration
- [ ] Basic sync setup
- [ ] Conflict resolution
- [ ] Shared database support
- [ ] Collection sharing UI
- [ ] Participant management

### Phase 7: Platform-Specific Features
- [ ] Mac: Advanced export options
- [ ] Mac: Batch operations
- [ ] Mac: Keyboard shortcuts
- [ ] iOS/iPad: Camera integration
- [ ] iPad: Split view optimization

## Configuration

### CloudKit Container
Update the container identifier in:
- `ModelContainer.swift`
- `CloudKitSharingManager.swift`
- Xcode project capabilities

Replace `iCloud.com.artifactcollector.app` with your actual container ID.

## License

TBD

## Notes

This is an initial scaffold. Many features are marked as "TO BE IMPLEMENTED" and will be built incrementally.
