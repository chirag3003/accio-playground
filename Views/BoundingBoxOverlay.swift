import SwiftUI

// MARK: - Corner Bracket Shape

/// Draws four L-shaped corner brackets (targeting reticle)
private struct TargetingBrackets: Shape {
    /// Length of each bracket arm as a fraction of the shorter side
    var armFraction: CGFloat = 0.25

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arm = min(rect.width, rect.height) * armFraction
        let minX = rect.minX, maxX = rect.maxX
        let minY = rect.minY, maxY = rect.maxY

        // Top-left
        path.move(to: CGPoint(x: minX, y: minY + arm))
        path.addLine(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: minX + arm, y: minY))

        // Top-right
        path.move(to: CGPoint(x: maxX - arm, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY + arm))

        // Bottom-right
        path.move(to: CGPoint(x: maxX, y: maxY - arm))
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: maxX - arm, y: maxY))

        // Bottom-left
        path.move(to: CGPoint(x: minX + arm, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: maxY - arm))

        return path
    }
}

// MARK: - Single Detection Highlight

/// Targeting reticle for one detected object.
/// NOTE: These views are recreated every ML-inference frame (new IDs each time),
/// so we must NOT rely on @State + onAppear for visibility. Everything renders
/// immediately -- only the continuous glow pulse uses a TimelineView.
private struct DetectionHighlight: View {
    let detection: DetectionBox
    let screenRect: CGRect

    // Neon green accent
    private let accent = AppTheme.accent

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let phase = pulseFraction(date: timeline.date)

            ZStack {
                // Subtle translucent fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(accent.opacity(0.08))

                // Glow layer (blurred thick stroke behind brackets)
                TargetingBrackets()
                    .stroke(accent.opacity(0.25 + phase * 0.3), lineWidth: 8)
                    .blur(radius: 6)

                // Sharp bracket lines on top
                TargetingBrackets()
                    .stroke(accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // Confidence badge -- pinned inside the top-left
                VStack(spacing: 0) {
                    HStack {
                        confidenceBadge
                            .padding(.leading, 4)
                            .padding(.top, 4)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(width: screenRect.width, height: screenRect.height)
        .position(x: screenRect.midX, y: screenRect.midY)
    }

    /// Returns 0->1->0 on a ~1.4s cycle for the glow pulse
    private func pulseFraction(date: Date) -> CGFloat {
        let t = date.timeIntervalSinceReferenceDate
        return CGFloat((sin(t * 2.3 * .pi) + 1) / 2)
    }

    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)
            Text(detection.label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(accent.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Overlay

/// Transparent overlay that renders targeting reticles for detected objects
struct BoundingBoxOverlay: View {
    let detections: [DetectionBox]

    var body: some View {
        GeometryReader { geometry in
            ForEach(detections) { detection in
                DetectionHighlight(
                    detection: detection,
                    screenRect: screen(for: detection.rect, in: geometry.size)
                )
            }
        }
        .allowsHitTesting(false) // Never intercept touches
    }

    private func screen(for normalized: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: normalized.minX * size.width,
            y: normalized.minY * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }
}
