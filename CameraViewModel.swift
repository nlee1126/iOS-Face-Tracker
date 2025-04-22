import AVFoundation
import Photos
import Vision

class CameraViewModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoFrameOutput = AVCaptureVideoDataOutput()
    private let faceQueue = DispatchQueue(label: "face-detection-queue")

    @Published var currentPosition: AVCaptureDevice.Position = .front
    @Published var isRecording = false
    @Published var faceCenter: CGPoint? // face center in normalized coords (0–1)

    override init() {
        super.init()
        configureSession(for: currentPosition)
    }

    private func configureSession(for position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("Failed to set up camera input.")
            return
        }

        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if session.canAddOutput(videoFrameOutput) {
            videoFrameOutput.setSampleBufferDelegate(self, queue: faceQueue)
            videoFrameOutput.alwaysDiscardsLateVideoFrames = true
            session.addOutput(videoFrameOutput)
        }

        session.commitConfiguration()
    }

    func flipCamera() {
        currentPosition = (currentPosition == .front) ? .back : .front
        configureSession(for: currentPosition)
    }

    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func toggleRecording() {
        if videoOutput.isRecording {
            videoOutput.stopRecording()
            isRecording = false
        } else {
            let outputPath = NSTemporaryDirectory() + UUID().uuidString + ".mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
            isRecording = true
        }
    }

    private func handleFaceDetection(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation],
                  let face = results.first else {
                DispatchQueue.main.async {
                    self?.faceCenter = nil
                }
                return
            }

            let boundingBox = face.boundingBox
            let centerX = boundingBox.origin.x + boundingBox.size.width / 2
            let centerY = boundingBox.origin.y + boundingBox.size.height / 2
            let normalized = CGPoint(x: centerX, y: 1 - centerY) // flip Y

            DispatchQueue.main.async {
                self?.faceCenter = normalized
//                print("🎯 Face Center: \(normalized)")
            }
        }

        let orientation: CGImagePropertyOrientation = (currentPosition == .front) ? .leftMirrored : .right
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Delegate Extensions

extension CameraViewModel: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handleFaceDetection(buffer: sampleBuffer)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.forAsset().addResource(with: .photo, data: imageData, options: nil)
                }
            }
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else { return }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                }
            }
        }
    }
}
