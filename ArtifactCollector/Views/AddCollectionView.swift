import SwiftUI
import SwiftData

struct AddCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Collection Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Default Attributes") {
                    Text("The following attributes will be added by default:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(AttributeDefinition.defaultDefinitions()) { def in
                        HStack {
                            Text(def.name)
                            Spacer()
                            Text(def.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Text("You can customize attributes after creating the collection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Collection")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCollection()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 800, idealWidth: 900, minHeight: 700, idealHeight: 800)
        #endif
    }
    
    private func createCollection() {
        let collection = ArtifactCollection(name: name, desc: description.isEmpty ? nil : description)
        modelContext.insert(collection)
        
        // Add default attribute definitions
        let defaultAttrs = AttributeDefinition.defaultDefinitions()
        for attr in defaultAttrs {
            modelContext.insert(attr)
            attr.collection = collection
            collection.attributeDefinitions.append(attr)
        }
        
        try? modelContext.save()
        dismiss()
    }
}
