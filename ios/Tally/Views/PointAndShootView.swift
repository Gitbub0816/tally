import AVFoundation
import SwiftUI
import UIKit

struct PointAndShootView: View {
    @EnvironmentObject private var store: TallyStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraService()
    @State private var captured: Encounter?
    @State private var flash = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreview(session: camera.session).ignoresSafeArea()
            if case .running = camera.state {} else { cameraFallback }
            LinearGradient(colors: [Color.black.opacity(0.68), .clear, Color.black.opacity(0.82)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            hud
            if flash { Color.white.ignoresSafeArea().transition(.opacity).allowsHitTesting(false) }
        }
        .preferredColorScheme(.dark)
        .onAppear { camera.start(); store.locationService.beginUpdates() }
        .onDisappear { camera.stop() }
        .sheet(item: $captured) { CardDetailView(encounter: $0) }
    }

    private var hud: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44).background(.black.opacity(0.42), in: Circle()) }
                Spacer()
                VStack(spacing: 2) {
                    Text("POINT & SHOOT").font(.system(size: 12, weight: .black, design: .monospaced)).tracking(2)
                    Text(store.environment.isDemo ? "SIMULATED FLIGHT LOCK" : "LIVE FLIGHT LOCK").font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(.green)
                }
                Spacer()
                Image(systemName: "location.north.line.fill").frame(width: 44, height: 44).background(.black.opacity(0.42), in: Circle())
                    .rotationEffect(.degrees(currentHeading))
            }.padding(.horizontal, 18).padding(.top, 10)

            compass.padding(.top, 18)
            Spacer()
            reticle
            Spacer()
            targetPanel.padding(.horizontal, 18).padding(.bottom, 8)
            shutter.padding(.bottom, 24)
        }.foregroundStyle(.white)
    }

    private var compass: some View {
        HStack(spacing: 16) {
            ForEach([-20, -10, 0, 10, 20], id: \.self) { offset in
                VStack(spacing: 4) {
                    Rectangle().fill(offset == 0 ? Color.green : Color.white.opacity(0.55)).frame(width: 1, height: offset == 0 ? 13 : 7)
                    Text("\(Int(currentHeading) + offset)°").font(.system(size: 7, design: .monospaced)).opacity(offset == 0 ? 1 : 0.55)
                }
            }
        }.padding(.horizontal, 18).padding(.vertical, 8).background(.black.opacity(0.34), in: Capsule())
    }

    private var reticle: some View {
        ZStack {
            Circle().stroke(isLocked ? Color.green : Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 1.2, dash: [8, 7])).frame(width: 186, height: 186)
            Circle().stroke(isLocked ? Color.green.opacity(0.55) : Color.white.opacity(0.35), lineWidth: 1).frame(width: 72, height: 72)
            Path { path in
                path.move(to: CGPoint(x: 93, y: 0)); path.addLine(to: CGPoint(x: 93, y: 66)); path.move(to: CGPoint(x: 93, y: 120)); path.addLine(to: CGPoint(x: 93, y: 186))
                path.move(to: CGPoint(x: 0, y: 93)); path.addLine(to: CGPoint(x: 66, y: 93)); path.move(to: CGPoint(x: 120, y: 93)); path.addLine(to: CGPoint(x: 186, y: 93))
            }.stroke(isLocked ? Color.green : .white, lineWidth: 1)
            if isLocked { Text("TARGET LOCK").font(.system(size: 8, weight: .black, design: .monospaced)).tracking(1.4).foregroundStyle(.green).offset(y: 112) }
        }.frame(width: 186, height: 186)
    }

    private var targetPanel: some View {
        Group {
            if let target {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(target.aircraft.registration).font(.system(size: 22, weight: .black, design: .monospaced))
                        Text("\(target.aircraft.displayModel) · \(target.flightNumber)").font(.caption).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(target.rarity.title).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(.yellow)
                        Text(String(format: "%.1f NM  /  %d FT", target.distanceMiles, target.altitudeFeet)).font(.system(size: 9, design: .monospaced))
                    }
                }
            } else { Text("NO CONTACT IN RETICLE").font(.caption.monospaced()).frame(maxWidth: .infinity) }
        }.padding(16).background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(isLocked ? Color.green.opacity(0.7) : Color.white.opacity(0.2)))
    }

    private var shutter: some View {
        Button { shoot() } label: {
            ZStack { Circle().stroke(.white, lineWidth: 4).frame(width: 78, height: 78); Circle().fill(isLocked ? Color.white : Color.gray).frame(width: 64, height: 64); Image(systemName: "scope").foregroundStyle(.black).font(.title2) }
        }.disabled(!isLocked).padding(.top, 14)
    }

    @ViewBuilder private var cameraFallback: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.07), .black], startPoint: .top, endPoint: .bottom)
            if case .denied = camera.state {
                VStack(spacing: 12) { Image(systemName: "camera.fill").font(.largeTitle); Text("CAMERA ACCESS REQUIRED").font(.caption.bold()); Button("OPEN SETTINGS") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) } }.foregroundStyle(.white)
            }
        }.ignoresSafeArea()
    }

    private var currentHeading: Double { store.locationService.heading?.trueHeading ?? store.locationService.heading?.magneticHeading ?? 0 }
    private var target: Encounter? {
        if store.environment.isDemo { return store.priorityContacts.first ?? store.encounters.first }
        return store.encounters.min { angularDistance(Double($0.bearingDegrees), currentHeading) < angularDistance(Double($1.bearingDegrees), currentHeading) }
    }
    private var isLocked: Bool { guard let target else { return false }; return store.environment.isDemo || angularDistance(Double(target.bearingDegrees), currentHeading) <= 10 }
    private func angularDistance(_ first: Double, _ second: Double) -> Double { abs((first - second + 540).truncatingRemainder(dividingBy: 360) - 180) }

    private func shoot() {
        guard isLocked, let target else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        withAnimation(.easeOut(duration: 0.08)) { flash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { withAnimation(.easeIn(duration: 0.12)) { flash = false }; captured = target }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView { let view = PreviewView(); view.layerView.session = session; return view }
    func updateUIView(_ uiView: PreviewView, context: Context) { uiView.layerView.session = session }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var layerView: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    override init(frame: CGRect) { super.init(frame: frame); layerView.videoGravity = .resizeAspectFill }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
