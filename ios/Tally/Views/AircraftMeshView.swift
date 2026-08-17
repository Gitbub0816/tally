import OSLog
import SceneKit
import SwiftUI
import UIKit

private let aircraftModelLogger = Logger(subsystem: "app.tally.ios", category: "AircraftModels")

struct AircraftMeshView: View {
    let encounter: Encounter
    var compact = false

    @ViewBuilder
    var body: some View {
        if let asset = AircraftModelAsset.resolve(for: encounter.aircraft) {
            BundledAircraftMeshView(asset: asset, encounter: encounter, compact: compact)
        } else {
            ProceduralAircraftMeshView(encounter: encounter, compact: compact)
        }
    }
}

private struct BundledAircraftMeshView: UIViewRepresentable {
    let asset: AircraftModelAsset
    let encounter: Encounter
    let compact: Bool

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = compact ? .multisampling2X : .multisampling4X
        view.autoenablesDefaultLighting = false
        view.isUserInteractionEnabled = false
        load(into: view)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        let identifier = asset.rawValue + encounter.aircraft.registration
        guard view.accessibilityIdentifier != identifier else { return }
        load(into: view)
    }

    private func load(into view: SCNView) {
        let identifier = asset.rawValue + encounter.aircraft.registration
        view.accessibilityIdentifier = identifier
        view.isAccessibilityElement = true
        view.accessibilityLabel = "3D model of \(encounter.aircraft.displayModel)"

        guard let url = resourceURL else {
            aircraftModelLogger.error("Missing bundled aircraft model: \(asset.rawValue, privacy: .public).usdz")
            view.accessibilityValue = "Using fallback model"
            view.scene = ProceduralAircraftMeshView(encounter: encounter, compact: compact).scene()
            return
        }

        do {
            let scene = try SCNScene(url: url, options: [.checkConsistency: true])
            prepare(scene: scene)
            view.scene = scene
            view.accessibilityValue = "Bundled model loaded"
            aircraftModelLogger.info("Loaded bundled aircraft model: \(asset.rawValue, privacy: .public).usdz")
        } catch {
            aircraftModelLogger.error("Failed to load \(asset.rawValue, privacy: .public).usdz: \(String(describing: error), privacy: .public)")
            view.accessibilityValue = "Using fallback model"
            view.scene = ProceduralAircraftMeshView(encounter: encounter, compact: compact).scene()
        }
    }

    private var resourceURL: URL? {
        Bundle.main.url(forResource: asset.rawValue, withExtension: "usdz")
            ?? Bundle.main.url(forResource: asset.rawValue, withExtension: "usdz", subdirectory: "AircraftModels")
    }

    private func prepare(scene: SCNScene) {
        let model = SCNNode()
        for child in scene.rootNode.childNodes {
            model.addChildNode(child)
        }
        scene.rootNode.addChildNode(model)

        let (minimum, maximum) = model.boundingBox
        let center = SCNVector3(
            (minimum.x + maximum.x) * 0.5,
            (minimum.y + maximum.y) * 0.5,
            (minimum.z + maximum.z) * 0.5
        )
        let longest = max(maximum.x - minimum.x, max(maximum.y - minimum.y, maximum.z - minimum.z))
        let scale = longest > 0 ? 7.4 / longest : 1
        model.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        model.scale = SCNVector3(scale, scale, scale)
        model.position = SCNVector3(0, compact ? -0.1 : -0.25, 0)
        model.eulerAngles = SCNVector3(-0.09, 0, -0.06)

        let camera = SCNCamera()
        camera.fieldOfView = compact ? 34 : 31
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.45, compact ? 14.5 : 13.5)
        scene.rootNode.addChildNode(cameraNode)

        let key = SCNLight()
        key.type = .directional
        key.intensity = 1_250
        key.color = UIColor.white
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.eulerAngles = SCNVector3(-0.7, -0.55, 0)
        scene.rootNode.addChildNode(keyNode)

        let fill = SCNLight()
        fill.type = .omni
        fill.intensity = 420
        fill.color = UIColor(red: 0.75, green: 0.82, blue: 1, alpha: 1)
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.position = SCNVector3(-3, 2, 4)
        scene.rootNode.addChildNode(fillNode)
    }
}

