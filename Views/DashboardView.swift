import SwiftUI
import UIKit

/// The home screen displaying a grid of searchable items
struct DashboardView: View {
    let items = SearchableItem.allItems
    @State private var showHelp = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find objects in seconds")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Pick what you need, then point your camera. We'll highlight matches and vibrate when it's found.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal)

                HStack(spacing: 10) {
                    Label("Hold 0.5\u{2013}1.5m away", systemImage: "arrow.up.left.and.arrow.down.right")
                    Label("Use good light", systemImage: "sun.max.fill")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.warning)
                .padding(.horizontal)

                // Grid of searchable items
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            SearchableItemCard(item: item)
                        }
                        .buttonStyle(SpringPressButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(AppTheme.backgroundGradient)
        .navigationTitle("Accio")
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .navigationDestination(for: SearchableItem.self) { item in
            ViewfinderView(targetItem: item)
        }
        .sheet(isPresented: $showHelp) {
            HelpSheetView()
        }
    }
}
