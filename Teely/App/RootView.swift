import SwiftUI

enum SplashContent {
    static let slogan = "Discover. Track. Watch"
}

enum SplashTiming {
    static let duration: Duration = .seconds(4)
    static let fade: Double = 0.4
}

@MainActor
struct SplashView: View {
    @State private var isShown = false

    var body: some View {
        VStack(spacing: 28) {
            Image("SplashIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 124)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .background(NeuSurface(cornerRadius: 28, isInset: false, depth: 10))
                .accessibilityHidden(true)
            Image("TeelyLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 64)
                .accessibilityLabel(Text(verbatim: "Teely"))
                .accessibilityIdentifier("splashName")
            Text(verbatim: SplashContent.slogan)
                .font(.manrope(.headline, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityIdentifier("splashSlogan")
        }
        .opacity(isShown ? 1 : 0)
        .scaleEffect(isShown ? 1 : 0.94)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .neuScreenBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { isShown = true }
        }
    }
}

@MainActor
struct RootView: View {
    let environment: AppEnvironment
    @State private var router = AppRouter()
    @State private var selection = 0
    @State private var isSplashVisible: Bool

    init(environment: AppEnvironment) {
        self.environment = environment
        _isSplashVisible = State(initialValue: environment.showsSplash)
    }

    var body: some View {
        ZStack {
            navigation
                .accessibilityHidden(isSplashVisible)
            if isSplashVisible {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard isSplashVisible else { return }
            try? await Task.sleep(for: SplashTiming.duration)
            withAnimation(.easeOut(duration: SplashTiming.fade)) { isSplashVisible = false }
        }
    }

    private var navigation: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $selection) {
                HomeView(environment: environment, navigator: router)
                    .tabItem { Label("tab.home", systemImage: "house") }
                    .accessibilityIdentifier("homeTab")
                    .tag(0)
                LibraryView(environment: environment, navigator: router)
                    .tabItem { Label("tab.library", systemImage: "books.vertical") }
                    .accessibilityIdentifier("libraryTab")
                    .tag(1)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .search(let query):
                    SearchView(environment: environment, navigator: router, query: query)
                case .detail(let kind, let id):
                    DetailView(environment: environment, navigator: router, kind: kind, id: id)
                }
            }
        }
        .tint(Theme.accent)
    }
}
