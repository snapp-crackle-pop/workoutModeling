import SwiftUI
import SceneKit

struct USDZSceneView: UIViewRepresentable {
    @Binding var selectedExercise: Exercise?
    @Binding var targetMuscleIDs: [String]
    @Binding var synergistMuscleIDs: [String]
    @Binding var dynamicStabilizerMuscleIDs: [String]
    @Binding var stabilizerMuscleIDs: [String]
    @Binding var antagonistStabilizerMuscleIDs: [String]
    @Binding var targetMuscleName: String?
    @Binding var modelReferenceNames: [String]
    @Binding var touchedMeshName: String
    @Binding var highlightedNode: SCNNode?
    @Binding var selectedMuscleName: String? // Use a single string for selected muscle
    @Binding var activeMuscleGroups: [String] // Active muscle groups
    var muscleGroupColors: [String: UIColor] // Muscle group colors

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = setupScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear // Set SCNView background to clear

        // Add tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if activeMuscleGroups.isEmpty {
            // No active muscle groups, color based on selected exercise
            if let _ = selectedExercise {
                colorMeshesForExercise(sceneView: uiView)
            } else {
                // No exercise selected, reset the model to default
                resetMeshColors(sceneView: uiView)
            }
        } else {
            // Active muscle groups present, color based on groups
            colorMeshesForGroups(sceneView: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func setupScene() -> SCNScene {
        let scene = SCNScene()

        // Load the USDZ file
        if let usdzScene = SCNScene(named: "finalanatomy.usdz") {
            let usdzNode = SCNNode()
            for child in usdzScene.rootNode.childNodes {
                usdzNode.addChildNode(child)
            }

            // Add the usdzNode to the scene
            scene.rootNode.addChildNode(usdzNode)

            // Load mesh reference names from CSV
            let meshNames = loadMeshReferenceNames()
            assignNamesToNodes(rootNode: usdzNode, meshNames: meshNames)

            // Add a camera to the scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()

            // Center the camera on the object
            let (minVec, maxVec) = usdzNode.boundingBox
            let modelHeight = maxVec.y - minVec.y
            cameraNode.position = SCNVector3(0, modelHeight / 1.75, modelHeight * 1.5)
            scene.rootNode.addChildNode(cameraNode)

            // Set the camera's field of view to fit the object
            let fitCamera = cameraNode.camera!
            fitCamera.fieldOfView = 50
            fitCamera.automaticallyAdjustsZRange = true
        } else {
            print("Failed to load the USDZ file.")
        }

        // Add ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // Add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        let secondLightNode = SCNNode()
        secondLightNode.light = SCNLight()
        secondLightNode.light?.type = .omni
        secondLightNode.position = SCNVector3(x: 0, y: 10, z: -10)
        scene.rootNode.addChildNode(secondLightNode)

        return scene
    }

    private func assignNamesToNodes(rootNode: SCNNode, meshNames: [String]) {
        let meshNames = loadMeshReferenceNames().sorted()

        var nodeIndex = 0
        rootNode.enumerateChildNodes { (node, _) in
            if let _ = node.geometry, nodeIndex < meshNames.count {
                node.name = meshNames[nodeIndex]
                nodeIndex += 1
            }
            node.enumerateChildNodes { (child, _) in
                if let _ = child.geometry, nodeIndex < meshNames.count {
                    child.name = meshNames[nodeIndex]
                    nodeIndex += 1
                }
            }
        }
    }

    private func resetMeshColors(sceneView: SCNView) {
        guard let scene = sceneView.scene else { return }

        // Reset all meshes to default color
        scene.rootNode.enumerateChildNodes { (node, _) in
            if let _ = node.geometry {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(named:"ModelGrayColor") ?? .systemGray
                node.geometry?.materials = [material]
            }
        }
    }

    private func colorMeshesForExercise(sceneView: SCNView) {
        guard let scene = sceneView.scene else { return }

        // Reset all meshes to default color
        resetMeshColors(sceneView: sceneView)

        // Helper function to apply color to specific nodes
        func applyColor(to nodes: [String], color: UIColor) {
            for modelReferenceName in nodes {
                scene.rootNode.enumerateChildNodes { (node, _) in
                    if let _ = node.geometry, node.name == modelReferenceName {
                        let material = SCNMaterial()
                        material.diffuse.contents = color
                        node.geometry?.materials = [material]
                    }
                }
            }
        }

        // Apply colors based on the selected exercise
        applyColor(to: extractModelReferenceNames(from: targetMuscleIDs), color: UIColor(named: "TargetMuscleColor") ?? .systemRed) // Target muscles
        applyColor(to: extractModelReferenceNames(from: synergistMuscleIDs), color: UIColor(named: "SynergistMuscleColor") ?? .systemPink) // Synergist
        applyColor(to: extractModelReferenceNames(from: dynamicStabilizerMuscleIDs), color: UIColor(named: "DynamicStabilizerMuscleColor") ?? .orange) // Dynamic Stabilizer
        applyColor(to: extractModelReferenceNames(from: stabilizerMuscleIDs), color: UIColor(named: "StabilizerMuscleColor") ?? .yellow) // Stabilizer
        applyColor(to: extractModelReferenceNames(from: antagonistStabilizerMuscleIDs), color: UIColor(named: "AntagonistStabilizerMuscleColor") ?? .cyan) // Antagonist Stabilizer

        // Highlight the selected node
        if let highlightedNode = highlightedNode {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(named:"SelectionColor") ?? .systemGreen
            highlightedNode.geometry?.materials = [material]
        }
    }

    private func colorMeshesForGroups(sceneView: SCNView) {
        guard let scene = sceneView.scene else { return }

        // Reset all meshes to default color
        resetMeshColors(sceneView: sceneView)

        // Apply colors based on the active muscle groups
        applyColorsForActiveMuscleGroups(scene: scene)
    }

    private func applyColorsForActiveMuscleGroups(scene: SCNScene) {
        // Load the muscle correlations data
        let muscleCorrelations = loadMuscleCorrelations()

        // Helper function to apply color to specific nodes
        func applyColor(to nodes: [String], color: UIColor) {
            for modelReferenceName in nodes {
                scene.rootNode.enumerateChildNodes { (node, _) in
                    if let _ = node.geometry, node.name == modelReferenceName {
                        let material = SCNMaterial()
                        material.diffuse.contents = color
                        node.geometry?.materials = [material]
                    }
                }
            }
        }

        for muscleGroup in activeMuscleGroups {
            if let correlatedData = muscleCorrelations[muscleGroup] {
                let color = muscleGroupColors[muscleGroup] ?? UIColor.red // Default color if not found
                applyColor(to: correlatedData.map { $0.modelReferenceName }, color: color)
            }
        }
    }

    private func loadMuscleCorrelations() -> [String: [(headTypeID: String, modelReferenceName: String)]] {
        guard let path = Bundle.main.path(forResource: "MuscleCoorelations", ofType: "csv") else {
            print("MuscleCoorelations.csv file not found")
            return [:]
        }

        var muscleCorrelations: [String: [(headTypeID: String, modelReferenceName: String)]] = [:]

        do {
            let csvData = try String(contentsOfFile: path)
            let rows = csvData.components(separatedBy: "\n").dropFirst()

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count > 11 {
                    let muscleGroup = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                    let headTypeID = columns[7].trimmingCharacters(in: .whitespacesAndNewlines)
                    let modelReferenceName = columns[11].trimmingCharacters(in: .whitespacesAndNewlines)

                    muscleCorrelations[muscleGroup, default: []].append((headTypeID, modelReferenceName))
                }
            }
        } catch {
            print("Error reading MuscleCoorelations.csv file: \(error.localizedDescription)")
        }

        return muscleCorrelations
    }

    func extractModelReferenceNames(from muscleIDs: [String]) -> [String] {
        // Load and parse the CSV file to get model reference names
        guard let path = Bundle.main.path(forResource: "MuscleCoorelations", ofType: "csv") else {
            print("MuscleCoorelations.csv file not found")
            return []
        }

        var modelReferenceNames: [String] = []

        do {
            let csvData = try String(contentsOfFile: path)
            let rows = csvData.components(separatedBy: "\n").dropFirst()

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count > 3 {
                    let muscleIDFromCSV = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let headTypeIDFromCSV = columns[7].trimmingCharacters(in: .whitespacesAndNewlines)

                    if muscleIDs.contains(muscleIDFromCSV) || muscleIDs.contains(headTypeIDFromCSV) {
                        let modelReferenceName = columns[11]
                        modelReferenceNames.append(modelReferenceName)
                    }
                }
            }
        } catch {
            print("Error reading muscleHeadData.csv file: \(error.localizedDescription)")
        }

        return modelReferenceNames
    }

    class Coordinator: NSObject {
        var parent: USDZSceneView

        init(_ parent: USDZSceneView) {
            self.parent = parent
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let sceneView = gestureRecognizer.view as! SCNView
            let location = gestureRecognizer.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])

            if let hitResult = hitResults.first {
                let node = hitResult.node
                parent.touchedMeshName = node.name ?? "Unnamed"

                // Reset previous highlight
                if let previousNode = parent.highlightedNode {
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.white
                    previousNode.geometry?.materials = [material]
                }

                // Set new highlight
                parent.highlightedNode = node
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(named:"SelectionColor") ?? .systemGreen
                node.geometry?.materials = [material]

                // Update selected muscle name
                parent.selectedMuscleName = node.name
            } else {
                // No mesh was hit; clear selection
                parent.touchedMeshName = "None"
                parent.highlightedNode = nil
                parent.selectedMuscleName = nil
            }
        }
    }

    func loadMeshReferenceNames() -> [String] {
        guard let path = Bundle.main.path(forResource: "mesh_names", ofType: "csv") else {
            print("mesh_names.csv file not found")
            return []
        }

        var meshNames: [String] = []

        do {
            let csvData = try String(contentsOfFile: path, encoding: .utf8)
            let rows = csvData.components(separatedBy: "\n").dropFirst() // Skip header

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if let meshName = columns.first?.trimmingCharacters(in: .whitespacesAndNewlines), !meshName.isEmpty {
                    meshNames.append(meshName)
                }
            }
        } catch {
            print("Error reading mesh_names.csv file: \(error.localizedDescription)")
        }

        return meshNames
    }
}

