//
//  exerciseData.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/4/24.
//

import Foundation

struct Exercise: Identifiable, Hashable {
    var id: String { exerciseID } // Use exerciseID as the unique identifier
    var exerciseID: String
    var exerciseName: String
    var targetMuscleIDs: String
    var synergistMuscleIDs: String
    var dynamicStabilizerMuscleIDs: String
    var stabilizerMuscleIDs: String
    var antagonistStabilizerMuscleIDs: String
    var formTypeID: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(exerciseID)
        hasher.combine(exerciseName)
    }
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

                // Ensure there are enough columns in the CSV
                if columns.count >= 25 {
                    // Trim each column to remove leading and trailing whitespace
                    let trimmedColumns = columns.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                    // Extract data from columns using proper index
                    let exerciseName = trimmedColumns[0]
                    let exerciseID = trimmedColumns[1]
                    let formTypeID = trimmedColumns[7]
                    let targetMuscleIDs = trimmedColumns[17]
                    let synergistMuscleIDs = trimmedColumns[19]
                    let dynamicStabilizerMuscleIDs = trimmedColumns[21]
                    let stabilizerMuscleIDs = trimmedColumns[23]
                    let antagonistStabilizerMuscleIDs = trimmedColumns[25]

                    // Create and append the exercise
                    let exercise = Exercise(
                        exerciseID: exerciseID,
                        exerciseName: exerciseName,
                        targetMuscleIDs: targetMuscleIDs,
                        synergistMuscleIDs: synergistMuscleIDs,
                        dynamicStabilizerMuscleIDs: dynamicStabilizerMuscleIDs,
                        stabilizerMuscleIDs: stabilizerMuscleIDs,
                        antagonistStabilizerMuscleIDs: antagonistStabilizerMuscleIDs,
                        formTypeID: formTypeID
                    )
                    exercises.append(exercise)

                    // Debugging output
                    print("Loaded exercise: \(exerciseName) with target muscles: \(targetMuscleIDs)")
                    print("Loaded exercise: \(exerciseName) with synergist muscles: \(synergistMuscleIDs)")
                } else {
                    print("Invalid row: \(row)")
                }
            }
        } catch {
            print("Error reading exerciseData.csv file: \(error.localizedDescription)")
        }
    }
}
