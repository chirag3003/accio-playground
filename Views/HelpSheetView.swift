import SwiftUI

struct HelpSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to use Accio")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Select an item, point your camera, and wait for the green reticle + haptic.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    TipRow(icon: "hand.raised.fill", title: "Hold steady", detail: "Keep the phone still for a second to lock onto small items.")
                    TipRow(icon: "ruler", title: "Distance", detail: "Best results are 0.5\u{2013}1.5 meters from the target.")
                    TipRow(icon: "sun.max.fill", title: "Lighting", detail: "Use bright, even light and avoid harsh glare.")
                    TipRow(icon: "square.2.layers.3d", title: "Clutter", detail: "If the object is hidden, move items around and scan again.")
                }
                .padding(20)
            }
            .background(AppTheme.backgroundGradient)
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}

private struct TipRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.warning)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
