import Foundation

struct Exercise: Identifiable {
    var id: String  // Unique identifier from the CSV
    var exerciseName: String
    var formTypeName: String
}

struct ExerciseEntry: Identifiable {
    var id = UUID()
    var exerciseName: String
    var formType: String
    var weight: Int? // Optional, used only for Weight forms
    var reps: Int
}
