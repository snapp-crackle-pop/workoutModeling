import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject private var exerciseData = ExerciseData()
    @State private var showingExerciseMenu = false
    @State private var showConsole = false
    @State private var selectedExercise: Exercise?
    
    // Muscle ID States
    @State private var targetMuscleIDs: [String] = []
    @State private var synergistMuscleIDs: [String] = []
    @State private var dynamicStabilizerMuscleIDs: [String] = []
    @State private var stabilizerMuscleIDs: [String] = []
    @State private var antagonistStabilizerMuscleIDs: [String] = []
    
    // Model References
    @State private var targetMuscleName: String?
    @State private var modelReferenceNames: [String] = []
    @State private var touchedMeshName: String = ""
    @State private var highlightedNode: SCNNode?
    @State private var isDashboardVisible = false
    @State private var selectedMuscleNames: [String] = [] // List of selected muscles
    @State private var selectedMuscleName: String? // Single selected muscle

    // Exercise References
    @State private var selectedExerciseForForm: Exercise? // For exercise form
    @State private var exerciseInputs: [ExerciseInstance] = [] // For storing inputs

    // Muscle Data Loader
    let muscleDataLoader = MuscleDataLoader() // Initialize muscleDataLoader
    
    // State for active muscle groups
    @State private var activeMuscleGroups: [String] = [] // Added activeMuscleGroups state

    // State to toggle the ExerciseSelector visibility
    @State private var showSelector = false

    // Muscle group colors
    private let muscleGroupColors: [String: UIColor] = [
        "Neck": UIColor(named: "NeckColor") ?? .red,
        "Shoulders": UIColor(named: "ShouldersColor") ?? .green,
        "Upper Arms": UIColor(named: "UpperArmsColor") ?? .blue,
        "Forearms": UIColor(named: "ForearmsColor") ?? .orange,
        "Back": UIColor(named: "BackColor") ?? .purple,
        "Chest": UIColor(named: "ChestColor") ?? .yellow,
        "Waist": UIColor(named: "WaistColor") ?? .brown,
        "Hips": UIColor(named: "HipsColor") ?? .systemPink,
        "Thighs": UIColor(named: "ThighsColor") ?? .systemIndigo,
        "Calves": UIColor(named: "CalvesColor") ?? .cyan
    ]

    
    // State to manage the button's position
    @State private var selectorButtonPosition: CGPoint = CGPoint(x: 50, y: UIScreen.main.bounds.height - 150) // Initial position lower left

    var body: some View {
        NavigationView {
            ZStack {
                
                LinearGradient(
                    gradient: Gradient(colors: [.black, .modelBackground]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .edgesIgnoringSafeArea(.all)
                
                VStack {
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
                        activeMuscleGroups: $activeMuscleGroups, // Pass activeMuscleGroups
                        muscleGroupColors: muscleGroupColors // Pass muscleGroupColors
                    )
                    .edgesIgnoringSafeArea(.all)

                    DynamicDashboard(
                        isVisible: $isDashboardVisible,
                        muscleNames: $selectedMuscleNames,
                        exerciseData: exerciseData,
                        selectedExercise: $selectedExercise,
                        selectedExerciseForForm: $selectedExerciseForForm,
                        exerciseInputs: $exerciseInputs,
                        onSelectExercise: { exercise in
                            self.selectedExercise = exercise
                            self.updateMuscleIDs(for: exercise)
                            selectedExerciseForForm = exercise
                        },
                        muscleDataLoader: muscleDataLoader
                    )
                }

                // Top right corner: "Deselect All" button
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            deselectAll()
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    Spacer()
                }

                // Draggable "Toggle Selector" button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                    }
                }
                .overlay(
                    DraggableButton(
                        position: $selectorButtonPosition,
                        action: { showSelector.toggle() },
                        imageName: showSelector ? "xmark.circle.fill" : "plus.circle.fill"
                    )
                )

                // Conditionally show the ExerciseSelector
                if showSelector {
                    ExerciseSelector(
                                        selectedExercise: $selectedExercise,
                                        showSelector: $showSelector,
                                        activeMuscleGroups: $activeMuscleGroups, // Add this in the correct order
                                        exercises: exerciseData.exercises,
                                        onSelectExercise: { exercise in
                                            // Handle selection
                                            selectedExercise = exercise
                                            self.selectedExercise = exercise
                                            self.updateMuscleIDs(for: exercise)
                                            selectedExerciseForForm = exercise
                                            showSelector = true // Hide selector after selection
                                        },
                                        muscleDataLoader: muscleDataLoader // Pass muscleDataLoader here
                                    )
                }
            }
        }
        .onAppear {
            loadSelectorButtonPosition() // Load position on view appear
        }
    }

    func deselectAll() {
        // Reset selected exercise and muscle states
        selectedExercise = nil
        selectedExerciseForForm = nil
        targetMuscleIDs = []
        synergistMuscleIDs = []
        dynamicStabilizerMuscleIDs = []
        stabilizerMuscleIDs = []
        antagonistStabilizerMuscleIDs = []
        selectedMuscleName = nil
        selectedMuscleNames = []
        activeMuscleGroups = []
    }

    func updateMuscleIDs(for exercise: Exercise?) {
        guard let exercise = exercise else { return }
        targetMuscleIDs = extractMuscleIDs(from: exercise.targetMuscleIDs)
        synergistMuscleIDs = extractMuscleIDs(from: exercise.synergistMuscleIDs)
        dynamicStabilizerMuscleIDs = extractMuscleIDs(from: exercise.dynamicStabilizerMuscleIDs)
        stabilizerMuscleIDs = extractMuscleIDs(from: exercise.stabilizerMuscleIDs)
        antagonistStabilizerMuscleIDs = extractMuscleIDs(from: exercise.antagonistStabilizerMuscleIDs)
    }

    func extractMuscleIDs(from targetMuscleIDs: String) -> [String] {
        let components = targetMuscleIDs
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .components(separatedBy: "] [")

        let cleanedIDs = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return cleanedIDs.filter { !$0.isEmpty }
    }

    func findModelReferenceNames(for muscleID: String) -> (String, [String]) {
        guard let path = Bundle.main.path(forResource: "MuscleCoorelations", ofType: "csv") else {
            print("MuscleCoorelations.csv file not found")
            return ("", [])
        }

        var muscleName = ""
        var modelReferenceNames: [String] = []

        do {
            let csvData = try String(contentsOfFile: path)
            let rows = csvData.components(separatedBy: "\n").dropFirst()

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count > 11 {
                    let muscleIDFromCSV = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let headTypeIDFromCSV = columns[7].trimmingCharacters(in: .whitespacesAndNewlines)

                    if muscleID == muscleIDFromCSV || muscleID == headTypeIDFromCSV {
                        muscleName = columns[6]
                        let modelReferenceName = columns[11].trimmingCharacters(in: .whitespacesAndNewlines)
                        modelReferenceNames.append(modelReferenceName)
                    }
                }
            }
        } catch {
            print("Error reading MuscleCoorelations.csv file: \(error.localizedDescription)")
        }

        return (muscleName, modelReferenceNames)
    }

    // Load selector button position from UserDefaults
    func loadSelectorButtonPosition() {
        let x = UserDefaults.standard.double(forKey: "selectorButtonPositionX")
        let y = UserDefaults.standard.double(forKey: "selectorButtonPositionY")
        if x != 0 && y != 0 {
            selectorButtonPosition = CGPoint(x: x, y: y)
        }
    }

    // Save selector button position to UserDefaults
    func saveSelectorButtonPosition() {
        UserDefaults.standard.set(selectorButtonPosition.x, forKey: "selectorButtonPositionX")
        UserDefaults.standard.set(selectorButtonPosition.y, forKey: "selectorButtonPositionY")
    }
}

struct DraggableButton: View {
    @Binding var position: CGPoint
    var action: () -> Void
    var imageName: String
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 24))
            .foregroundColor(.gray)
            .opacity(0.6)
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.dragOffset = value.translation
                    }
                    .onEnded { value in
                        self.position.x += value.translation.width
                        self.position.y += value.translation.height
                        self.dragOffset = .zero
                        savePosition() // Save position on drag end
                    }
            )
            .onTapGesture {
                action()
            }
            .padding()
    }
    
    private func savePosition() {
        UserDefaults.standard.set(position.x, forKey: "selectorButtonPositionX")
        UserDefaults.standard.set(position.y, forKey: "selectorButtonPositionY")
    }
}
