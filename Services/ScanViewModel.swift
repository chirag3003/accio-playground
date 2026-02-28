import Foundation
import CoreVideo
import UIKit
import Combine

/// ViewModel connecting camera, detector, and UI for the Viewfinder screen
final class ScanViewModel: ObservableObject, CameraManagerDelegate {

    // MARK: - Properties

    let cameraManager = CameraManager()
    private let detector = ObjectDetector()

    /// The item we're actively searching for
    @Published var targetItem: SearchableItem?

    /// Smoothed detections -- stable for display, won't flicker frame-to-frame
    @Published private(set) var displayDetections: [DetectionBox] = []

    /// Filtered detections matching the target item
    var filteredDetections: [DetectionBox] {
        guard let targetItem else { return displayDetections }
        return displayDetections.filter { targetItem.matches(label: $0.label) }
    }

    /// True when at least one match is found right now
    var hasMatch: Bool { !filteredDetections.isEmpty }

    /// Camera permission state forwarded from CameraManager
    var permissionState: CameraPermissionState { cameraManager.permissionState }

    /// Model load error from the detector, if any
    var modelError: Error? { detector.modelLoadError }

    // MARK: - Smoothing

    /// How long (seconds) a detection stays visible after the model last saw it
    private let retentionInterval: TimeInterval = 0.4

    /// Tracks the last time each label was seen, plus the most recent box for it
    private var trackedDetections: [String: (box: DetectionBox, lastSeen: Date)] = [:]
    private var cleanupTimer: Timer?

    // MARK: - Haptic

    private var didFireFoundHaptic = false
    private let haptic = UINotificationFeedbackGenerator()

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        cameraManager.delegate = self

        detector.onDetections = { [weak self] detections in
            self?.updateTrackedDetections(detections)
        }

        // Forward CameraManager's permissionState changes to trigger view updates
        cameraManager.$permissionState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func startScanning(for item: SearchableItem) {
        targetItem = item
        haptic.prepare()
        cameraManager.configure()
        cameraManager.start()

        // Periodic cleanup of stale detections
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.pruneStaleDetections()
        }
    }

    func stopScanning() {
        cameraManager.stop()
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        trackedDetections.removeAll()
        displayDetections = []
        didFireFoundHaptic = false
    }

    // MARK: - CameraManagerDelegate

    func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer) {
        detector.detect(pixelBuffer: pixelBuffer)
    }

    // MARK: - Smoothing Logic

    private func updateTrackedDetections(_ detections: [DetectionBox]) {
        let now = Date()

        // Update or insert every detection the model saw this frame
        for det in detections {
            let key = det.label.lowercased()
            // Smooth confidence with exponential moving average (70% new, 30% old)
            let smoothedConfidence: Float
            if let existing = trackedDetections[key] {
                smoothedConfidence = det.confidence * 0.7 + existing.box.confidence * 0.3
            } else {
                smoothedConfidence = det.confidence
            }
            let smoothedBox = DetectionBox(rect: det.rect, label: det.label, confidence: smoothedConfidence)
            trackedDetections[key] = (box: smoothedBox, lastSeen: now)
        }

        rebuildDisplayList()
    }

    private func pruneStaleDetections() {
        let now = Date()
        let staleKeys = trackedDetections.filter { now.timeIntervalSince($0.value.lastSeen) > retentionInterval }.map(\.key)
        guard !staleKeys.isEmpty else { return }
        for key in staleKeys {
            trackedDetections.removeValue(forKey: key)
        }
        rebuildDisplayList()
    }

    private func rebuildDisplayList() {
        displayDetections = trackedDetections.values.map(\.box)

        // Haptic: fire once on empty -> non-empty transition
        if hasMatch {
            if !didFireFoundHaptic {
                haptic.notificationOccurred(.success)
                didFireFoundHaptic = true
            }
        } else {
            didFireFoundHaptic = false
        }
    }
}
