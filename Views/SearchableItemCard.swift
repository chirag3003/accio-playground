import SwiftUI

/// Spring-scale press effect applied via ButtonStyle so it never blocks NavigationLink
struct SpringPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

/// A card component displaying a searchable item with icon and label
struct SearchableItemCard: View {
    let item: SearchableItem

    var body: some View {
        VStack(spacing: 12) {
            // Large SF Symbol icon
            Image(systemName: item.iconName)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(height: 44)

            // Item label
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
