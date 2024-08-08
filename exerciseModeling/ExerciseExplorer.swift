//
//  ExerciseExplorer.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/4/24.
//

import SwiftUI

struct ExerciseExplorer: View {
    @Binding var selectedMuscleName: String?
    @Binding var selectedExercise: Exercise?
    @ObservedObject var exerciseData: ExerciseData

    var body: some View {
        VStack(alignment: .leading) {
            Text("Exercise Explorer")
                .font(.headline)
                .padding(.bottom)

            // List exercises based on the selected muscle
            let filteredExercises = exerciseData.exercises.filter { exercise in
                selectedMuscleName == nil || exercise.targetMuscleIDs.contains(where: { $0 == selectedMuscleName })
            }
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(filteredExercises, id: \.exerciseID) { exercise in
                        ExerciseTile(exercise: exercise) {
                            selectedExercise = exercise
                            // Optionally trigger visualization here
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ExerciseTile: View {
    let exercise: Exercise
    var onTap: () -> Void
    
    var body: some View {
        VStack {
            Text(exercise.exerciseName)
                .font(.subheadline)
                .padding()
                .background(Color.blue.opacity(0.3))
                .cornerRadius(5)
        }
        .onTapGesture {
            onTap()
        }
    }
}
