import Foundation
import SwiftData
import CloudKit

// MARK: - Collection Model
@Model
final class ArtifactCollection {
    var id: UUID
    var name: String
    var desc: String?
    var createdDate: Date
    var modifiedDate: Date
    var colorHex: String?
    var isShared: Bool
    var cloudKitShareRecord: Data?
    
    @Relationship(deleteRule: .cascade) var attributeDefinitions: [AttributeDefinition]
    @Relationship(deleteRule: .cascade) var artifacts: [Artifact]
    
    init(name: String, desc: String? = nil) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.isShared = false
        self.attributeDefinitions = []
        self.artifacts = []
    }
}

extension ArtifactCollection: Hashable {
    static func == (lhs: ArtifactCollection, rhs: ArtifactCollection) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Attribute Definition
@Model
final class AttributeDefinition {
    var id: UUID
    var name: String
    var type: AttributeType
    var isRequired: Bool
    var sortOrder: Int
    
    @Relationship(inverse: \ArtifactCollection.attributeDefinitions) var collection: ArtifactCollection?
    
    init(name: String, type: AttributeType, isRequired: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.sortOrder = sortOrder
    }
    
    static func defaultDefinitions() -> [AttributeDefinition] {
        return [
            AttributeDefinition(name: "Date Acquired", type: .date, sortOrder: 0),
            AttributeDefinition(name: "Cost", type: .currency, sortOrder: 1),
            AttributeDefinition(name: "Current Value", type: .currency, sortOrder: 2),
            AttributeDefinition(name: "Manufacturer", type: .text, sortOrder: 3),
            AttributeDefinition(name: "Notes", type: .longText, sortOrder: 4)
        ]
    }
}

enum AttributeType: String, Codable {
    case text
    case longText
    case number
    case currency
    case date
    case boolean
    case url
}

// MARK: - Artifact Model
@Model
final class Artifact {
    var id: UUID
    var name: String
    var createdDate: Date
    var modifiedDate: Date
    var thumbnailData: Data?
    
    @Relationship(inverse: \ArtifactCollection.artifacts) var collection: ArtifactCollection?
    @Relationship(deleteRule: .cascade) var attributes: [ArtifactAttribute]
    @Relationship(deleteRule: .cascade) var mediaItems: [MediaItem]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.attributes = []
        self.mediaItems = []
    }
}

extension Artifact: Hashable {
    static func == (lhs: Artifact, rhs: Artifact) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Artifact Attribute
@Model
final class ArtifactAttribute {
    var id: UUID
    var definitionId: UUID
    var definitionName: String // Cached for performance
    var stringValue: String?
    var numberValue: Double?
    var dateValue: Date?
    var boolValue: Bool?
    
    @Relationship(inverse: \Artifact.attributes) var artifact: Artifact?
    
    init(definitionId: UUID, definitionName: String) {
        self.id = UUID()
        self.definitionId = definitionId
        self.definitionName = definitionName
    }
    
    func setValue(_ value: Any, for type: AttributeType) {
        switch type {
        case .text, .longText, .url:
            stringValue = value as? String
        case .number, .currency:
            numberValue = value as? Double
        case .date:
            dateValue = value as? Date
        case .boolean:
            boolValue = value as? Bool
        }
    }
    
    func getValue(for type: AttributeType) -> Any? {
        switch type {
        case .text, .longText, .url:
            return stringValue
        case .number, .currency:
            return numberValue
        case .date:
            return dateValue
        case .boolean:
            return boolValue
        }
    }
}

// MARK: - Media Item Model
@Model
final class MediaItem {
    var id: UUID
    var type: MediaType
    var fileName: String
    var fileExtension: String
    var createdDate: Date
    var notes: String?
    var sortOrder: Int
    
    // Media data - stored locally and synced to CloudKit
    var thumbnailData: Data?
    var fileURL: URL? // Local file reference
    var cloudAssetID: String? // CloudKit CKAsset reference
    
    @Relationship(inverse: \Artifact.mediaItems) var artifact: Artifact?
    
    init(type: MediaType, fileName: String, fileExtension: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.type = type
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.createdDate = Date()
        self.sortOrder = sortOrder
    }
}

enum MediaType: String, Codable {
    case photo
    case video
}
