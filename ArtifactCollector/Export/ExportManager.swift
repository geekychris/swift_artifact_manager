#if os(macOS)
import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

@MainActor
class ExportManager {
    
    enum ExportFormat {
        case pdf
        case json
        case html
    }
    
    enum ExportError: Error {
        case dataCreationFailed
        case zipCreationFailed
        case fileWriteFailed
    }
    
    // MARK: - Export Collection
    
    func exportCollection(_ collection: ArtifactCollection, format: ExportFormat) throws -> URL {
        switch format {
        case .pdf:
            return try exportPDF(collection: collection)
        case .json:
            return try exportJSON(collection: collection)
        case .html:
            return try exportHTML(collection: collection)
        }
    }
    
    // MARK: - PDF Export
    
    private func exportPDF(collection: ArtifactCollection) throws -> URL {
        let pdfData = generatePDF(for: collection)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(collection.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try pdfData.write(to: fileURL)
        return fileURL
    }
    
    private func generatePDF(for collection: ArtifactCollection) -> Data {
        #if os(macOS)
        return generatePDFMacOS(for: collection)
        #else
        return generatePDFiOS(for: collection)
        #endif
    }
    
    #if os(iOS)
    private func generatePDFiOS(for collection: ArtifactCollection) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Artifact Collector",
            kCGPDFContextTitle: collection.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            
            var yPosition: CGFloat = 50
            let margin: CGFloat = 50
            let contentWidth = pageRect.width - (margin * 2)
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
            let titleString = collection.name as NSString
            titleString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Description
            if let desc = collection.desc {
                let descFont = UIFont.systemFont(ofSize: 12)
                let descAttributes: [NSAttributedString.Key: Any] = [.font: descFont]
                (desc as NSString).draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 100), withAttributes: descAttributes)
                yPosition += 60
            }
            
            // Artifacts
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
            ("Artifacts" as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 30
            
            let bodyFont = UIFont.systemFont(ofSize: 11)
            let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
            
            for artifact in collection.artifacts.sorted(by: { $0.name < $1.name }) {
                // Check if we need a new page
                if yPosition > pageRect.height - 100 {
                    context.beginPage()
                    yPosition = 50
                }
                
                // Artifact name
                let nameFont = UIFont.boldSystemFont(ofSize: 14)
                let nameAttributes: [NSAttributedString.Key: Any] = [.font: nameFont]
                (artifact.name as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: nameAttributes)
                yPosition += 25
                
                // Attributes
                for attr in artifact.attributes.sorted(by: { $0.definitionName < $1.definitionName }) {
                    let attrText = "\(attr.definitionName): \(attr.stringValue ?? attr.numberValue?.description ?? "—")"
                    (attrText as NSString).draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
                
                yPosition += 10
            }
        }
    }
    #endif
    
    #if os(macOS)
    private func generatePDFMacOS(for collection: ArtifactCollection) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Artifact Collector",
            kCGPDFContextTitle: collection.name
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = pageRect
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, pdfMetaData as CFDictionary)!
        
        pdfContext.beginPDFPage(nil)
        
        // Flip coordinate system to match AppKit (top-left origin)
        pdfContext.translateBy(x: 0, y: pageRect.height)
        pdfContext.scaleBy(x: 1.0, y: -1.0)
        
        var yPosition: CGFloat = 50
        let margin: CGFloat = 50
        let contentWidth = pageRect.width - (margin * 2)
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        let titleString = collection.name as NSString
        titleString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
        yPosition += 40
        
        // Description
        if let desc = collection.desc {
            let descFont = NSFont.systemFont(ofSize: 12)
            let descAttributes: [NSAttributedString.Key: Any] = [.font: descFont]
            (desc as NSString).draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: 100), withAttributes: descAttributes)
            yPosition += 60
        }
        
        // Artifacts
        let headerFont = NSFont.boldSystemFont(ofSize: 18)
        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
        ("Artifacts" as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
        yPosition += 30
        
        let bodyFont = NSFont.systemFont(ofSize: 11)
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
        
        for artifact in collection.artifacts.sorted(by: { $0.name < $1.name }) {
            if yPosition > pageRect.height - 100 {
                pdfContext.endPDFPage()
                pdfContext.beginPDFPage(nil)
                pdfContext.translateBy(x: 0, y: pageRect.height)
                pdfContext.scaleBy(x: 1.0, y: -1.0)
                yPosition = 50
            }
            
            let nameFont = NSFont.boldSystemFont(ofSize: 14)
            let nameAttributes: [NSAttributedString.Key: Any] = [.font: nameFont]
            (artifact.name as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: nameAttributes)
            yPosition += 25
            
            for attr in artifact.attributes.sorted(by: { $0.definitionName < $1.definitionName }) {
                let attrText = "\(attr.definitionName): \(attr.stringValue ?? attr.numberValue?.description ?? "—")"
                (attrText as NSString).draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18
            }
            
            yPosition += 10
        }
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        return pdfData as Data
    }
    #endif
    
    // MARK: - JSON Export
    
    private func exportJSON(collection: ArtifactCollection) throws -> URL {
        let jsonData = try generateJSON(for: collection)
        
        // Create temporary directory for export
        let tempDir = FileManager.default.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        // Write JSON
        let jsonURL = exportDir.appendingPathComponent("collection.json")
        try jsonData.write(to: jsonURL)
        
        // Export images
        let imagesDir = exportDir.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        for artifact in collection.artifacts {
            for media in artifact.mediaItems {
                if let thumbnailData = media.thumbnailData {
                    let imageURL = imagesDir.appendingPathComponent("\(media.id.uuidString).jpg")
                    try thumbnailData.write(to: imageURL)
                }
            }
        }
        
        // Create ZIP using ditto (macOS built-in)
        let zipFileName = "\(collection.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).zip"
        let zipURL = tempDir.appendingPathComponent(zipFileName)
        
        try createZip(from: exportDir, to: zipURL)
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: exportDir)
        
        return zipURL
    }
    
    private func generateJSON(for collection: ArtifactCollection) throws -> Data {
        let exportData: [String: Any] = [
            "collection": [
                "name": collection.name,
                "description": collection.desc ?? "",
                "created": ISO8601DateFormatter().string(from: collection.createdDate),
                "modified": ISO8601DateFormatter().string(from: collection.modifiedDate),
                "artifactCount": collection.artifacts.count
            ],
            "artifacts": collection.artifacts.map { artifact in
                [
                    "id": artifact.id.uuidString,
                    "name": artifact.name,
                    "created": ISO8601DateFormatter().string(from: artifact.createdDate),
                    "modified": ISO8601DateFormatter().string(from: artifact.modifiedDate),
                    "attributes": artifact.attributes.map { attr in
                        [
                            "name": attr.definitionName,
                            "value": attr.stringValue ?? attr.numberValue?.description ?? attr.dateValue?.description ?? ""
                        ]
                    },
                    "media": artifact.mediaItems.map { media in
                        [
                            "id": media.id.uuidString,
                            "type": media.type.rawValue,
                            "notes": media.notes ?? "",
                            "filename": "\(media.id.uuidString).jpg"
                        ]
                    }
                ]
            }
        ]
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // MARK: - HTML Export
    
    private func exportHTML(collection: ArtifactCollection) throws -> URL {
        let htmlString = generateHTML(for: collection)
        
        // Create temporary directory for export
        let tempDir = FileManager.default.temporaryDirectory
        let exportDir = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        // Write HTML
        let htmlURL = exportDir.appendingPathComponent("index.html")
        try htmlString.write(to: htmlURL, atomically: true, encoding: .utf8)
        
        // Export images
        let imagesDir = exportDir.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        
        for artifact in collection.artifacts {
            for media in artifact.mediaItems {
                if let thumbnailData = media.thumbnailData {
                    let imageURL = imagesDir.appendingPathComponent("\(media.id.uuidString).jpg")
                    try thumbnailData.write(to: imageURL)
                }
            }
        }
        
        // Create ZIP using ditto (macOS built-in)
        let zipFileName = "\(collection.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).zip"
        let zipURL = tempDir.appendingPathComponent(zipFileName)
        
        try createZip(from: exportDir, to: zipURL)
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: exportDir)
        
        return zipURL
    }
    
    private func generateHTML(for collection: ArtifactCollection) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(collection.name)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
                .container { max-width: 1200px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                h1 { color: #333; margin-bottom: 10px; }
                .description { color: #666; margin-bottom: 30px; }
                .artifact { margin-bottom: 40px; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
                .artifact h2 { margin-top: 0; color: #007AFF; }
                .attributes { margin: 15px 0; }
                .attribute { margin: 5px 0; }
                .attribute-name { font-weight: bold; color: #555; }
                .media-gallery { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 15px; }
                .media-item { width: 150px; }
                .media-item img { width: 100%; border-radius: 5px; }
                .media-notes { font-size: 12px; color: #666; margin-top: 5px; }
                .meta { color: #999; font-size: 12px; margin-top: 20px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>\(collection.name)</h1>
        """
        
        if let desc = collection.desc {
            html += "<p class=\"description\">\(desc)</p>"
        }
        
        html += "<div class=\"meta\">Created: \(collection.createdDate.formatted(date: .long, time: .omitted)) | Artifacts: \(collection.artifacts.count)</div>"
        
        for artifact in collection.artifacts.sorted(by: { $0.name < $1.name }) {
            html += """
                <div class="artifact">
                    <h2>\(artifact.name)</h2>
                    <div class="attributes">
            """
            
            for attr in artifact.attributes.sorted(by: { $0.definitionName < $1.definitionName }) {
                let value = attr.stringValue ?? attr.numberValue?.description ?? attr.dateValue?.description ?? "—"
                html += "<div class=\"attribute\"><span class=\"attribute-name\">\(attr.definitionName):</span> \(value)</div>"
            }
            
            html += "</div>"
            
            if !artifact.mediaItems.isEmpty {
                html += "<div class=\"media-gallery\">"
                for media in artifact.mediaItems {
                    html += """
                        <div class="media-item">
                            <img src="images/\(media.id.uuidString).jpg" alt="Media">
                    """
                    if let notes = media.notes, !notes.isEmpty {
                        html += "<div class=\"media-notes\">\(notes)</div>"
                    }
                    html += "</div>"
                }
                html += "</div>"
            }
            
            html += "</div>"
        }
        
        html += """
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    // MARK: - ZIP Helper
    
    private func createZip(from sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", sourceURL.path, destinationURL.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw ExportError.zipCreationFailed
        }
    }
}
#endif
