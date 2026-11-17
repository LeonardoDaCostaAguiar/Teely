import Foundation
import SwiftData

@MainActor
final class AppEnvironment {
    let service: MediaServicing
    let worker: LibraryWorking
    let languageProvider: @Sendable () -> String
    let container: ModelContainer
    let showsSplash: Bool

    init(
        service: MediaServicing,
        worker: LibraryWorking,
        languageProvider: @escaping @Sendable () -> String,
        container: ModelContainer,
        showsSplash: Bool = true
    ) {
        self.service = service
        self.worker = worker
        self.languageProvider = languageProvider
        self.container = container
        self.showsSplash = showsSplash
    }

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        let isUITesting = arguments.contains("-uitesting")
        let container = makeContainer(inMemory: isUITesting)
        let worker = SwiftDataLibraryWorker(context: container.mainContext)
        let service: MediaServicing = isUITesting
            ? StubMediaService(
                trendingFails: arguments.contains("-trending-error"),
                extendedDetails: arguments.contains("-extended-details")
            )
            : TMDBService(accessToken: AppConfiguration.tmdbAccessToken)
        return AppEnvironment(
            service: service,
            worker: worker,
            languageProvider: { AppLanguage.current },
            container: container,
            showsSplash: !isUITesting || arguments.contains("-show-splash")
        )
    }

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: SavedMedia.self, configurations: configuration)
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }
}
