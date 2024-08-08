//
//  functions.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/4/24.
//

import Foundation

func loadMuscleToModelMapping() -> [String: String] {
    guard let path = Bundle.main.path(forResource: "MuscleCoorelations", ofType: "csv") else {
        print("MuscleCoorelations.csv file not found")
        return [:]
    }

    var mapping: [String: String] = [:]

    do {
        let csvData = try String(contentsOfFile: path, encoding: .utf8)
        let rows = csvData.components(separatedBy: "\n").dropFirst() // Skip header

        for row in rows {
            let columns = row.components(separatedBy: ",")
            if columns.count > 12 {
                let uniqueHeadID = columns[10].trimmingCharacters(in: .whitespacesAndNewlines)
                let modelReferenceName = columns[12].trimmingCharacters(in: .whitespacesAndNewlines)

                if !uniqueHeadID.isEmpty && !modelReferenceName.isEmpty {
                    mapping[uniqueHeadID] = modelReferenceName
                }
            }
        }
    } catch {
        print("Error reading MuscleCoorelations.csv file: \(error.localizedDescription)")
    }

    return mapping
}
