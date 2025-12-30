import SwiftUI
import SwiftData

// MARK: - Placeholder Views (to be implemented)

struct ArtifactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let artifact: Artifact
    
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var showingImagePicker = false
    @State private var selectedAttributeForEdit: ArtifactAttribute?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Debug info
                Text("DEBUG: Collection = \(artifact.collection?.name ?? "nil")")
                    .font(.caption)
                    .foregroundColor(.orange)
                if let coll = artifact.collection {
                    Text("DEBUG: Attrs count = \(coll.attributeDefinitions.count)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // Header with name and edit button
                HStack {
                    if isEditing {
                        TextField("Name", text: $editedName)
                            .font(.largeTitle)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(artifact.name)
                            .font(.largeTitle)
                            .bold()
                    }
                    
                    Spacer()
                    
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            editedName = artifact.name
                        }
                        isEditing.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Media Gallery
                if !artifact.mediaItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Media")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(artifact.mediaItems.sorted(by: { $0.sortOrder < $1.sortOrder })) { media in
                                    MediaThumbnailView(mediaItem: media)
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // Attributes
                if let collection = artifact.collection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attributes")
                            .font(.headline)
                        
                        if collection.attributeDefinitions.isEmpty {
                            Text("No attributes defined for this collection")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(collection.attributeDefinitions.sorted(by: { $0.sortOrder < $1.sortOrder })) { definition in
                                AttributeRowView(
                                    artifact: artifact,
                                    definition: definition,
                                    isEditing: isEditing
                                )
                            }
                        }
                    }
                    
                    Divider()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attributes")
                            .font(.headline)
                        Text("Error: Artifact not linked to collection")
                            .foregroundStyle(.red)
                            .italic()
                    }
                    
                    Divider()
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Info")
                        .font(.headline)
                    
                    HStack {
                        Text("Created:")
                            .foregroundStyle(.secondary)
                        Text(artifact.createdDate, style: .date)
                        Text(artifact.createdDate, style: .time)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Modified:")
                            .foregroundStyle(.secondary)
                        Text(artifact.modifiedDate, style: .date)
                        Text(artifact.modifiedDate, style: .time)
                    }
                    .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingImagePicker = true }) {
                    Label("Add Media", systemImage: "photo.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            MediaPickerView(artifact: artifact)
        }
    }
    
    private func saveChanges() {
        if !editedName.isEmpty {
            artifact.name = editedName
            artifact.modifiedDate = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Media Thumbnail View

struct MediaThumbnailView: View {
    @Environment(\.modelContext) private var modelContext
    let mediaItem: MediaItem
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail
                if let thumbnailData = mediaItem.thumbnailData {
                    #if os(macOS)
                    if let nsImage = NSImage(data: thumbnailData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    #else
                    if let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    #endif
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: mediaItem.type == .photo ? "photo" : "video")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
                
                // Delete button
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)
                .padding(4)
            }
            .onTapGesture {
                showingEditSheet = true
            }
            
            // Notes preview
            if let notes = mediaItem.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(width: 120)
            } else {
                Text("Tap to add notes")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
                    .frame(width: 120)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            MediaEditView(mediaItem: mediaItem)
        }
        .alert("Delete Media", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMedia()
            }
        } message: {
            Text("Are you sure you want to delete this media item?")
        }
    }
    
    private func deleteMedia() {
        if let artifact = mediaItem.artifact {
            artifact.mediaItems.removeAll { $0.id == mediaItem.id }
            artifact.modifiedDate = Date()
            
            // Update artifact thumbnail if this was the thumbnail
            if artifact.thumbnailData == mediaItem.thumbnailData {
                artifact.thumbnailData = artifact.mediaItems.first?.thumbnailData
            }
        }
        
        modelContext.delete(mediaItem)
        try? modelContext.save()
    }
}

// MARK: - Attribute Row View

struct AttributeRowView: View {
    @Environment(\.modelContext) private var modelContext
    let artifact: Artifact
    let definition: AttributeDefinition
    let isEditing: Bool
    
