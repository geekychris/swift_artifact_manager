import Foundation
import SwiftData
import CloudKit

@MainActor
class ModelContainerManager {
    static let shared = ModelContainerManager()
    
    private(set) var container: ModelContainer!
    
    private init() {}
    
    func setupContainer() throws {
        let schema = Schema([
            ArtifactCollection.self,
            Artifact.self,
            AttributeDefinition.self,
            ArtifactAttribute.self,
            MediaItem.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.artifactcollector.app")
        )
        
        container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    var mainContext: ModelContext {
        container.mainContext
    }
}
