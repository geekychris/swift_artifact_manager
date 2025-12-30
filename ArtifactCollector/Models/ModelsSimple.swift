import Foundation
import SwiftData

// Minimal test models to verify SwiftData works

@Model
final class TestCollection {
    var id: UUID
    var name: String
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
