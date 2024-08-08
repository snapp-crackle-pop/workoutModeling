import SwiftUI
import SceneKit

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
    @State private var isDashboardVisible = false
    @State private var selectedMuscleName: String?
    @State private var selectedExerciseForForm: Exercise? // For exercise form
    @State private var exerciseInputs: [ExerciseInstance] = [] // For storing inputs

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Adjust the USDZ scene height based on the dashboard visibility
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
                        highlightedNode: $highlightedNode,
                        selectedMuscleName: $selectedMuscleName
                    )
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxHeight: isDashboardVisible ? UIScreen.main.bounds.height * 0.6 : UIScreen.main.bounds.height)

                    DynamicDashboard(
                        isVisible: $isDashboardVisible,
                        muscleName: $selectedMuscleName,
                        exerciseData: exerciseData,
                        selectedExercise: $selectedExercise,
                        selectedExerciseForForm: $selectedExerciseForForm,
                        exerciseInputs: $exerciseInputs
                    )
                }

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
                if columns.count > 3 {
                    let muscleIDFromCSV = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let headTypeIDFromCSV = columns[7].trimmingCharacters(in: .whitespacesAndNewlines)

                    if muscleID == muscleIDFromCSV || muscleID == headTypeIDFromCSV {
                        muscleName = columns[6]  // Assuming column 2 contains the muscle name
                        let modelReferenceName = columns[11]
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

struct DynamicDashboard: View {
    @Binding var isVisible: Bool
    @Binding var muscleName: String?
    @ObservedObject var exerciseData: ExerciseData
    @Binding var selectedExercise: Exercise?
    @Binding var selectedExerciseForForm: Exercise?
    @Binding var exerciseInputs: [ExerciseInstance]

    var body: some View {
        VStack {
            HStack {
                Text(muscleName ?? "No Muscle Selected")
                    .font(.headline)
                    .padding()
                
                Spacer()
            }
            .background(Color.gray.opacity(0.8))
            .cornerRadius(10)
            .padding([.leading, .trailing, .top])

            // Exercise Explorer Tile
            ExerciseExplorerTile(
                selectedMuscleName: muscleName,
                exercises: exerciseData.exercises,
                onSelectExercise: { exercise in
                    selectedExercise = exercise
                }
            )

            // Exercise Form Tile
            ExerciseFormTile(
                selectedExercise: $selectedExerciseForForm,
                onSubmit: { exerciseInstance in
                    exerciseInputs.append(exerciseInstance)
                }
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: isVisible ? UIScreen.main.bounds.height * 0.3 : 50) // Adjustable height
        .background(Color.gray.opacity(0.9))
        .cornerRadius(15)
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < 0 { // Swipe up to expand
                        withAnimation {
                            isVisible = true
                        }
                    } else if value.translation.height > 0 { // Swipe down to collapse
                        withAnimation {
                            isVisible = false
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation {
                isVisible.toggle()
            }
        }
    }
}

struct ExerciseExplorerTile: View {
    var selectedMuscleName: String?
    var exercises: [Exercise]
    var onSelectExercise: (Exercise) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Exercise Explorer")
                .font(.headline)
                .padding([.leading, .top])
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(filteredExercises, id: \.exerciseID) { exercise in
                        ExerciseTile(exercise: exercise)
                            .onTapGesture {
                                onSelectExercise(exercise)
                            }
                    }
                }
                .padding()
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding([.leading, .trailing])
    }
    
    private var filteredExercises: [Exercise] {
        if let muscleName = selectedMuscleName, !muscleName.isEmpty {
            return exercises.filter { $0.targetMuscleIDs.contains(muscleName) }
        } else {
            return exercises
        }
    }
}

struct ExerciseTile: View {
    var exercise: Exercise
    
    var body: some View {
        VStack {
            Text(exercise.exerciseName)
                .font(.subheadline)
                .padding()
        }
        .frame(width: 100, height: 100)
        .background(Color.blue.opacity(0.8))
        .cornerRadius(10)
    }
}

struct ExerciseFormTile: View {
    @Binding var selectedExercise: Exercise?
    var onSubmit: (ExerciseInstance) -> Void
    
    @State private var reps: Int = 0
    @State private var weight: Int = 0
    @State private var duration: Int = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Exercise Form")
                .font(.headline)
                .padding([.leading, .top])
            
            if let exercise = selectedExercise {
                Form {
                    Section(header: Text(exercise.exerciseName)) {
                        switch exercise.formTypeID {
                        case 1: // Reps
                            Stepper("Reps: \(reps)", value: $reps)
                            
                        case 2: // WeightReps
                            Stepper("Weight: \(weight)", value: $weight)
                            Stepper("Reps: \(reps)", value: $reps)
                            
                        case 3: // Timed
                            Stepper("Duration: \(duration) sec", value: $duration)
                            
                        default:
                            Text("Invalid form type")
                        }
                        
                        Button("Submit") {
                            let newExerciseInstance = ExerciseInstance(
                                exerciseName: exercise.exerciseName,
                                inputDateTime: Date(),
                                reps: reps,
                                weight: weight,
                                duration: duration
                            )
                            onSubmit(newExerciseInstance)
                            resetForm()
                        }
                    }
                }
                .padding([.leading, .trailing, .bottom])
            } else {
                Text("Select an exercise to fill out the form.")
                    .padding([.leading, .trailing, .bottom])
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding([.leading, .trailing])
    }
    
    private func resetForm() {
        reps = 0
        weight = 0
        duration = 0
    }
}

// ExerciseInstance model to store submitted data
struct ExerciseInstance {
    var exerciseName: String
    var inputDateTime: Date
    var reps: Int?
    var weight: Int?
    var duration: Int?
}
