//
//  muscleDataLoader.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/4/24.
//

import Foundation

struct MuscleData: Identifiable {
    var id: Int
    var muscleName: String
    var muscleID: Int
    var muscleGroup: String
    var muscleGroupID: Int
    var headType: String
    var headTypeID: Int
    var uniqueHead: String
    var uniqueHeadID: Int
    var chiralityFlag: String
    var modelReferenceName: String
}

class MuscleDataLoader {
    var muscles: [MuscleData] = []

    init() {
        loadMuscleData()
    }

    private func loadMuscleData() {
        guard let path = Bundle.main.path(forResource: "MuscleCoorelations", ofType: "csv") else {
            print("MuscleCoorelations.csv file not found")
            return
        }

        do {
            let csvData = try String(contentsOfFile: path, encoding: .utf8)
            let rows = csvData.components(separatedBy: "\n").dropFirst() // Skip header

            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 12 {  // Ensure there are enough columns
                    let muscle = MuscleData(
                        id: Int(columns[9].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                        muscleName: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                        muscleID: Int(columns[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                        muscleGroup: columns[4].trimmingCharacters(in: .whitespacesAndNewlines),
                        muscleGroupID: Int(columns[5].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                        headType: columns[6].trimmingCharacters(in: .whitespacesAndNewlines),
                        headTypeID: Int(columns[7].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                        uniqueHead: columns[8].trimmingCharacters(in: .whitespacesAndNewlines),
                        uniqueHeadID: Int(columns[9].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                        chiralityFlag: columns[10].trimmingCharacters(in: .whitespacesAndNewlines),
                        modelReferenceName: columns[11].trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    muscles.append(muscle)
                }
            }
        } catch {
            print("Error reading MuscleCoorelations.csv file: \(error.localizedDescription)")
        }
    }

    func findMuscleData(by nodeName: String) -> MuscleData? {
        return muscles.first { $0.modelReferenceName == nodeName }
    }
}
