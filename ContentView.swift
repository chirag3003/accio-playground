import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            NavigationStack {
                DashboardView()
            }
            .tint(AppTheme.accent)
        } else {
            OnboardingView {
                hasSeenOnboarding = true
            }
        }
    }
}
