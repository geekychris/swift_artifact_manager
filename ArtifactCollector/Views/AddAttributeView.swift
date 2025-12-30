import SwiftUI
import SwiftData

struct AddAttributeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let collection: ArtifactCollection
    
    @State private var name = ""
    @State private var selectedType: AttributeType = .text
    @State private var isRequired = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Attribute Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        Text("Text").tag(AttributeType.text)
                        Text("Long Text").tag(AttributeType.longText)
                        Text("Number").tag(AttributeType.number)
                        Text("Currency").tag(AttributeType.currency)
                        Text("Date").tag(AttributeType.date)
                        Text("Yes/No").tag(AttributeType.boolean)
                        Text("URL").tag(AttributeType.url)
                    }
                    
                    Toggle("Required", isOn: $isRequired)
                }
                
                Section {
                    Text("This attribute will be available for all artifacts in the collection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Attribute")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAttribute()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
    
    private func addAttribute() {
        let sortOrder = (collection.attributeDefinitions.map { $0.sortOrder }.max() ?? -1) + 1
        let attribute = AttributeDefinition(
            name: name,
            type: selectedType,
            isRequired: isRequired,
            sortOrder: sortOrder
        )
        
        modelContext.insert(attribute)
        collection.attributeDefinitions.append(attribute)
        collection.modifiedDate = Date()
        
        try? modelContext.save()
        dismiss()
    }
}
