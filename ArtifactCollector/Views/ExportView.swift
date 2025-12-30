import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    let collection: ArtifactCollection
    
    @State private var selectedFormat: ExportManager.ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportError: Error?
    @State private var showingError = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        Form {
            Section {
                Text("Export Collection: \(collection.name)")
                    .font(.headline)
            }
            
            Section("Export Format") {
                Picker("Format", selection: $selectedFormat) {
                    Text("PDF Document").tag(ExportManager.ExportFormat.pdf)
                    Text("JSON Archive (ZIP)").tag(ExportManager.ExportFormat.json)
                    Text("HTML Archive (ZIP)").tag(ExportManager.ExportFormat.html)
                }
                .pickerStyle(.radioGroup)
            }
            
            Section {
                if isExporting {
                    HStack {
                        ProgressView()
                        Text("Exporting...")
                    }
                } else {
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            dismiss()
                        }
                        Button("Export") {
                            performExport()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .frame(width: 500, height: 350)
        .fixedSize()
        .alert("Export Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportError?.localizedDescription ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheetMac(url: url)
            }
        }
    }
    
    private func formatName(_ format: ExportManager.ExportFormat) -> String {
        switch format {
        case .pdf: return "PDF Document"
        case .json: return "JSON Archive"
        case .html: return "HTML Archive"
        }
    }
    
    private func formatDescription(_ format: ExportManager.ExportFormat) -> String {
        switch format {
        case .pdf: return "Single PDF file with all artifact details"
        case .json: return "ZIP file with JSON data and images"
        case .html: return "ZIP file with HTML page and images"
        }
    }
    
    private func formatIcon(_ format: ExportManager.ExportFormat) -> String {
        switch format {
        case .pdf: return "doc.fill"
        case .json: return "doc.zipper"
        case .html: return "doc.zipper"
        }
    }
    
    private func performExport() {
        isExporting = true
        
        Task {
            do {
                let exportManager = ExportManager()
                let fileURL = try exportManager.exportCollection(collection, format: selectedFormat)
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    showingShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showingError = true
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Share Sheets

struct ShareSheetMac: View {

    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Export Complete!")
                .font(.title)
            
            Text(url.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 15) {
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}
#endif
