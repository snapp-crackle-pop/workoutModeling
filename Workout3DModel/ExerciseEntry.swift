import Foundation

struct ExerciseEntry: Identifiable {
    var id = UUID()
    var exerciseName: String
    var formType: String
    var weight: Int? // Optional, used only for Weight forms
    var reps: Int
}
