import SwiftUI
import CoreData

struct HistoryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExerciseInstance.inputDateTime, ascending: false)],
        animation: .default)
    private var exerciseInstances: FetchedResults<ExerciseInstance>

    @State private var selectedExerciseName: String?

    var body: some View {
        VStack(alignment: .leading) {

            if exerciseInstances.isEmpty {
                Text("No exercise entries found.")
                    .font(.headline)
                    .padding()
            } else {
                VStack(alignment: .leading) {
                    // Dropdown to select exercise type
                    Picker("Filter by Exercise", selection: $selectedExerciseName) {
                        Text("All").tag(String?.none)
                        ForEach(exerciseInstances.map { $0.exerciseName ?? "Unknown" }.unique, id: \.self) { name in
                            Text(name).tag(name as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    //.padding()

                    ScrollView {
                        VStack(spacing: 10) {
                            // Header row
                            HStack {
                                Text("Exercise").bold().frame(maxWidth: .infinity, alignment: .center)
                                Text("Date").bold().frame(width: 70, alignment: .center)
                                Text("Reps").bold().frame(width: 30, alignment: .center)
                                Text("Weight").bold().frame(width: 40, alignment: .center)
                                Text("Dur.").bold().frame(width: 50, alignment: .center)
                            }
                            //.padding(.horizontal)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(5)
                            .font(.caption2)

                            // Data rows
                            ForEach(filteredExerciseInputs, id: \.self) { instance in
                                HStack {
                                    Text(instance.exerciseName ?? "Unknown")
                                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .center)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                    Text(formattedDate(instance.inputDateTime))
                                        .frame(width: 70, alignment: .center)
                                    Text("\(instance.reps)").frame(width: 30, alignment: .center)
                                    Text("\(instance.weight) lbs").frame(width: 40, alignment: .center)
                                    Text("\(instance.duration) sec").frame(width: 50, alignment: .center)
                                }
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.6))
                                .cornerRadius(5)
                                .shadow(radius: 1)
                                .foregroundColor(.black) // Set text color to black
                                .font(.caption2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                //.padding(.horizontal)
            }
        }
        .onAppear {
            logLatestEntries()
        }
    }

    private var filteredExerciseInputs: [ExerciseInstance] {
        if let selectedName = selectedExerciseName {
            return exerciseInstances.filter { $0.exerciseName == selectedName }
        } else {
            return Array(exerciseInstances)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy" // Use MM/dd/yyyy format
        return formatter.string(from: date)
    }

    private func logLatestEntries() {
        let latestEntries = exerciseInstances.prefix(5)
        print("Latest 5 Entries:")
        for entry in latestEntries {
            print("Exercise: \(entry.exerciseName ?? "Unknown"), Date: \(formattedDate(entry.inputDateTime)), Reps: \(entry.reps), Weight: \(entry.weight), Duration: \(entry.duration)")
        }
    }
}

extension Sequence where Element: Hashable {
    var unique: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
