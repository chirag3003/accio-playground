import AVFoundation
import Foundation
import Combine

/// Possible camera permission states
enum CameraPermissionState {
    case unknown
    case granted
    case denied
}

/// Delegate protocol for receiving camera frame data
protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer)
}

/// Manages AVCaptureSession for live camera video capture
final class CameraManager: NSObject, ObservableObject {

    // MARK: - Properties

    let captureSession = AVCaptureSession()
    weak var delegate: CameraManagerDelegate?

    /// Current camera permission state
    @Published private(set) var permissionState: CameraPermissionState = .unknown

    var isRunning: Bool {
        captureSession.isRunning
    }

    private let sessionQueue = DispatchQueue(label: "com.accio.cameraSession")
    private let videoOutput = AVCaptureVideoDataOutput()

    // MARK: - Public Methods

    /// Request camera permission and configure session
    func configure() {
        checkPermission()
    }

    /// Start the capture session. Safe to call before configure() completes --
    /// the serial sessionQueue ensures ordering.
    func start() {
        sessionQueue.async { [weak self] in
            guard let self,
                  self.permissionState == .granted,
                  !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    /// Stop the capture session
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    // MARK: - Private Methods

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { [weak self] in
                self?.permissionState = .granted
            }
            setupCaptureSession()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.permissionState = granted ? .granted : .denied
                }
                if granted {
                    self.setupCaptureSession()
                }
            }

        case .denied, .restricted:
            DispatchQueue.main.async { [weak self] in
                self?.permissionState = .denied
            }

        @unknown default:
            DispatchQueue.main.async { [weak self] in
                self?.permissionState = .denied
            }
        }
    }

    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(videoInput)

            // Add video output
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.accio.videoOutput"))
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)

                // Set video orientation to portrait
                if let connection = self.videoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                    } else {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                        }
                    }
                }
            }

            self.captureSession.commitConfiguration()

            // Auto-start after configuration
            self.captureSession.startRunning()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.cameraManager(self, didOutput: pixelBuffer)
    }
}