    @State private var editValue: String = ""
    @State private var editNumberValue: Double = 0
    @State private var editDateValue: Date = Date()
    @State private var editBoolValue: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(definition.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if isEditing {
                editField
            } else {
                displayValue
            }
        }
        .onAppear {
            loadCurrentValue()
        }
    }
    
    @ViewBuilder
    private var editField: some View {
        switch definition.type {
        case .text, .url:
            TextField(definition.name, text: $editValue)
                .textFieldStyle(.roundedBorder)
                .onChange(of: editValue) { _, newValue in
                    updateAttribute(stringValue: newValue)
                }
        case .longText:
            TextEditor(text: $editValue)
                .frame(minHeight: 60)
                .border(Color.gray.opacity(0.3))
                .onChange(of: editValue) { _, newValue in
                    updateAttribute(stringValue: newValue)
                }
        case .number, .currency:
            HStack {
                if definition.type == .currency {
                    Text("$")
                }
                TextField("0", value: $editNumberValue, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: editNumberValue) { _, newValue in
                        updateAttribute(numberValue: newValue)
                    }
            }
        case .date:
            DatePicker("", selection: $editDateValue, displayedComponents: .date)
                .labelsHidden()
                .onChange(of: editDateValue) { _, newValue in
                    updateAttribute(dateValue: newValue)
                }
        case .boolean:
            Toggle("", isOn: $editBoolValue)
                .labelsHidden()
                .onChange(of: editBoolValue) { _, newValue in
                    updateAttribute(boolValue: newValue)
                }
        }
    }
    
    @ViewBuilder
    private var displayValue: some View {
        if let attr = findAttribute() {
            switch definition.type {
            case .text, .longText, .url:
                Text(attr.stringValue ?? "—")
            case .number:
                Text(attr.numberValue.map { "\($0)" } ?? "—")
            case .currency:
                Text(attr.numberValue.map { "$\(String(format: "%.2f", $0))" } ?? "—")
            case .date:
                Text(attr.dateValue.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—")
            case .boolean:
                Text(attr.boolValue == true ? "Yes" : "No")
            }
        } else {
            Text("—")
                .foregroundStyle(.tertiary)
        }
    }
    
    private func findAttribute() -> ArtifactAttribute? {
        artifact.attributes.first { $0.definitionId == definition.id }
    }
    
    private func loadCurrentValue() {
        if let attr = findAttribute() {
            switch definition.type {
            case .text, .longText, .url:
                editValue = attr.stringValue ?? ""
            case .number, .currency:
                editNumberValue = attr.numberValue ?? 0
            case .date:
                editDateValue = attr.dateValue ?? Date()
            case .boolean:
                editBoolValue = attr.boolValue ?? false
            }
        }
    }
    
    private func updateAttribute(stringValue: String? = nil, numberValue: Double? = nil, dateValue: Date? = nil, boolValue: Bool? = nil) {
        var attr = findAttribute()
        
        if attr == nil {
            // Create new attribute
            attr = ArtifactAttribute(definitionId: definition.id, definitionName: definition.name)
            modelContext.insert(attr!)
            artifact.attributes.append(attr!)
        }
        
        // Update value
        if let stringValue = stringValue {
            attr?.stringValue = stringValue
        } else if let numberValue = numberValue {
            attr?.numberValue = numberValue
        } else if let dateValue = dateValue {
            attr?.dateValue = dateValue
        } else if let boolValue = boolValue {
            attr?.boolValue = boolValue
        }
        
        artifact.modifiedDate = Date()
        try? modelContext.save()
    }
}

struct AddArtifactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let collection: ArtifactCollection
    
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Artifact Name", text: $name)
            }
            .navigationTitle("New Artifact")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let artifact = Artifact(name: name)
                        modelContext.insert(artifact)
                        artifact.collection = collection
                        collection.artifacts.append(artifact)
                        collection.modifiedDate = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct CollectionSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var collection: ArtifactCollection
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var showingAddAttribute = false
    @State private var attributeToDelete: AttributeDefinition?
    @State private var showingDeleteAlert = false
    
    init(collection: ArtifactCollection) {
        self.collection = collection
        self._editedName = State(initialValue: collection.name)
        self._editedDescription = State(initialValue: collection.desc ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("DEBUG: Collection = \(collection.name)")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("DEBUG: Attrs count = \(collection.attributeDefinitions.count)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Form {
                        Section("Collection Details") {
                            TextField("Name", text: $editedName)
                            TextField("Description", text: $editedDescription, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        Section {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Created")
                                        .foregroundStyle(.secondary)
                                    Text(collection.createdDate, style: .date)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Modified")
                                        .foregroundStyle(.secondary)
                                    Text(collection.modifiedDate, style: .date)
                                }
                            }
                            .font(.caption)
                        }
                        
                        Section {
                            HStack {
                                Text("Artifacts")
                                Spacer()
                                Text("\(collection.artifacts.count)")
                                    .foregroundStyle(.secondary)
                            }
                            
                            if collection.isShared {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                    Text("Shared Collection")
                                    Spacer()
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        Section {
                            ForEach(collection.attributeDefinitions.sorted(by: { $0.sortOrder < $1.sortOrder })) { attr in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(attr.name)
                                            .font(.body)
                                        Text(attr.type.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if attr.isRequired {
                                        Text("Required")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        attributeToDelete = attr
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            
                            Button(action: { showingAddAttribute = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Attribute")
                                }
                            }
                        } header: {
                            Text("Attributes")
                        } footer: {
                            Text("These attributes will be available for all artifacts in this collection.")
                        }
            }
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            .navigationTitle("Collection Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 800, idealWidth: 900, minHeight: 700, idealHeight: 800)
        #endif
        .sheet(isPresented: $showingAddAttribute) {
            AddAttributeView(collection: collection)
        }
        .alert("Delete Attribute", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let attr = attributeToDelete {
                    deleteAttribute(attr)
                }
            }
        } message: {
            Text("Are you sure you want to delete this attribute? This will remove it from all artifacts in the collection.")
        }
    }
    
    private func saveChanges() {
        collection.name = editedName
        collection.desc = editedDescription.isEmpty ? nil : editedDescription
        collection.modifiedDate = Date()
        try? modelContext.save()
    }
    
    private func deleteAttribute(_ attr: AttributeDefinition) {
        // Remove from all artifacts first
        for artifact in collection.artifacts {
            artifact.attributes.removeAll { $0.definitionId == attr.id }
        }
        
        // Remove from collection
        collection.attributeDefinitions.removeAll { $0.id == attr.id }
        modelContext.delete(attr)
        
        try? modelContext.save()
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("About") {
                Text("Artifact Collector")
                Text("Settings - TO BE IMPLEMENTED")
            }
        }
        .frame(width: 400, height: 300)
    }
}
