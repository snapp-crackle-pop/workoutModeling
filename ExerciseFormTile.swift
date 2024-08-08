import SwiftUI
import CoreData

struct ExerciseFormTile: View {
    @Binding var selectedExercise: Exercise?
    var exercises: [Exercise]
    var onSelectExercise: (Exercise) -> Void
    var onSubmit: (ExerciseInstance) -> Void

    @Environment(\.managedObjectContext) private var viewContext

    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var duration: String = ""

    @FocusState private var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case reps, weight, duration
    }

    var body: some View {
        VStack(alignment: .leading) {
            //Text("Exercise Form")
                //.font(.headline)
                //.padding([.leading, .top])

            if let exercise = selectedExercise {
                VStack {
                    //Text("Selected Exercise: \(exercise.exerciseName)")
                        //.font(.headline)
                        //.padding()

                    if let formTypeID = Int(exercise.formTypeID.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        switch formTypeID {
                        case 1: // Reps
                            TextField("Reps", text: $reps)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .reps)
                                .submitLabel(.done)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)

                        case 2: // WeightReps
                            TextField("Weight", text: $weight)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .weight)
                                .submitLabel(.next)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)

                            TextField("Reps", text: $reps)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .reps)
                                .submitLabel(.done)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)

                        case 3: // Timed
                            TextField("Duration (seconds)", text: $duration)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .duration)
                                .submitLabel(.done)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)

                        default:
                            Text("Invalid form type")
                                .padding()
                        }
                    } else {
                        Text("Invalid form type ID")
                            .padding()
                    }

                    Button("Submit") {
                        saveExerciseInstance(
                            name: exercise.exerciseName,
                            date: Date(),
                            reps: Int(reps),
                            weight: Int(weight),
                            duration: Int(duration)
                        )
                        resetForm()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding([.leading, .trailing, .bottom])
                .background(Color.white.opacity(0.0))
                .cornerRadius(10)
                .frame(minHeight: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(exercises, id: \.exerciseID) { exercise in
                            Button(action: {
                                onSelectExercise(exercise)
                            }) {
                                ExerciseTile(exercise: exercise, backgroundColor: Color.gray)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.white.opacity(0.0))
        .cornerRadius(10)
        //.padding([.leading, .trailing])
    }

    private func saveExerciseInstance(name: String, date: Date, reps: Int?, weight: Int?, duration: Int?) {
        let newInstance = ExerciseInstance(context: viewContext)
        newInstance.exerciseName = name
        newInstance.inputDateTime = date
        newInstance.reps = Int32(reps ?? 0) // Convert Int to Int32
        newInstance.weight = Int32(weight ?? 0) // Convert Int to Int32
        newInstance.duration = Int32(duration ?? 0) // Convert Int to Int32

        do {
            try viewContext.save()
            print("Exercise instance saved successfully.")
        } catch {
            print("Failed to save exercise instance: \(error.localizedDescription)")
        }
    }

    private func resetForm() {
        reps = ""
        weight = ""
        duration = ""
    }

    private func hideKeyboard() {
        focusedField = nil
    }
}
