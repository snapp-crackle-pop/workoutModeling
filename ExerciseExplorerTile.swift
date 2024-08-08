import SwiftUI

struct ExerciseExplorerTile: View {
    @Binding var selectedExercise: Exercise? // Binding for the selected exercise
    var selectedMuscleName: String?
    var exercises: [Exercise]
    var onSelectExercise: (Exercise) -> Void
    var muscleDataLoader: MuscleDataLoader
    var exerciseInstances: [ExerciseInstance] // Data for charts

    // Define muscle group colors
    private let muscleGroupColors: [String: Color] = [
        "Neck": .red,
        "Shoulders": .green,
        "Upper Arms": .green,
        "Forearms": .blue,
        "Back": .orange,
        "Chest": .purple,
        "Waist": .brown,
        "Hips": .pink,
        "Thighs": .indigo,
        "Calves": .cyan
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack {
                ForEach(muscleGroups, id: \.self) { group in
                    VStack(alignment: .leading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(filteredExercises(for: group), id: \.exerciseID) { exercise in
                                    ExerciseTile(exercise: exercise, backgroundColor: muscleGroupColors[group] ?? Color.gray.opacity(0.0))
                                        .onTapGesture {
                                            selectedExercise = exercise // Update the selected exercise
                                            onSelectExercise(exercise)
                                        }
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding() // Add padding around each group
                    .scrollTargetLayout() // Enable layout support for snapping
                }
            }
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .safeAreaPadding(.vertical, 5)
        .frame(height: 150) // Adjust height to accommodate the explorer and charts
    }

    private var muscleGroups: [String] {
        let groups = exercises.flatMap { exercise in
            extractMuscleGroups(from: exercise.targetMuscleIDs)
        }
        return Array(Set(groups)).sorted() // Unique and sorted list of muscle groups
    }

    private func filteredExercises(for group: String) -> [Exercise] {
        let filtered = exercises.filter { exercise in
            let exerciseGroups = extractMuscleGroups(from: exercise.targetMuscleIDs)
            return exerciseGroups.contains(group)
        }
        
        // Log the exercises for the current muscle group
        //let exerciseNames = filtered.map { $0.exerciseName }
        //print("Muscle Group: \(group) - Exercises: \(exerciseNames.joined(separator: ", "))")
        
        return filtered
    }

    private func extractMuscleGroups(from muscleIDs: String) -> [String] {
        // Split the muscle IDs by commas, trim whitespaces, and remove any brackets
        let ids = muscleIDs
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Use compactMap to filter and transform the muscle IDs into muscle groups
        let groups: [String] = ids.compactMap { id -> String? in
            guard let intID = Int(id) else {
                //print("Invalid muscle ID: \(id)")
                return nil
            }

            if let muscleGroup = muscleDataLoader.muscles.first(where: { $0.muscleID == intID })?.muscleGroup {
                //print("Muscle ID: \(intID), Group: \(muscleGroup)")
                return muscleGroup
            } else {
                //print("No muscle group found for ID: \(intID)")
            }
            return nil
        }

        return groups
    }
}

struct ExerciseTile: View {
    var exercise: Exercise
    var backgroundColor: Color // Background color based on muscle group

    var body: some View {
        VStack {
            Text(exercise.exerciseName)
                .font(.subheadline)
                .padding()
                .multilineTextAlignment(.center) // Allow multiline
        }
        .frame(width: 120, height: 100)
        .background(backgroundColor)
        .cornerRadius(10)
    }
}
