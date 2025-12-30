import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ArtifactCollection.modifiedDate, order: .reverse) private var collections: [ArtifactCollection]
    
    @State private var selectedCollection: ArtifactCollection? {
        didSet {
            print("DEBUG ContentView: selectedCollection changed to \(selectedCollection?.name ?? "nil")")
        }
    }
    @State private var selectedArtifact: Artifact? {
        didSet {
            print("DEBUG ContentView: selectedArtifact changed to \(selectedArtifact?.name ?? "nil")")
        }
    }
    @State private var showingAddCollection = false
    @State private var searchText = ""
    @State private var showingExport = false
    @State private var collectionToExport: ArtifactCollection?
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView(columnVisibility: .constant(.all)) {
            collectionsList
        } content: {
            if let collection = selectedCollection {
                ArtifactListView(collection: collection, selectedArtifact: $selectedArtifact)
            } else {
                Text("Select a collection")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            if let artifact = selectedArtifact {
                NavigationStack {
                    ArtifactDetailView(artifact: artifact)
                        .navigationTitle(artifact.name)
                }
            } else {
                Text("Select an artifact")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Artifact Collector")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingAddCollection = true }) {
                        Label("New Collection", systemImage: "plus")
                    }
                    
                    #if os(macOS)
                    if selectedCollection != nil {
                        Divider()
                        
                        Button(action: {
                            collectionToExport = selectedCollection
                            showingExport = true
                        }) {
                            Label("Export Collection", systemImage: "square.and.arrow.up")
                        }
                    }
                    #endif
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        // Present sheets at the top level to avoid List-related sheet issues on macOS
        .sheet(isPresented: $showingAddCollection) {
            AddCollectionView()
        }
        #if os(macOS)
        .popover(isPresented: $showingExport, arrowEdge: .bottom) {
            if let collection = collectionToExport {
                ExportView(collection: collection)
            }
        }
        #endif
        #else
        NavigationStack {
            List {
                ForEach(filteredCollections) { collection in
                    NavigationLink(value: collection) {
                        CollectionRowView(collection: collection)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteCollection(collection)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search collections")
            .navigationTitle("Collections")
            .navigationDestination(for: ArtifactCollection.self) { collection in
                ArtifactListView(collection: collection, selectedArtifact: .constant(nil))
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddCollection = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCollection) {
            AddCollectionView()
        }
        #endif
    }
    
    private var collectionsList: some View {
        List(selection: $selectedCollection) {
            ForEach(filteredCollections) { collection in
                NavigationLink(value: collection) {
                    CollectionRowView(collection: collection)
                }
                .contextMenu {
                    Button(role: .destructive, action: {
                        deleteCollection(collection)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteCollection(collection)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        #if !os(macOS)
        .searchable(text: $searchText, prompt: "Search collections")
        #endif
    }
    
    private var filteredCollections: [ArtifactCollection] {
        if searchText.isEmpty {
            return collections
        }
        return collections.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func deleteCollection(_ collection: ArtifactCollection) {
        withAnimation {
            modelContext.delete(collection)
            try? modelContext.save()
        }
    }
}

struct CollectionRowView: View {
    let collection: ArtifactCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(collection.name)
                    .font(.headline)
                if collection.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let desc = collection.desc, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Text("\(collection.artifacts.count) items")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
