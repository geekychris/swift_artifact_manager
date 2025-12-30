import Foundation
import CloudKit
import SwiftData

@MainActor
class CloudKitSharingManager: ObservableObject {
    @Published var shareError: Error?
    @Published var pendingShare: CKShare?
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    init() {
        self.container = CKContainer(identifier: "iCloud.com.artifactcollector.app")
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
    }
    
    // MARK: - Sharing Collections
    
    func createShare(for collection: ArtifactCollection) async throws -> CKShare {
        // Create a CKShare for the collection
        let share = CKShare(rootRecord: try await fetchRecord(for: collection))
        share[CKShare.SystemFieldKey.title] = collection.name as CKRecordValue
        share.publicPermission = .none // Private sharing only
        
        try await privateDatabase.save(share)
        
        // Store share reference in collection
        collection.cloudKitShareRecord = try NSKeyedArchiver.archivedData(
            withRootObject: share.recordID,
            requiringSecureCoding: true
        )
        collection.isShared = true
        
        return share
    }
    
    func addParticipant(email: String, to share: CKShare, permission: CKShare.ParticipantPermission) async throws {
        let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: email)
        
        // Discover user identity using modern async/await API
        let userIdentity = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKUserIdentity, Error>) in
            container.discoverUserIdentity(withEmailAddress: email) { identity, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let identity = identity {
                    continuation.resume(returning: identity)
                } else {
                    continuation.resume(throwing: NSError(domain: "CloudKitSharingManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user identity found"]))
                }
            }
        }
        
        // Note: CKShare.Participant is created by CloudKit when adding to share
        // We cannot create participants directly - this needs to be done through CloudKit sharing UI
        // For now, this is a placeholder for the full implementation
        
        // TODO: Implement proper sharing using UICloudSharingController or NSCloudSharingServiceDelegate
    }
    
    func removeShare(from collection: ArtifactCollection) async throws {
        guard let shareData = collection.cloudKitShareRecord,
              let shareRecordID = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKRecord.ID.self,
                from: shareData
              ) else {
            return
        }
        
        try await privateDatabase.deleteRecord(withID: shareRecordID)
        collection.cloudKitShareRecord = nil
        collection.isShared = false
    }
    
    // MARK: - Helper Methods
    
    private func fetchRecord(for collection: ArtifactCollection) async throws -> CKRecord {
        // This is a simplified version - in reality you'd need to map SwiftData models to CKRecords
        // SwiftData with CloudKit integration handles this automatically in most cases
        let recordID = CKRecord.ID(recordName: collection.id.uuidString)
        return try await privateDatabase.record(for: recordID)
    }
}
