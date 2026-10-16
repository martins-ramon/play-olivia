import SwiftUI

/// Owned by the App, so another scene activation never replays the opening.
@MainActor
final class AppLaunchState: ObservableObject {
    @Published private(set) var hasFinished = false

    func finish() { hasFinished = true }
}

struct AppRootView: View {
    @ObservedObject var launch: AppLaunchState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PlayTheme.paper.ignoresSafeArea()
            if launch.hasFinished {
                HomeView().transition(.opacity)
            } else {
                SplashView {
                    withAnimation(.easeOut(duration: reduceMotion ? 0.12 : 0.32)) {
                        launch.finish()
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
