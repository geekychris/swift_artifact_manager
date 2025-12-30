import SwiftUI
import SwiftData

@main
struct ArtifactCollectorApp: App {
    // CloudKit sharing manager - disabled for now until entitlements are properly configured
    // @StateObject private var cloudKitManager = CloudKitSharingManager()
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Create schema
            let schema = Schema([
                ArtifactCollection.self,
                Artifact.self,
                AttributeDefinition.self,
                ArtifactAttribute.self,
                MediaItem.self
            ])
            
            // Configure model container - start with local-only storage
            // CloudKit sync can be enabled later in settings
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // .environmentObject(cloudKitManager)
        }
        .modelContainer(modelContainer)
        
        #if os(macOS)
        // Additional Mac-specific windows for advanced features
        Settings {
            SettingsView()
        }
        #endif
    }
}
