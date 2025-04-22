import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraModel = CameraViewModel()
    @StateObject var bluetooth = BluetoothManager()
    @State private var lastSentTime: TimeInterval = 0

    var body: some View {
        ZStack {
            // Camera Feed
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()
                .onAppear {
                    cameraModel.startSession()
                }
                .onDisappear {
                    cameraModel.stopSession()
                }

//            GeometryReader { geo in
//                if let face = cameraModel.faceCenter {
//                    let x = face.x * geo.size.width
//                    let y = face.y * geo.size.height
//
//                    Circle()
//                        .fill(Color.red)
//                        .frame(width: 20, height: 20)
//                        .position(x: x, y: y)
//                        .animation(.easeInOut(duration: 0.2), value: face)
//                }
//            }
            .onChange(of: cameraModel.faceCenter) { oldValue, newValue in
                if let face = newValue, bluetooth.isReady {
                    let now = Date().timeIntervalSince1970
                    if now - lastSentTime > 0.05 { // throttle to ~20 Hz
                        bluetooth.sendFacePosition(x: face.x, y: face.y)
                        lastSentTime = now
                    }
                }
            }

            VStack {
                Spacer()

                HStack {
                    // Flip Camera Button
                    Button(action: {
                        cameraModel.flipCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 24, weight: .bold))
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)

                    Spacer()

                    // Take Photo Button
                    Button(action: {
                        cameraModel.takePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    }

                    Spacer()

                    // Record Video Button
                    Button(action: {
                        cameraModel.toggleRecording()
                    }) {
                        Circle()
                            .fill(cameraModel.isRecording ? Color.red : Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: cameraModel.isRecording ? "stop.fill" : "video.fill")
                                    .foregroundColor(cameraModel.isRecording ? .white : .black)
                                    .font(.system(size: 28))
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    ContentView()
}
