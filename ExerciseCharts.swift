import SwiftUI
import Charts

enum ChartViewMode: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    
    var id: String { self.rawValue }
}

struct ExerciseChartsTile: View {
    var exercise: Exercise
    @FetchRequest private var exerciseInstances: FetchedResults<ExerciseInstance>
    
    @State private var currentDate: Date = Date()
    @State private var viewMode: ChartViewMode = .week

    init(exercise: Exercise) {
        self.exercise = exercise
        _exerciseInstances = FetchRequest<ExerciseInstance>(
            sortDescriptors: [NSSortDescriptor(keyPath: \ExerciseInstance.inputDateTime, ascending: true)],
            predicate: NSPredicate(format: "exerciseName == %@", exercise.exerciseName)
        )
    }

    var body: some View {
        VStack {
            HStack {
                Text("\(titleForCurrentDate())'s Reps")
                    .font(.headline)
                    .padding()

                Spacer()

                Picker("", selection: $viewMode) {
                    ForEach(ChartViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.trailing)
            }

            if exerciseDataForChart.isEmpty {
                Text("No data available for this exercise.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart {
                    ForEach(exerciseDataForChart) { data in
                        ForEach(data.instances) { instance in
                            RectangleMark(
                                x: .value(viewMode == .day ? "Hour" : "Day", data.label),
                                yStart: .value("Reps Start", instance.repsStart),
                                yEnd: .value("Reps End", instance.repsEnd)
                            )
                            .foregroundStyle(colorForWeight(instance.weight))
                            .cornerRadius(5)
                        }
                    }
                }
                .frame(height: 200)
                .padding()
                .chartXAxis {
                    AxisMarks(values: xAxisValues()) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            logExerciseData()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation {
                            navigateDate(forward: true)
                        }
                    } else if value.translation.width > 50 {
                        withAnimation {
                            navigateDate(forward: false)
                        }
                    }
                }
        )
    }

    private func navigateDate(forward: Bool) {
        let calendar = Calendar.current
        if forward {
            let nextDate = calendar.date(byAdding: viewMode == .day ? .day : .weekOfYear, value: 1, to: currentDate) ?? Date()
            if nextDate <= Date() {
                currentDate = nextDate
            }
        } else {
            currentDate = calendar.date(byAdding: viewMode == .day ? .day : .weekOfYear, value: -1, to: currentDate) ?? Date()
        }
    }

    private var exerciseDataForChart: [ChartData] {
        let calendar = Calendar.current

        switch viewMode {
        case .day:
            return generateDayData(calendar: calendar)

        case .week:
            return generateWeekData(calendar: calendar)
        }
    }

    private func generateDayData(calendar: Calendar) -> [ChartData] {
        let startOfDay = calendar.startOfDay(for: currentDate)
        let hours = (0..<24).map { calendar.date(byAdding: .hour, value: $0, to: startOfDay)! }

        let groupedData = Dictionary(grouping: exerciseInstances.filter { instance in
            guard let date = instance.inputDateTime else { return false }
            return calendar.isDate(date, inSameDayAs: currentDate)
        }, by: { instance in
            calendar.component(.hour, from: instance.inputDateTime ?? Date())
        })

        return hours.map { hour in
            let hourInt = calendar.component(.hour, from: hour)
            let instancesForHour = groupedData[hourInt] ?? []
            var instances: [InstanceData] = []

            var cumulativeReps = 0
            for instance in instancesForHour {
                let start = cumulativeReps
                let end = start + Int(instance.reps)
                instances.append(InstanceData(repsStart: start, repsEnd: end, weight: Int(instance.weight)))
                cumulativeReps = end
            }

            if instances.isEmpty {
                instances.append(InstanceData(repsStart: 0, repsEnd: 0, weight: 0))
            }

            return ChartData(label: hourLabel(for: hourInt), instances: instances)
        }
    }

    private func generateWeekData(calendar: Calendar) -> [ChartData] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        let days = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }

        let groupedData = Dictionary(grouping: exerciseInstances.filter { instance in
            guard let date = instance.inputDateTime else { return false }
            return calendar.isDate(date, equalTo: currentDate, toGranularity: .weekOfYear)
        }, by: { instance in
            calendar.component(.weekday, from: instance.inputDateTime ?? Date())
        })

        return days.map { day in
            let dayInt = calendar.component(.weekday, from: day)
            let instancesForDay = groupedData[dayInt] ?? []
            var instances: [InstanceData] = []

            var cumulativeReps = 0
            for instance in instancesForDay {
                let start = cumulativeReps
                let end = start + Int(instance.reps)
                instances.append(InstanceData(repsStart: start, repsEnd: end, weight: Int(instance.weight)))
                cumulativeReps = end
            }

            if instances.isEmpty {
                instances.append(InstanceData(repsStart: 0, repsEnd: 0, weight: 0))
            }

            return ChartData(label: dayLabel(for: dayInt), instances: instances)
        }
    }

    private func xAxisValues() -> [String] {
        switch viewMode {
        case .day:
            return ["12AM", "6AM", "12PM", "6PM", "12AM"]
        case .week:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }

    private func titleForCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: currentDate))'s Reps"
    }

    private func hourLabel(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) else {
            return ""
        }
        return formatter.string(from: date)
    }

    private func dayLabel(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        guard let date = Calendar.current.date(bySetting: .weekday, value: weekday, of: Date()) else {
            return ""
        }
        return formatter.string(from: date)
    }

    private func colorForWeight(_ weight: Int) -> Color {
        let minWeight: Double = 0
        let maxWeight: Double = 100 // Adjust as needed
        let normalizedWeight = (Double(weight) - minWeight) / (maxWeight - minWeight)
        return Color(hue: (0.6 - 0.25 * normalizedWeight), saturation: 0.8, brightness: 0.8)
    }

    private func logExerciseData() {
        print("Logging data for exercise: \(exercise.exerciseName)")
        for instance in exerciseInstances {
            print("ID: \(instance.id?.uuidString ?? "Unknown ID"), Date: \(instance.inputDateTime ?? Date()), Reps: \(instance.reps), Weight: \(instance.weight)")
        }
    }

    struct ChartData: Identifiable {
        var id = UUID()
        var label: String
        var instances: [InstanceData]
    }

    struct InstanceData: Identifiable {
        var id = UUID()
        var repsStart: Int
        var repsEnd: Int
        var weight: Int
    }
}
