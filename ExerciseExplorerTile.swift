import SwiftUI

struct ExerciseExplorerTile: View {
    @Binding var selectedExercise: Exercise? // Binding for the selected exercise
    @State private var selectedGroup: String? // State for the selected group
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
                if let selectedGroup = selectedGroup {
                    // Show exercises for the selected group
                    VStack(alignment: .leading) {
                        Text(selectedGroup)
                            .font(.headline)
                            .padding()

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(filteredExercises(for: selectedGroup), id: \.exerciseID) { exercise in
                                    ExerciseTile(exercise: exercise, backgroundColor: muscleGroupColors[selectedGroup] ?? Color.gray.opacity(0.0))
                                        .onTapGesture {
                                            selectedExercise = exercise // Update the selected exercise
                                            onSelectExercise(exercise)
                                        }
                                }
                            }
                        }
                        .padding()

                        Button(action: {
                            self.selectedGroup = nil
                        }) {
                            Text("Back to Muscle Groups")
                                .font(.caption)
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                } else {
                    // Show muscle group nodes
                    ForEach(muscleGroups, id: \.self) { group in
                        Button(action: {
                            self.selectedGroup = group
                        }) {
                            Text(group)
                                .font(.headline)
                                .padding()
                                .background(muscleGroupColors[group] ?? Color.gray.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 5)
            .frame(height: 150) // Adjust height to accommodate the explorer and charts
        }
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
                return nil
            }

            if let muscleGroup = muscleDataLoader.muscles.first(where: { $0.muscleID == intID })?.muscleGroup {
                return muscleGroup
            } else {
                return nil
            }
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
                .font(.caption2)
                .multilineTextAlignment(.center) // Allow multiline
        }
        .frame(width: 100, height: 60)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}