struct USDZSceneViewContainer: View {
    @State private var selectedExercise: Exercise?
    @State private var targetMuscleIDs: [String] = []
    @State private var synergistMuscleIDs: [String] = []
    @State private var dynamicStabilizerMuscleIDs: [String] = []
    @State private var stabilizerMuscleIDs: [String] = []
    @State private var antagonistStabilizerMuscleIDs: [String] = []
    @State private var targetMuscleName: String?
    @State private var modelReferenceNames: [String] = []
    @State private var touchedMeshName: String = ""
    @State private var highlightedNode: SCNNode?
    @State private var selectedMuscleName: String?
    @State private var activeMuscleGroups: [String] = []
    
    var muscleGroupColors: [String: UIColor] = [
        "Neck": .red,
        "Shoulders": .green,
        "Upper Arms": .blue,
        "Forearms": .orange,
        "Back": .purple,
        "Chest": .yellow,
        "Waist": .brown,
        "Hips": .systemPink,
        "Thighs": .systemIndigo,
        "Calves": .cyan
    ]

    var body: some View {
        ZStack {
            Color.green.edgesIgnoringSafeArea(.all) // Set the background color to green
            USDZSceneView(
                selectedExercise: $selectedExercise,
                targetMuscleIDs: $targetMuscleIDs,
                synergistMuscleIDs: $synergistMuscleIDs,
                dynamicStabilizerMuscleIDs: $dynamicStabilizerMuscleIDs,
                stabilizerMuscleIDs: $stabilizerMuscleIDs,
                antagonistStabilizerMuscleIDs: $antagonistStabilizerMuscleIDs,
                targetMuscleName: $targetMuscleName,
                modelReferenceNames: $modelReferenceNames,
                touchedMeshName: $touchedMeshName,
                highlightedNode: $highlightedNode,
                selectedMuscleName: $selectedMuscleName,
                activeMuscleGroups: $activeMuscleGroups,
                muscleGroupColors: muscleGroupColors
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
