import Foundation

struct Exercise: Identifiable {
    var id: String  // Using String for simplicity; ensure it matches CSV data
    var exerciseName: String
    var targetMuscleIDs: String
    var synergistMuscleIDs: String
    var dynamicStabilizerIDs: String
    var stabilizerIDs: String
    var antagonistStabilizerIDs: String
}

class ExerciseData: ObservableObject {
    @Published var exercises: [Exercise] = []

    init() {
        loadExercises()
    }

    private func loadExercises() {
        guard let path = Bundle.main.path(forResource: "exerciseData", ofType: "csv") else {
            print("exerciseData.csv file not found")
            return
        }

        do {
            let csvData = try String(contentsOfFile: path, encoding: .utf8)
            let rows = csvData.components(separatedBy: "\n").dropFirst() // Skip header

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 26 {  // Ensure there are enough columns
                    let id = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let exerciseName = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let targetMuscleIDs = columns[17].trimmingCharacters(in: .whitespacesAndNewlines)
                    let synergistMuscleIDs = columns[19].trimmingCharacters(in: .whitespacesAndNewlines)
                    let dynamicStabilizerIDs = columns[21].trimmingCharacters(in: .whitespacesAndNewlines)
                    let stabilizerIDs = columns[23].trimmingCharacters(in: .whitespacesAndNewlines)
                    let antagonistStabilizerIDs = columns[25].trimmingCharacters(in: .whitespacesAndNewlines)

                    let exercise = Exercise(id: id, exerciseName: exerciseName, targetMuscleIDs: targetMuscleIDs, synergistMuscleIDs: synergistMuscleIDs, dynamicStabilizerIDs: dynamicStabilizerIDs, stabilizerIDs: stabilizerIDs, antagonistStabilizerIDs: antagonistStabilizerIDs)
                    exercises.append(exercise)

                    // Debugging output
                    print("Loaded exercise: \(exerciseName) with target muscles: \(targetMuscleIDs)")
                }
            }
        } catch {
            print("Error reading exerciseData.csv file: \(error.localizedDescription)")
        }
    }

}
