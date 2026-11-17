import Foundation
import SwiftData

enum LibraryWorkerError: Error, Equatable {
    case notFound
}

@MainActor
protocol LibraryWorking: AnyObject {
    func all() throws -> [SavedMedia]
    func find(key: String) throws -> SavedMedia?
    func save(_ detail: MediaDetail) throws -> SavedMedia
    func setStatus(_ status: WatchStatus, key: String) throws
    func setRating(_ rating: MediaRating?, key: String) throws
    func remove(key: String) throws
}

@MainActor
final class SwiftDataLibraryWorker: LibraryWorking {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() throws -> [SavedMedia] {
        let descriptor = FetchDescriptor<SavedMedia>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func find(key: String) throws -> SavedMedia? {
        var descriptor = FetchDescriptor<SavedMedia>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func save(_ detail: MediaDetail) throws -> SavedMedia {
        if let existing = try find(key: detail.key) {
            return existing
        }
        let saved = SavedMedia(detail: detail)
        context.insert(saved)
        try context.save()
        return saved
    }

    func setStatus(_ status: WatchStatus, key: String) throws {
        guard let saved = try find(key: key) else { throw LibraryWorkerError.notFound }
        saved.status = status
        try context.save()
    }

    func setRating(_ rating: MediaRating?, key: String) throws {
        guard let saved = try find(key: key) else { throw LibraryWorkerError.notFound }
        saved.rating = rating
        try context.save()
    }

    func remove(key: String) throws {
        guard let saved = try find(key: key) else { throw LibraryWorkerError.notFound }
        context.delete(saved)
        try context.save()
    }
}
