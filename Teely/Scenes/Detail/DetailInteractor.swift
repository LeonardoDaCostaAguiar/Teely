import Foundation

@MainActor
protocol DetailBusinessLogic: AnyObject {
    func load(_ request: Detail.Load.Request) async
    func save(_ request: Detail.Save.Request)
    func setStatus(_ request: Detail.SetStatus.Request)
    func setRating(_ request: Detail.SetRating.Request)
    func remove(_ request: Detail.Remove.Request)
}

@MainActor
final class DetailInteractor: DetailBusinessLogic {
    private let kind: MediaKind
    private let id: Int
    private let service: MediaServicing
    private let worker: LibraryWorking
    private let presenter: DetailPresentationLogic
    private let router: DetailRouting
    private let languageProvider: @Sendable () -> String
    private var detail: MediaDetail?

    private var key: String { MediaKey.make(kind: kind, id: id) }

    init(
        kind: MediaKind,
        id: Int,
        service: MediaServicing,
        worker: LibraryWorking,
        presenter: DetailPresentationLogic,
        router: DetailRouting,
        languageProvider: @escaping @Sendable () -> String
    ) {
        self.kind = kind
        self.id = id
        self.service = service
        self.worker = worker
        self.presenter = presenter
        self.router = router
        self.languageProvider = languageProvider
    }

    func load(_ request: Detail.Load.Request) async {
        presenter.presentLoading()
        let saved = savedItem()
        do {
            let loaded = try await service.detail(kind: kind, id: id, language: languageProvider())
            detail = loaded
            presenter.presentContent(Detail.Response(detail: loaded, saved: saved))
        } catch {
            if let saved {
                let fallback = MediaDetail(saved: saved)
                detail = fallback
                presenter.presentContent(Detail.Response(detail: fallback, saved: saved))
            } else {
                let failure: Detail.Failure = (error as? TMDBError) == .missingToken ? .missingToken : .network
                presenter.presentFailure(failure)
            }
        }
    }

    func save(_ request: Detail.Save.Request) {
        guard let detail else { return }
        _ = try? worker.save(detail)
        refresh()
    }

    func setStatus(_ request: Detail.SetStatus.Request) {
        guard savedItem() != nil else { return }
        _ = try? worker.setStatus(request.status, key: key)
        refresh()
    }

    func setRating(_ request: Detail.SetRating.Request) {
        guard let current = savedItem(), current.status == .watched else { return }
        let newValue: MediaRating? = current.rating == request.rating ? nil : request.rating
        _ = try? worker.setRating(newValue, key: key)
        refresh()
    }

    func remove(_ request: Detail.Remove.Request) {
        guard savedItem() != nil else { return }
        guard (try? worker.remove(key: key)) != nil else {
            refresh()
            return
        }
        router.routeBack()
    }

    private func savedItem() -> SavedItem? {
        guard let saved = (try? worker.find(key: key)) ?? nil else { return nil }
        return SavedItem(saved)
    }

    private func refresh() {
        guard let detail else { return }
        presenter.presentContent(Detail.Response(detail: detail, saved: savedItem()))
    }
}
