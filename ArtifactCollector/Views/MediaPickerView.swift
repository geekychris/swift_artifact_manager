import SwiftUI
import SwiftData
import PhotosUI

struct MediaPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let artifact: Artifact
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isProcessing {
                    ProgressView("Adding media...")
                        .padding()
                } else {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .any(of: [.images, .videos])
                    ) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            
                            Text("Select Photos or Videos")
                                .font(.headline)
                            
                            Text("Choose up to 10 items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .onChange(of: selectedItems) { _, items in
                        Task {
                            await processSelectedItems(items)
                        }
                    }
                    .padding()
                }
                
                if !selectedItems.isEmpty {
                    Text("Selected: \(selectedItems.count) items")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .navigationTitle("Add Media")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }
    
    private func processSelectedItems(_ items: [PhotosPickerItem]) async {
        isProcessing = true
        
        for (index, item) in items.enumerated() {
            // Determine media type
            let mediaType: MediaType = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) ? .video : .photo
            
            // Load data
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Create media item
                let sortOrder = (artifact.mediaItems.map { $0.sortOrder }.max() ?? -1) + index + 1
                let mediaItem = MediaItem(
                    type: mediaType,
                    fileName: "media_\(UUID().uuidString)",
                    fileExtension: mediaType == .photo ? "jpg" : "mov",
                    sortOrder: sortOrder
                )
                
                // Generate thumbnail
                if mediaType == .photo {
                    #if os(macOS)
                    if let image = NSImage(data: data) {
                        mediaItem.thumbnailData = generateThumbnail(from: image)
                    }
                    #else
                    if let image = UIImage(data: data) {
                        mediaItem.thumbnailData = generateThumbnail(from: image)
                    }
                    #endif
                }
                
                // Save to local storage (in a real app, you'd save the full file)
                // For now, we'll just store the thumbnail
                
                modelContext.insert(mediaItem)
                artifact.mediaItems.append(mediaItem)
                
                // Update artifact thumbnail if it doesn't have one
                if artifact.thumbnailData == nil && mediaItem.thumbnailData != nil {
                    artifact.thumbnailData = mediaItem.thumbnailData
                }
            }
        }
        
        artifact.modifiedDate = Date()
        try? modelContext.save()
        
        isProcessing = false
        selectedItems = []
    }
    
    #if os(macOS)
    private func generateThumbnail(from image: NSImage) -> Data? {
        let targetSize = CGSize(width: 200, height: 200)
        let thumbnail = NSImage(size: targetSize)
        
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()
        
        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let data = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return nil
        }
        
        return data
    }
    #else
    private func generateThumbnail(from image: UIImage) -> Data? {
        let targetSize = CGSize(width: 200, height: 200)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail?.jpegData(compressionQuality: 0.8)
    }
    #endif
}
