import SwiftData
import XCTest
@testable import Teely

@MainActor
final class SwiftDataLibraryWorkerTests: XCTestCase {
    private var container: ModelContainer!
    private var worker: SwiftDataLibraryWorker!

    override func setUpWithError() throws {
        container = try makeInMemoryContainer()
        worker = SwiftDataLibraryWorker(context: container.mainContext)
    }

    func testStartsEmpty() throws {
        XCTAssertTrue(try worker.all().isEmpty)
    }

    func testSaveStartsWithNoWatchStatus() throws {
        let saved = try worker.save(Sample.detail())
        XCTAssertNil(saved.status)
        XCTAssertEqual(try worker.all().count, 1)
        XCTAssertNotNil(try worker.find(key: "movie-101"))
    }

    func testLegacyImplicitWantToWatchStatusIsUnselected() {
        let saved = SavedMedia(detail: Sample.detail(), addedAt: Date(timeIntervalSince1970: 100))
        saved.statusRaw = WatchStatus.wantToWatch.rawValue
        saved.statusChangedAt = saved.addedAt
        XCTAssertNil(saved.status)
    }

    func testExplicitWantToWatchStatusRemainsSelected() {
        let saved = SavedMedia(detail: Sample.detail(), status: .wantToWatch)
        XCTAssertEqual(saved.status, .wantToWatch)
    }

    func testSavingTwiceDoesNotDuplicate() throws {
        _ = try worker.save(Sample.detail())
        _ = try worker.save(Sample.detail())
        XCTAssertEqual(try worker.all().count, 1)
    }

    func testMovieAndSeriesWithSameIdentifierAreDistinct() throws {
        _ = try worker.save(Sample.detail(id: 5, kind: .movie))
        _ = try worker.save(Sample.detail(id: 5, kind: .tv))
        XCTAssertEqual(try worker.all().count, 2)
    }

    func testAllIsSortedByNewestFirst() throws {
        let older = SavedMedia(detail: Sample.detail(id: 1, title: "Older"), addedAt: Date(timeIntervalSince1970: 100))
        let newer = SavedMedia(detail: Sample.detail(id: 2, title: "Newer"), addedAt: Date(timeIntervalSince1970: 200))
        container.mainContext.insert(older)
        container.mainContext.insert(newer)
        try container.mainContext.save()
        XCTAssertEqual(try worker.all().map(\.title), ["Newer", "Older"])
    }

    func testSetStatusAndRating() throws {
        _ = try worker.save(Sample.detail())
        try worker.setStatus(.watched, key: "movie-101")
        try worker.setRating(.liked, key: "movie-101")
        let saved = try XCTUnwrap(try worker.find(key: "movie-101"))
        XCTAssertEqual(saved.status, .watched)
        XCTAssertEqual(saved.rating, .liked)
    }

    func testReturningToWantToWatchClearsRating() throws {
        _ = try worker.save(Sample.detail())
        try worker.setStatus(.watched, key: "movie-101")
        try worker.setRating(.disliked, key: "movie-101")
        try worker.setStatus(.wantToWatch, key: "movie-101")
        XCTAssertNil(try XCTUnwrap(try worker.find(key: "movie-101")).rating)
    }

    func testRemove() throws {
        _ = try worker.save(Sample.detail())
        try worker.remove(key: "movie-101")
        XCTAssertTrue(try worker.all().isEmpty)
    }

    func testOperationsOnMissingKeyThrow() {
        XCTAssertThrowsError(try worker.setStatus(.watched, key: "movie-1")) {
            XCTAssertEqual($0 as? LibraryWorkerError, .notFound)
        }
        XCTAssertThrowsError(try worker.setRating(.liked, key: "movie-1"))
        XCTAssertThrowsError(try worker.remove(key: "movie-1"))
    }
}
