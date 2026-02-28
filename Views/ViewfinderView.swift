import SwiftUI
import UIKit

/// The camera viewfinder screen that displays live detection results
struct ViewfinderView: View {
    let targetItem: SearchableItem

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScanViewModel()
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var showIdleHint = false
    @State private var showFoundFlash = false
    @State private var idleHintWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            switch viewModel.permissionState {
            case .denied:
                permissionDeniedView

            case .unknown, .granted:
                cameraContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                statusLabel
            }
        }
        .onAppear {
            viewModel.startScanning(for: targetItem)
            startPulseAnimation()
            scheduleIdleHint(delay: 4.0)
        }
        .onDisappear {
            viewModel.stopScanning()
            idleHintWorkItem?.cancel()
        }
        .onChange(of: viewModel.hasMatch) { hasMatch in
            if hasMatch {
                // Hide idle hint when found
                withAnimation(.easeInOut(duration: 0.25)) {
                    showIdleHint = false
                }
                idleHintWorkItem?.cancel()

                // Trigger found flash
                withAnimation(.easeIn(duration: 0.15)) {
                    showFoundFlash = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.45)) {
                        showFoundFlash = false
                    }
                }
            } else {
                // Match lost — re-show idle hint after a shorter delay
                scheduleIdleHint(delay: 2.0)
            }
        }
    }

    // MARK: - Main Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        if let error = viewModel.modelError {
            modelErrorView(error: error)
        } else {
            // Layer 1: Live camera preview
            CameraPreviewView(session: viewModel.cameraManager.captureSession)
                .ignoresSafeArea()

            // Layer 2: Detection overlay
            BoundingBoxOverlay(detections: viewModel.filteredDetections)

            // Layer 3: HUD
            VStack {
                topHUD
                Spacer()
                bottomHUD
            }

            // Layer 4: Green border flash on first match
            if showFoundFlash {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(AppTheme.accent, lineWidth: 4)
                    .shadow(color: AppTheme.accent.opacity(0.6), radius: 16)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Status Label

    private var statusLabel: some View {
        HStack(spacing: 8) {
            // Pulsing animated indicator
            Circle()
                .fill(viewModel.hasMatch ? AppTheme.accent : Color.white)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)

            Text("Searching for \(targetItem.name)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasMatch)
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.45
            pulseOpacity = 0.35
        }
    }

    // MARK: - Control Bar

    private var topHUD: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: targetItem.iconName)
                    .foregroundStyle(AppTheme.accent)
                Text(targetItem.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.surface.opacity(0.75), in: Capsule())

            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }

    private var bottomHUD: some View {
        VStack(spacing: 12) {
            if viewModel.hasMatch {
                Text("Found!")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface.opacity(0.8), in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else if showIdleHint {
                Text("No match yet \u{2014} try moving closer or adding more light.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.surface.opacity(0.8), in: Capsule())
                    .transition(.opacity)
            }

            Button(action: { dismiss() }) {
                Label("Back to items", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 15)
                    .background(Color.red.gradient)
                    .clipShape(Capsule())
                    .shadow(color: .red.opacity(0.4), radius: 10, y: 4)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasMatch)
        .animation(.easeInOut(duration: 0.3), value: showIdleHint)
        .padding(.bottom, 20)
    }

    private func scheduleIdleHint(delay: TimeInterval) {
        idleHintWorkItem?.cancel()
        let work = DispatchWorkItem { [self] in
            if !viewModel.hasMatch {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showIdleHint = true
                }
            }
        }
        idleHintWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: - Permission Denied (custom fallback for iOS 16 compat)

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            Text("Camera Access Required")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Accio needs camera access to search for your items. Please enable it in Settings.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 32)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundGradient)
    }

    // MARK: - Model Error (custom fallback for iOS 16 compat)

    private func modelErrorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppTheme.warning)

            Text("Detection Unavailable")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(error.localizedDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 32)

            Button("Go Back") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundGradient)
    }
}
