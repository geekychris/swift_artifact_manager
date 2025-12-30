import SwiftUI
import SwiftData

struct MediaEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mediaItem: MediaItem
    
    @State private var notes: String
    @State private var showingFullImage = false
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
        self._notes = State(initialValue: mediaItem.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Large preview
                if let thumbnailData = mediaItem.thumbnailData {
                    #if os(macOS)
                    if let nsImage = NSImage(data: thumbnailData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    #else
                    if let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    #endif
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay {
                            Image(systemName: mediaItem.type == .photo ? "photo" : "video")
                                .font(.system(size: 80))
                                .foregroundStyle(.secondary)
                        }
                }
                
                // Media info
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: mediaItem.type == .photo ? "photo" : "video")
                        Text(mediaItem.type == .photo ? "Photo" : "Video")
                        Spacer()
                        Text(mediaItem.createdDate, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
                
                // Notes editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100, maxHeight: 200)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Edit Media")
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
                        saveNotes()
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }
    
    private func saveNotes() {
        mediaItem.notes = notes.isEmpty ? nil : notes
        
        if let artifact = mediaItem.artifact {
            artifact.modifiedDate = Date()
        }
        
        try? modelContext.save()
    }
}
