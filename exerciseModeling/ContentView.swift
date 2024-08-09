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
    
    // State for showing/hiding the selector
    @State private var showSelector = false

    var body: some View {
        NavigationView {
            ZStack {
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
                        selectedMuscleName: $selectedMuscleName // Single muscle name
                    )
                    .edgesIgnoringSafeArea(.all)

                    DynamicDashboard(
                        isVisible: $isDashboardVisible,
                        muscleNames: $selectedMuscleNames, // List of selected muscles
                        exerciseData: exerciseData,
                        selectedExercise: $selectedExercise,
                        selectedExerciseForForm: $selectedExerciseForForm,
                        exerciseInputs: $exerciseInputs,
                        onSelectExercise: { exercise in
                            self.selectedExercise = exercise
                            self.updateMuscleIDs(for: exercise)
                            selectedExerciseForForm = exercise
                        },
                        muscleDataLoader: muscleDataLoader // Pass muscleDataLoader here
                    )
                }

                ExerciseSelector(
                    selectedExercise: $selectedExercise,
                    showSelector: $showSelector, // Pass the showSelector binding
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

                VStack {
                    if showConsole {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Latest Selection (Exercise): \(selectedExercise?.exerciseName ?? "None")")
                                .font(.headline)

                            Text("Target Muscle (Muscle_ID): \(targetMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Synergist Muscle IDs: \(synergistMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Dynamic Stabilizer IDs: \(dynamicStabilizerMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Stabilizer IDs: \(stabilizerMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Antagonist Stabilizer IDs: \(antagonistStabilizerMuscleIDs.joined(separator: ", "))")
                                .font(.subheadline)

                            Text("Dependent Muscle Name (Muscle): \(targetMuscleName ?? "None")")
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
                            showSelector.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .padding()
                        }
                        Spacer()
                    }
                    .padding(.bottom, 50) // Adjust to be above the DynamicDashboard
                }
            }
        }
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
}
