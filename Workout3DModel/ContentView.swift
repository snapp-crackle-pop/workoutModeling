import SwiftUI
import SceneKit
import ZIPFoundation

struct ContentView: View {
    @StateObject private var exerciseData = ExerciseData()
    @State private var showingExerciseMenu = false
    @State private var showConsole = false
    @State private var selectedExercise: Exercise?
    @State private var dependentMuscleIDs: [String] = []
    @State private var synergistMuscleIDs: [String] = []
    @State private var dynamicStabilizerIDs: [String] = []
    @State private var stabilizerIDs: [String] = []
    @State private var antagonistStabilizerIDs: [String] = []
    @State private var dependentMuscleName: String?
    @State private var modelReferenceNames: [String] = []
    @State private var touchedMeshName: String = ""
    @State private var highlightedNode: SCNNode?

    var body: some View {
        NavigationView {
            ZStack {
                USDZSceneView(
                    selectedExercise: $selectedExercise,
                    dependentMuscleIDs: $dependentMuscleIDs,
                    synergistMuscleIDs: $synergistMuscleIDs,
                    dynamicStabilizerIDs: $dynamicStabilizerIDs,
                    stabilizerIDs: $stabilizerIDs,
                    antagonistStabilizerIDs: $antagonistStabilizerIDs,
                    dependentMuscleName: $dependentMuscleName,
                    modelReferenceNames: $modelReferenceNames,
                    touchedMeshName: $touchedMeshName,
                    highlightedNode: $highlightedNode
                )
                .edgesIgnoringSafeArea(.all)

                VStack {
                    if showConsole {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Latest Selection (Exercise): \(selectedExercise?.exerciseName ?? "None")")
                                .font(.headline)

                            Text("Target Muscle (Muscle_ID): \(dependentMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Synergist Muscle IDs: \(synergistMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Dynamic Stabilizer IDs: \(dynamicStabilizerIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Stabilizer IDs: \(stabilizerIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Antagonist Stabilizer IDs: \(antagonistStabilizerIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Dependent Muscle Name (Muscle): \(dependentMuscleName ?? "None")")
                                .font(.subheadline)

                            Text("Model Reference Name(s): \(modelReferenceNames.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Touched Mesh Name: \(touchedMeshName)")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                    }

                    Spacer()
                }

                VStack {
                    HStack {
                        Button(action: {
                            showConsole.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                        }

                        Spacer()
                    }

                    Spacer()

                    HStack {
                        Button(action: {
                            showingExerciseMenu.toggle()
                        }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .bold))
                                )
                        }
                        .padding()
                        .actionSheet(isPresented: $showingExerciseMenu) {
                            ActionSheet(
                                title: Text("Select Exercise"),
                                buttons: exerciseButtons()
                            )
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }

    func exerciseButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = exerciseData.exercises.map { exercise in
            ActionSheet.Button.default(Text(exercise.exerciseName)) {
                selectedExercise = exercise
                // Set muscle details
                dependentMuscleIDs = ContentView.extractMuscleIDs(from: exercise.targetMuscleIDs)
                synergistMuscleIDs = ContentView.extractMuscleIDs(from: exercise.synergistMuscleIDs)
                dynamicStabilizerIDs = ContentView.extractMuscleIDs(from: exercise.dynamicStabilizerIDs)
                stabilizerIDs = ContentView.extractMuscleIDs(from: exercise.stabilizerIDs)
                antagonistStabilizerIDs = ContentView.extractMuscleIDs(from: exercise.antagonistStabilizerIDs)

                var muscleNames = [String]()
                var modelRefs = [String]()

                for muscleID in dependentMuscleIDs {
                    let (muscleName, modelRef) = findModelReferenceNames(for: muscleID)
                    muscleNames.append(muscleName)
                    modelRefs.append(contentsOf: modelRef)
                }

                dependentMuscleName = muscleNames.joined(separator: ", ")
                modelReferenceNames = modelRefs
            }
        }
        buttons.append(.cancel(Text("Cancel")))
        return buttons
    }

    static func extractMuscleIDs(from targetMuscleIDs: String) -> [String] {
        // Split the string into components based on space and brackets
        let components = targetMuscleIDs
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .components(separatedBy: "] [")

        // Trim whitespace and brackets from each component
        let cleanedIDs = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        // Filter out any empty strings
        return cleanedIDs.filter { !$0.isEmpty }
    }

    func findModelReferenceNames(for muscleID: String) -> (String, [String]) {
        // Load and parse the CSV file, returning a list of model reference names for the given muscle ID
        guard let path = Bundle.main.path(forResource: "muscleHeadData", ofType: "csv") else {
            print("muscleHeadData.csv file not found")
            return ("", [])
        }

        var muscleName = ""
        var modelReferenceNames: [String] = []

        do {
            let csvData = try String(contentsOfFile: path)
            let rows = csvData.components(separatedBy: "\n").dropFirst()

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count > 3 {
                    let muscleIDFromCSV = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let headTypeIDFromCSV = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)

                    if muscleID == muscleIDFromCSV || muscleID == headTypeIDFromCSV {
                        muscleName = columns[2]  // Assuming column 2 contains the muscle name
                        let modelReferenceName = columns[7]
                        modelReferenceNames.append(modelReferenceName)
                    }
                }
            }
        } catch {
            print("Error reading muscleHeadData.csv file: \(error.localizedDescription)")
        }

        return (muscleName, modelReferenceNames)
    }
}

