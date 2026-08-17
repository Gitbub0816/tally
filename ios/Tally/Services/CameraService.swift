import AVFoundation
import Foundation

@MainActor
final class CameraService: ObservableObject {
    enum State { case idle, requesting, running, denied, unavailable, failed(String) }

    let session = AVCaptureSession()
    @Published private(set) var state: State = .idle
    private let queue = DispatchQueue(label: "app.tally.camera", qos: .userInitiated)
    private var configured = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureAndStart()
        case .notDetermined:
            state = .requesting
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in granted ? self?.configureAndStart() : (self?.state = .denied) }
            }
        case .denied, .restricted: state = .denied
        @unknown default: state = .denied
        }
    }

    func stop() {
        queue.async { [session] in if session.isRunning { session.stopRunning() } }
    }

    private func configureAndStart() {
        state = .requesting
        queue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .high
                defer { self.session.commitConfiguration() }
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: camera), self.session.canAddInput(input) else {
                    Task { @MainActor in self.state = .unavailable }; return
                }
                self.session.addInput(input); self.configured = true
            }
            self.session.startRunning()
            Task { @MainActor in self.state = .running }
        }
    }
}
