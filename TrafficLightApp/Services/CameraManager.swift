import AVFoundation
import Foundation

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()

    private let queue = DispatchQueue(label: "camera.manager.queue", qos: .userInitiated)

    @Published var isRunning = false

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        queue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.output.alwaysDiscardsLateVideoFrames = true
            self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()
        }
    }

    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        output.setSampleBufferDelegate(delegate, queue: queue)
    }

    func start() {
        queue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        queue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }
}
