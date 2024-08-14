import SwiftUI
import Charts

enum ChartViewMode: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"
    
    var id: String { self.rawValue }
}


struct ExerciseChartsTile: View {
    var exercise: Exercise
    @FetchRequest private var exerciseInstances: FetchedResults<ExerciseInstance>
    
    @State private var currentDate: Date = Date()
    @State private var viewMode: ChartViewMode = .month

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
                Text("\(titleForCurrentDate())")
                    .font(.headline)
                    //.background(Color(.white.opacity(0.3)))
                    .foregroundColor(.modelGray)
                    .padding()

                Spacer()

                Picker("", selection: $viewMode) {
                    ForEach(ChartViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                            .background(Color(.modelGray.opacity(0.1)))
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
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3) // Adding shadow
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
        //.background(Color.white.opacity(0.1))
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
        let unit: Calendar.Component

        switch viewMode {
        case .day:
            unit = .day
        case .week:
            unit = .weekOfYear
        case .month:
            unit = .month
        case .year:
            unit = .year
        }

        let nextDate = calendar.date(byAdding: unit, value: forward ? 1 : -1, to: currentDate) ?? Date()
        if nextDate <= Date() {
            currentDate = nextDate
        }
    }


    private var exerciseDataForChart: [ChartData] {
        let calendar = Calendar.current

        switch viewMode {
        case .day:
            return generateDayData(calendar: calendar)
        case .week:
            return generateWeekData(calendar: calendar)
        case .month:
            return generateMonthData(calendar: calendar)
        case .year:
            return generateYearData(calendar: calendar)
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
    
    private func generateMonthData(calendar: Calendar) -> [ChartData] {
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        let days = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: calendar.startOfMonth(for: currentDate)) }

        let groupedData = Dictionary(grouping: exerciseInstances.filter { instance in
            guard let date = instance.inputDateTime else { return false }
            return calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
        }, by: { instance in
            calendar.component(.day, from: instance.inputDateTime ?? Date())
        })

        return days.map { day in
            let dayInt = calendar.component(.day, from: day)
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

            return ChartData(label: "\(dayInt)", instances: instances)
        }
    }

    private func generateYearData(calendar: Calendar) -> [ChartData] {
        let months = (1...12).compactMap { calendar.date(byAdding: .month, value: $0 - 1, to: calendar.startOfYear(for: currentDate)) }

        let groupedData = Dictionary(grouping: exerciseInstances.filter { instance in
            guard let date = instance.inputDateTime else { return false }
            return calendar.isDate(date, equalTo: currentDate, toGranularity: .year)
        }, by: { instance in
            calendar.component(.month, from: instance.inputDateTime ?? Date())
        })

        return months.map { month in
            let monthInt = calendar.component(.month, from: month)
            let instancesForMonth = groupedData[monthInt] ?? []
            var instances: [InstanceData] = []

            var cumulativeReps = 0
            for instance in instancesForMonth {
                let start = cumulativeReps
                let end = start + Int(instance.reps)
                instances.append(InstanceData(repsStart: start, repsEnd: end, weight: Int(instance.weight)))
                cumulativeReps = end
            }

            if instances.isEmpty {
                instances.append(InstanceData(repsStart: 0, repsEnd: 0, weight: 0))
            }

            return ChartData(label: monthLabel(for: monthInt), instances: instances)
        }
    }


    private func xAxisValues() -> [String] {
        switch viewMode {
        case .day:
            return ["12AM", "6AM", "12PM", "6PM", "12AM"]
        case .week:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .month:
            return ["1", "7", "14", "21", "28"]
        case .year:
            return ["Jan", "Mar", "May", "Jul", "Sep", "Nov"]
        }
    }

    private func titleForCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: currentDate))"
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
    
    private func monthLabel(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        guard let date = Calendar.current.date(bySetting: .month, value: month, of: Date()) else {
            return ""
        }
        return formatter.string(from: date)
    }


    private func colorForWeight(_ weight: Int) -> Color {
        let minWeight: Double = 0
        let maxWeight: Double = 100 // Adjust as needed
        let normalizedWeight = (Double(weight) - minWeight) / (maxWeight - minWeight)

        let startColor = UIColor(.chartsHighValue)
        let endColor = UIColor(.chartsLowValue)

        // Interpolate between startColor and endColor based on normalizedWeight
        let blendedColor = blendColors(startColor: startColor, endColor: endColor, ratio: normalizedWeight)

        return Color(blendedColor)
    }

    private func blendColors(startColor: UIColor, endColor: UIColor, ratio: Double) -> UIColor {
        let ratio = CGFloat(max(0, min(1, ratio))) // Ensure the ratio is between 0 and 1
        
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        
        startColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * ratio
        let g = g1 + (g2 - g1) * ratio
        let b = b1 + (b2 - b1) * ratio
        let a = a1 + (a2 - a1) * ratio
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
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

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }

    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components)!
    }
}
