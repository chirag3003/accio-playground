import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var selection = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Pick what you need",
            subtitle: "Choose an item from the dashboard and start searching.",
            systemImage: "square.grid.3x3.fill"
        ),
        OnboardingPage(
            title: "Point and scan",
            subtitle: "Aim your camera and wait for the green reticle and haptic.",
            systemImage: "camera.viewfinder"
        ),
        OnboardingPage(
            title: "Get better results",
            subtitle: "Hold steady, stay 0.5\u{2013}1.5m away, and use bright light.",
            systemImage: "sun.max.fill"
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page)

                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == selection ? AppTheme.accent : Color.white.opacity(0.2))
                            .frame(width: index == selection ? 26 : 10, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: selection)
                    }
                }

                Button(action: advance) {
                    Text(selection == pages.count - 1 ? "Start Searching" : "Next")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func advance() {
        if selection < pages.count - 1 {
            selection += 1
        } else {
            onFinish()
        }
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let systemImage: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: page.systemImage)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(.bottom, 6)

            Text(page.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(page.subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
