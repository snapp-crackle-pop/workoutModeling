import SwiftUI

struct SubmittedExercisesView: View {
    @ObservedObject var submissionData: SubmissionData

    var body: some View {
        List {
            ForEach(submissionData.entries) { entry in
                VStack(alignment: .leading) {
                    Text(entry.exerciseName)
                        .font(.headline)
                    if let weight = entry.weight {
                        Text("Weight: \(weight)")
                    }
                    Text("Reps: \(entry.reps)")
                }
            }
        }
        .navigationTitle("Submitted Exercises")
    }
}
