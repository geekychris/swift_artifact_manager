import SwiftUI
import SwiftData

struct ArtifactListView: View {
    @Environment(\.modelContext) private var modelContext
    let collection: ArtifactCollection
    @Binding var selectedArtifact: Artifact?
    
    @State private var searchText = ""
    @State private var showingAddArtifact = false
    @State private var showingCollectionSettings = false
    
    var body: some View {
        artifactList
            .searchable(text: $searchText, prompt: "Search artifacts")
            .navigationTitle(collection.name)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingAddArtifact) {
                AddArtifactView(collection: collection)
            }
            .sheet(isPresented: $showingCollectionSettings) {
                CollectionSettingsView(collection: collection)
            }
    }
    
    @ViewBuilder
    private var artifactList: some View {
        #if os(macOS)
        List(selection: $selectedArtifact) {
            ForEach(filteredArtifacts) { artifact in
                ArtifactRowView(artifact: artifact)
                    .tag(artifact)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteArtifact(artifact)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        #else
        List(selection: $selectedArtifact) {
            ForEach(filteredArtifacts) { artifact in
                NavigationLink(value: artifact) {
                    ArtifactRowView(artifact: artifact)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteArtifact(artifact)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationDestination(for: Artifact.self) { artifact in
            ArtifactDetailView(artifact: artifact)
        }
        #endif
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(macOS)
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: { showingAddArtifact = true }) {
                    Label("Add Artifact", systemImage: "plus")
                }
                Button(action: { showingCollectionSettings = true }) {
                    Label("Collection Settings", systemImage: "gearshape")
                }
                Divider()
                Button(action: { shareCollection() }) {
                    Label("Share Collection", systemImage: "square.and.arrow.up")
                }
            } label: {
                Label("Actions", systemImage: "ellipsis.circle")
            }
        }
        #else
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showingAddArtifact = true }) {
                Label("Add Artifact", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button(action: { showingCollectionSettings = true }) {
                Label("Settings", systemImage: "gearshape")
            }
        }
        #endif
    }
    
    private var filteredArtifacts: [Artifact] {
        let artifacts = collection.artifacts
        if searchText.isEmpty {
            return artifacts.sorted { $0.modifiedDate > $1.modifiedDate }
        }
        return artifacts.filter { artifact in
            artifact.name.localizedCaseInsensitiveContains(searchText) ||
            artifact.attributes.contains { attr in
                attr.stringValue?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    private func deleteArtifact(_ artifact: Artifact) {
        withAnimation {
            modelContext.delete(artifact)
            try? modelContext.save()
        }
    }
    
    private func shareCollection() {
        // TODO: Implement CloudKit sharing
    }
}

struct ArtifactRowView: View {
    let artifact: Artifact
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailData = artifact.thumbnailData {
                #if os(macOS)
                if let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                #else
                if let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                #endif
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artifact.name)
                    .font(.headline)
                
                if !artifact.mediaItems.isEmpty {
                    Text("\(artifact.mediaItems.count) media items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(artifact.modifiedDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