struct USDZSceneView: UIViewRepresentable {
    @Binding var selectedExercise: Exercise?
    @Binding var dependentMuscleIDs: [String]
    @Binding var synergistMuscleIDs: [String]
    @Binding var dynamicStabilizerIDs: [String]
    @Binding var stabilizerIDs: [String]
    @Binding var antagonistStabilizerIDs: [String]
    @Binding var dependentMuscleName: String?
    @Binding var modelReferenceNames: [String]
    @Binding var touchedMeshName: String
    @Binding var highlightedNode: SCNNode?

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        
        // Create a new scene
        let scene = SCNScene()

        // Load the USDZ file
        if let usdzScene = SCNScene(named: "finalanatomy.usdz") {
            let usdzNode = SCNNode()
            for child in usdzScene.rootNode.childNodes {
                usdzNode.addChildNode(child)
            }
            
            // Add the usdzNode to the scene
            scene.rootNode.addChildNode(usdzNode)
            
            // Add a camera to the scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            
            // Center the camera on the object
            let (minVec, maxVec) = usdzNode.boundingBox
            let modelHeight = maxVec.y - minVec.y
            cameraNode.position = SCNVector3(0, modelHeight / 2, modelHeight * 1.5)
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

        // Set up the scene view
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        
        // Add tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Assign names to nodes based on the CSV file
        assignNamesToNodes(sceneView: sceneView)
        
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the scene view when the selected exercise changes
        colorMeshes(sceneView: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func colorMeshes(sceneView: SCNView) {
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
                    }
                }
            }
        }

        // Apply colors based on muscle types
        applyColor(to: extractModelReferenceNames(from: dependentMuscleIDs), color: UIColor.systemRed) // Target muscles
        applyColor(to: extractModelReferenceNames(from: synergistMuscleIDs), color: UIColor.systemPink) // Synergist
        applyColor(to: extractModelReferenceNames(from: dynamicStabilizerIDs), color: UIColor.orange) // Dynamic Stabilizer
        applyColor(to: extractModelReferenceNames(from: stabilizerIDs), color: UIColor.yellow) // Stabilizer
        applyColor(to: extractModelReferenceNames(from: antagonistStabilizerIDs), color: UIColor.cyan) // Antagonist Stabilizer

        // Highlight the selected node
        if let highlightedNode = highlightedNode {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.green
            highlightedNode.geometry?.materials = [material]
        }
    }

    // This function will extract the correct model reference names for each muscle ID
    func extractModelReferenceNames(from muscleIDs: [String]) -> [String] {
        // Load and parse the CSV file to get model reference names
        guard let path = Bundle.main.path(forResource: "muscleHeadData", ofType: "csv") else {
            print("muscleHeadData.csv file not found")
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
                    let headTypeIDFromCSV = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)

                    if muscleIDs.contains(muscleIDFromCSV) || muscleIDs.contains(headTypeIDFromCSV) {
                        let modelReferenceName = columns[7]
                        modelReferenceNames.append(modelReferenceName)
                    }
                }
            }
        } catch {
            print("Error reading muscleHeadData.csv file: \(error.localizedDescription)")
        }

        return modelReferenceNames
    }


    func assignNamesToNodes(sceneView: SCNView) {
        guard let scene = sceneView.scene else { return }

        // Load and sort names from the CSV file
        let meshNames = loadMeshReferenceNames().sorted()

        // Assign names to nodes in the scene based on their index
        var nodeIndex = 0
        scene.rootNode.enumerateChildNodes { (node, _) in
            if let _ = node.geometry, nodeIndex < meshNames.count {
                node.name = meshNames[nodeIndex]
                nodeIndex += 1
            }
            // Recursively assign names to child nodes
            node.enumerateChildNodes { (child, _) in
                if let _ = child.geometry, nodeIndex < meshNames.count {
                    child.name = meshNames[nodeIndex]
                    nodeIndex += 1
                }
            }
        }
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
            }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