private struct ProceduralAircraftMeshView: UIViewRepresentable {
    let encounter: Encounter
    var compact = false

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = compact ? .multisampling2X : .multisampling4X
        view.autoenablesDefaultLighting = false
        view.isUserInteractionEnabled = false
        view.scene = scene()
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        if view.accessibilityIdentifier != encounter.aircraft.model + encounter.aircraft.registration {
            view.scene = scene()
            view.accessibilityIdentifier = encounter.aircraft.model + encounter.aircraft.registration
        }
    }

    fileprivate func scene() -> SCNScene {
        let scene = SCNScene()
        let aircraft = SCNNode(geometry: geometry())
        aircraft.eulerAngles = SCNVector3(-0.10, -0.08, 0)
        scene.rootNode.addChildNode(aircraft)

        let camera = SCNCamera()
        camera.fieldOfView = compact ? 33 : 30
        let cameraNode = SCNNode(); cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.55, compact ? 8.6 : 8.0)
        scene.rootNode.addChildNode(cameraNode)

        let key = SCNLight(); key.type = .directional; key.intensity = 1_250; key.color = UIColor.white
        let keyNode = SCNNode(); keyNode.light = key; keyNode.eulerAngles = SCNVector3(-0.7, -0.55, 0); scene.rootNode.addChildNode(keyNode)
        let fill = SCNLight(); fill.type = .omni; fill.intensity = 420; fill.color = UIColor(red: 0.75, green: 0.82, blue: 1, alpha: 1)
        let fillNode = SCNNode(); fillNode.light = fill; fillNode.position = SCNVector3(-3, 2, 4); scene.rootNode.addChildNode(fillNode)
        return scene
    }

    private func geometry() -> SCNGeometry {
        let value = TLYAircraftMeshFactory.mesh(forModel: encounter.aircraft.model)
        guard let positions = value["positions"] as? Data,
              let normals = value["normals"] as? Data,
              let texcoords = value["texcoords"] as? Data,
              let vertexCount = value["vertexCount"] as? Int else { return SCNGeometry() }

        let sources = [
            SCNGeometrySource(data: positions, semantic: .vertex, vectorCount: vertexCount, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12),
            SCNGeometrySource(data: normals, semantic: .normal, vectorCount: vertexCount, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12),
            SCNGeometrySource(data: texcoords, semantic: .texcoord, vectorCount: vertexCount, usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        ]
        let groups = [("fuselage", "fuselageCount"), ("wings", "wingsCount"), ("engines", "enginesCount"), ("tail", "tailCount")]
        let elements = groups.compactMap { dataKey, countKey -> SCNGeometryElement? in
            guard let data = value[dataKey] as? Data, let count = value[countKey] as? Int else { return nil }
            return SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: count / 3, bytesPerIndex: 4)
        }
        let geometry = SCNGeometry(sources: sources, elements: elements)
        geometry.materials = materials()
        return geometry
    }

    private func materials() -> [SCNMaterial] {
        let fuselage = SCNMaterial(); fuselage.diffuse.contents = LiveryTexture.image(for: encounter); fuselage.metalness.contents = 0.2; fuselage.roughness.contents = 0.35
        let wing = material(color: UIColor(white: 0.79, alpha: 1), metalness: 0.38)
        let engine = material(color: UIColor(hex: encounter.palette.secondaryHex), metalness: 0.45)
        let tail = material(color: UIColor(hex: encounter.palette.primaryHex), metalness: 0.25)
        [fuselage, wing, engine, tail].forEach { $0.isDoubleSided = true }
        return [fuselage, wing, engine, tail]
    }

    private func material(color: UIColor, metalness: CGFloat) -> SCNMaterial {
        let material = SCNMaterial(); material.diffuse.contents = color; material.metalness.contents = metalness; material.roughness.contents = 0.42; return material
    }
}

private enum LiveryTexture {
    static func image(for encounter: Encounter) -> UIImage {
        let size = CGSize(width: 1024, height: 512)
        let format = UIGraphicsImageRendererFormat(); format.opaque = true; format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            let primary = UIColor(hex: encounter.palette.primaryHex), secondary = UIColor(hex: encounter.palette.secondaryHex), accent = UIColor(hex: encounter.palette.accentHex)
            primary.setFill(); cg.fill(CGRect(origin: .zero, size: size))

            switch encounter.aircraft.livery {
            case "Tennessee One":
                UIColor(red: 0.78, green: 0.08, blue: 0.12, alpha: 1).setFill(); cg.fill(CGRect(origin: .zero, size: size))
                UIColor(red: 0.03, green: 0.19, blue: 0.43, alpha: 1).setFill(); cg.fillEllipse(in: CGRect(x: 340, y: 55, width: 344, height: 344))
                for center in [CGPoint(x: 512, y: 120), CGPoint(x: 438, y: 265), CGPoint(x: 586, y: 265)] { star(at: center, in: cg) }
                UIColor.white.setFill(); cg.fill(CGRect(x: 0, y: 405, width: 1024, height: 18))
            case "Classic Canyon Blue":
                secondary.setFill(); cg.fill(CGRect(x: 0, y: 290, width: 1024, height: 222)); accent.setFill(); cg.fill(CGRect(x: 0, y: 350, width: 1024, height: 34))
            case "Yellow":
                UIColor(red: 0.96, green: 0.82, blue: 0.05, alpha: 1).setFill(); cg.fill(CGRect(origin: .zero, size: size))
                UIColor.black.setFill(); cg.fill(CGRect(x: 0, y: 395, width: 1024, height: 38))
            case "Silver Eagle":
                UIColor(white: 0.78, alpha: 1).setFill(); cg.fill(CGRect(origin: .zero, size: size))
                secondary.setFill(); cg.fill(CGRect(x: 0, y: 350, width: 1024, height: 75)); accent.setFill(); cg.fill(CGRect(x: 0, y: 425, width: 1024, height: 22))
            default:
                secondary.setFill(); cg.fill(CGRect(x: 0, y: 350, width: 1024, height: 162))
                accent.setFill(); cg.fill(CGRect(x: 0, y: 335, width: 1024, height: 18))
            }
        }
    }

    private static func star(at center: CGPoint, in context: CGContext) {
        let path = UIBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) * .pi / 5 - .pi / 2, radius: CGFloat = index.isMultiple(of: 2) ? 35 : 15
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.close(); UIColor.white.setFill(); path.fill()
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0; Scanner(string: value).scanHexInt64(&number)
        self.init(red: CGFloat(number >> 16) / 255, green: CGFloat(number >> 8 & 0xff) / 255, blue: CGFloat(number & 0xff) / 255, alpha: 1)
    }
}
