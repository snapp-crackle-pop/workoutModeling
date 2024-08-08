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

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = setupScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black

        // Add tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        colorMeshes(sceneView: uiView)
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

    private func colorMeshes(sceneView: SCNView) {
        guard let scene = sceneView.scene else { return }

        // Reset all meshes to default color
        scene.rootNode.enumerateChildNodes { (node, _) in
            if let _ = node.geometry {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.white
                node.geometry?.materials = [material]
            }
        }

        // Helper function to apply color to specific nodes
        func applyColor(to nodes: [String], color: UIColor) {
            for modelReferenceName in nodes {
                scene.rootNode.enumerateChildNodes { (node, _) in
                    if let _ = node.geometry, node.name == modelReferenceName {
                        let material = SCNMaterial()
                        material.diffuse.contents = color
                        node.geometry?.materials = [material]
                        // Log which node is being colored and the color applied
                        //print("Coloring node: \(node.name ?? "Unnamed") with color: \(color)")
                    }
                }
            }
        }

        // Apply colors based on muscle types
        //print("Applying color for target muscles")
        applyColor(to: extractModelReferenceNames(from: targetMuscleIDs), color: UIColor.systemRed) // Target muscles

        //print("Applying color for synergist muscles")
        applyColor(to: extractModelReferenceNames(from: synergistMuscleIDs), color: UIColor.systemPink) // Synergist

        //print("Applying color for dynamic stabilizers")
        applyColor(to: extractModelReferenceNames(from: dynamicStabilizerMuscleIDs), color: UIColor.orange) // Dynamic Stabilizer

        //print("Applying color for stabilizers")
        applyColor(to: extractModelReferenceNames(from: stabilizerMuscleIDs), color: UIColor.yellow) // Stabilizer

        //print("Applying color for antagonist stabilizers")
        applyColor(to: extractModelReferenceNames(from: antagonistStabilizerMuscleIDs), color: UIColor.cyan) // Antagonist Stabilizer

        // Highlight the selected node
        if let highlightedNode = highlightedNode {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.green
            highlightedNode.geometry?.materials = [material]
            //print("Highlighting node: \(highlightedNode.name ?? "Unnamed") with green")
        }
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

        return modelReferenceNames // this is the functional output for modelReferenceNames. For each muscleID we are returning the modelReferenceName from the muscleCoorelations list.
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
                material.diffuse.contents = UIColor.green
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
    }

    func loadMeshReferenceNames() -> [String] { // is this used?
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

