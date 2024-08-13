import SwiftUI
import CoreData

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ExerciseInstance.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ExerciseInstance.inputDateTime, ascending: true)]
    ) private var exerciseInstances: FetchedResults<ExerciseInstance>
    
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack {
            Text("Data Management")
                .font(.title)
                .padding()

            Spacer()

            Button(action: exportData) {
                Text("Export Data")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Button(action: {
                showingDeleteAlert = true
            }) {
                Text("Clear All Data")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Are you sure?"),
                    message: Text("This will delete all stored data."),
                    primaryButton: .destructive(Text("Delete All")) {
                        clearAllData()
                    },
                    secondaryButton: .cancel()
                )
            }

            Spacer()
        }
    }

    private func exportData() {
        let csvString = createCSV(from: exerciseInstances)

        let fileName = "ExerciseData.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            let av = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            if let topController = UIApplication.shared.windows.first?.rootViewController {
                topController.present(av, animated: true, completion: nil)
            }
        } catch {
            print("Failed to write CSV file: \(error.localizedDescription)")
        }
    }

    private func createCSV(from records: FetchedResults<ExerciseInstance>) -> String {
        var csvString = "ID,Exercise Name,Date,Reps,Weight,Duration\n"
        
        for record in records {
            let id = record.id?.uuidString ?? ""
            let name = record.exerciseName
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = dateFormatter.string(from: record.inputDateTime ?? Date())
            let reps = record.reps
            let weight = record.weight
            let duration = record.duration

            let row = "\(id),\(name),\(date),\(reps),\(weight),\(duration)\n"
            csvString += row
        }

        return csvString
    }

    private func clearAllData() {
        for record in exerciseInstances {
            viewContext.delete(record)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to clear data: \(error.localizedDescription)")
        }
    }
}
