import SwiftUI
import CoreData

enum ExerciseSelectorState {
    case inactive
    case group
    case item
    case selected
    case formInput
}

struct ExerciseSelector: View {
    @Binding var selectedExercise: Exercise? // Binding for the selected exercise
    @Binding var showSelector: Bool
    @Binding var activeMuscleGroups: [String] // Binding for active muscle groups

    var exercises: [Exercise]
    var onSelectExercise: (Exercise) -> Void
    var muscleDataLoader: MuscleDataLoader

    // Muscle group colors
    private let muscleGroupColors: [String: Color] = [
        "Neck": Color("NeckColor") ?? .red,
        "Shoulders": Color("ShouldersColor") ?? .green,
        "Upper Arms": Color("UpperArmsColor") ?? .blue,
        "Forearms": Color("ForearmsColor") ?? .orange,
        "Back": Color("BackColor") ?? .purple,
        "Chest": Color("ChestColor") ?? .yellow,
        "Waist": Color("WaistColor") ?? .brown,
        "Hips": Color("HipsColor") ?? .pink,
        "Thighs": Color("ThighsColor") ?? .indigo,
        "Calves": Color("CalvesColor") ?? .cyan
    ]

    @State private var selectedGroup: String? = nil
    @State private var selectedExerciseID: String? = nil // Track selected exercise ID
    @State private var showItemNodes: Bool = false
    @State private var groupPositions: [String: CGPoint] = [:] // Store initial positions of group nodes
    @State private var selectorState: ExerciseSelectorState = .inactive
    @State private var lastActiveState: ExerciseSelectorState = .group

    @State private var previousDragPosition: CGFloat = 0 // Track the previous drag position
    @State private var accumulatedDrag: CGFloat = 0 // Accumulate the drag distance for smoother adjustments
    
    @Environment(\.managedObjectContext) private var viewContext // Core Data context

    // Form state variables
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var duration: String = ""
    @FocusState private var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case reps, weight, duration
    }

    private var muscleGroups: [String] {
        let groups = exercises.flatMap { exercise in
            extractMuscleGroups(from: exercise)
        }
        return Array(Set(groups)).sorted() // Unique and sorted list of muscle groups
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showSelector {
                    Color.clear // Use a clear background to detect taps only
                        .contentShape(Rectangle()) // Define the tappable area as a rectangle
                        .onTapGesture {
                            withAnimation {
                                showSelector = false
                                lastActiveState = selectorState
                                selectorState = .inactive // Set state to inactive
                                updateActiveMuscleGroups()
                                print("ExerciseSelectorState: \(selectorState)")
                            }
                        }
                        .onAppear {
                            if selectorState == .inactive {
                                selectorState = lastActiveState
                                updateActiveMuscleGroups()
                                print("ExerciseSelectorState: \(selectorState)")
                            }
                        }

                    ForEach(muscleGroups, id: \.self) { group in
                        let groupPosition = calculateGroupPosition(group: group, geometry: geometry)
                        let centerPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                        GroupNode(
                            group: group,
                            selectedGroup: $selectedGroup,
                            showItemNodes: $showItemNodes,
                            selectorState: $selectorState,
                            activeMuscleGroups: $activeMuscleGroups,
                            color: muscleGroupColors[group] ?? .gray
                        )
                        .position(selectedGroup == group ? centerPosition : groupPositions[group] ?? groupPosition)
                        .scaleEffect(selectedGroup == group ? 0.8 : 1.0) // Shrink to 80% when selected
                        .zIndex(selectedGroup == group ? 1 : 0) // Ensure the selected group node is always in front
                        .onAppear {
                            if groupPositions[group] == nil {
                                groupPositions[group] = groupPosition
                            }
                        }
                        .opacity(selectorState == .formInput ? 0 : (selectedGroup == nil || selectedGroup == group ? 1 : 0))
                        .scaleEffect(selectorState == .formInput ? 0.1 : (selectedGroup == nil || selectedGroup == group ? 1 : 0.1))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: selectorState)

                        if selectedGroup == group {
                            ForEach(filteredExercises(for: group), id: \.exerciseID) { exercise in
                                let index = filteredExercises(for: group).firstIndex(of: exercise) ?? 0
                                let angle = Double(index) / Double(filteredExercises(for: group).count) * 2 * .pi
                                let radius: CGFloat = 100
                                let offsetX = showItemNodes ? radius * CGFloat(cos(angle)) : 0
                                let offsetY = showItemNodes ? radius * CGFloat(sin(angle)) : 0

                                ItemNode(
                                    color: muscleGroupColors[group] ?? .gray,
                                    isSelected: selectedExerciseID == exercise.exerciseID,
                                    exerciseName: exercise.exerciseName // Pass the exercise name here
                                )
                                .position(centerPosition)
                                .offset(x: offsetX, y: offsetY)
                                .scaleEffect(selectorState == .formInput ? 0.1 : (showItemNodes ? 1.0 : 0.1))
                                .opacity(selectorState == .formInput ? 0 : (showItemNodes ? 1.0 : 0))
                                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: selectorState)
                                .onTapGesture(count: 2) { // Double tap to enter form input state
                                    selectedExerciseID = exercise.exerciseID
                                    selectedExercise = exercise
                                    loadLastExerciseValues(for: exercise)
                                    withAnimation {
                                        selectorState = .formInput
                                    }
                                    print("ExerciseSelectorState: \(selectorState)")
                                }
                                .onTapGesture {
                                    selectedExerciseID = exercise.exerciseID
                                    selectedExercise = exercise
                                    onSelectExercise(exercise)
                                    selectorState = .selected
                                    updateActiveMuscleGroups()
                                    print("ExerciseSelectorState: \(selectorState)")
                                }

                            }
                            .onAppear {
                                if showItemNodes && selectorState == .group {
                                    selectorState = .item
                                    updateActiveMuscleGroups()
                                    print("ExerciseSelectorState: \(selectorState)")
                                }
                            }
                        }
                    }
                }

                if selectorState == .formInput, let selectedExercise = selectedExercise {
                    formInputView(for: selectedExercise)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                print("ExerciseSelectorState: \(selectorState)")
            }
        }
    }

    private func calculateGroupPosition(group: String, geometry: GeometryProxy) -> CGPoint {
        // Arrange groups in a circular layout
        let index = muscleGroups.firstIndex(of: group) ?? 0
        let angle = Double(index) / Double(muscleGroups.count) * 2 * .pi
        let radius: CGFloat = 150
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2

        let positionX = centerX + radius * CGFloat(cos(angle))
        let positionY = centerY + radius * CGFloat(sin(angle))

        return CGPoint(x: positionX, y: positionY)
    }

    private func extractMuscleGroups(from exercise: Exercise) -> [String] {
        func muscleGroups(from muscleIDString: String) -> [String] {
            return muscleIDString
                .components(separatedBy: "] [") // Split by the closing and opening bracket
                .map { $0.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "") }
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .compactMap { muscleID in
                    muscleDataLoader.muscles.first(where: { $0.muscleID == muscleID })?.muscleGroup
                }
        }

        let targetGroups = muscleGroups(from: exercise.targetMuscleIDs)

        if !targetGroups.isEmpty {
            print("\(exercise.exerciseName) found target muscle groups: \(targetGroups)")
            return targetGroups
        } else {
            print("\(exercise.exerciseName) found with no target muscles")

            let synergistGroups = muscleGroups(from: exercise.synergistMuscleIDs)
            if !synergistGroups.isEmpty {
                print("\(exercise.exerciseName) synergist muscles include \(exercise.synergistMuscleIDs)")
                print("\(exercise.exerciseName) group should be set to \(synergistGroups)")
                return synergistGroups
            } else {
                print("\(exercise.exerciseName) found with no synergist muscles")

                let stabilizerGroups = muscleGroups(from: exercise.stabilizerMuscleIDs)
                if !stabilizerGroups.isEmpty {
                    print("\(exercise.exerciseName) stabilizer muscles include \(exercise.stabilizerMuscleIDs)")
                    print("\(exercise.exerciseName) group should be set to \(stabilizerGroups)")
                    return stabilizerGroups
                } else {
                    print("\(exercise.exerciseName) found with no stabilizer muscles")
                    return []
                }
            }
        }
    }

    private func filteredExercises(for group: String) -> [Exercise] {
        let filtered = exercises.filter { exercise in
            let exerciseGroups = extractMuscleGroups(from: exercise)
            let containsGroup = exerciseGroups.contains(group)
            print("Checking \(exercise.exerciseName) in group \(group): \(containsGroup)")
            return containsGroup
        }
        print("Filtered exercises for group \(group): \(filtered.map { $0.exerciseName })")
        return filtered
    }



    //private func muscleGroups(from muscleIDs: [Int]) -> [String] {
    //    return muscleIDs.compactMap { id in
    //        muscleDataLoader.muscles.first(where: { $0.muscleID == id })?.muscleGroup
    //    }
    //}



    private func extractMuscleIDs(from muscleIDsString: String) -> [Int] {
        return muscleIDsString
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }


    private func updateActiveMuscleGroups() {
        switch selectorState {
        case .group:
            activeMuscleGroups = muscleGroups
        case .item:
            if let selectedGroup = selectedGroup {
                activeMuscleGroups = [selectedGroup]
            }
        case .selected, .inactive, .formInput:
            activeMuscleGroups = []
        }
        print("Active Muscle Groups: \(activeMuscleGroups)")
    }

    private func loadLastExerciseValues(for exercise: Exercise) {
        let fetchRequest: NSFetchRequest<ExerciseInstance> = ExerciseInstance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "exerciseName == %@", exercise.exerciseName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "inputDateTime", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let lastInstance = try viewContext.fetch(fetchRequest).first
            reps = lastInstance != nil ? String(lastInstance!.reps) : ""
            weight = lastInstance != nil ? String(lastInstance!.weight) : ""
            duration = lastInstance != nil ? String(lastInstance!.duration) : ""
        } catch {
            print("Failed to fetch last exercise instance: \(error.localizedDescription)")
        }
    }

    private func saveExerciseInstance() {
        guard let selectedExercise = selectedExercise else { return }

        let newInstance = ExerciseInstance(context: viewContext)
        newInstance.id = UUID()
        newInstance.exerciseName = selectedExercise.exerciseName
        newInstance.inputDateTime = Date()
        newInstance.reps = Int32(reps) ?? 0
        newInstance.weight = Int32(weight) ?? 0
        newInstance.duration = Int32(duration) ?? 0

        do {
            try viewContext.save()
            print("Exercise instance saved successfully.")
            resetForm()
            withAnimation {
                selectorState = .selected
            }
        } catch {
            print("Failed to save exercise instance: \(error.localizedDescription)")
        }
    }

    private func resetForm() {
        reps = ""
        weight = ""
        duration = ""
    }

    private func CircularTextField(placeholder: String, text: Binding<String>, color: Color, unit: String) -> some View {
        GeometryReader { geometry in
            let intervalHeight = geometry.size.height / 10

            Circle()
                .stroke(Color("MenuGrayColor"), lineWidth: 10)
                .frame(width: 150, height: 150)
                .scaleEffect(selectorState == .item ? 0 : 1) // Shrink before disappearing
                .overlay(
                    VStack {
                        TextField(placeholder, text: text)
                            .font(.largeTitle)
                            .foregroundColor(Color.black)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.clear)
                            .gesture(DragGesture()
                                .onChanged { value in
                                    let dragDifference = value.translation.height - previousDragPosition
                                    accumulatedDrag += dragDifference
                                    let adjustment = Int(accumulatedDrag / intervalHeight) * 5

                                    if adjustment != 0 {
                                        if let currentValue = Int(text.wrappedValue) {
                                            let newValue = max(currentValue - adjustment, 0)
                                            text.wrappedValue = "\(newValue)"
                                        }
                                        accumulatedDrag = 0
                                    }
                                    previousDragPosition = value.translation.height
                                }
                                .onEnded { _ in
                                    previousDragPosition = 0
                                    accumulatedDrag = 0
                                }
                            )
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
                .background(Circle().fill(.clear.shadow(.inner(color: .white, radius: 5, x: -5, y: -5))))
                .background(Circle().fill(Color("MenuGrayColor").shadow(.inner(radius: 6, x: 6, y: 6))))
        }
        .frame(width: 150, height: 150)
    }

    private func formInputView(for exercise: Exercise) -> some View {
        VStack(spacing: 40) {
            Spacer()

            if let formTypeID = Int(exercise.formTypeID.trimmingCharacters(in: .whitespacesAndNewlines)) {
                switch formTypeID {
                case 1: // Reps
                    CircularTextField(placeholder: "Reps", text: $reps, color: .gray, unit: "reps")
                        .padding(.bottom, 20)

                case 2: // Weight and Reps
                    CircularTextField(placeholder: "Weight", text: $weight, color: .gray, unit: "pounds")
                        .padding(.bottom, 20)
                    CircularTextField(placeholder: "Reps", text: $reps, color: .gray, unit: "reps")

                case 3: // Time
                    CircularTextField(placeholder: "Duration (sec)", text: $duration, color: .gray, unit: "seconds")
                        .padding(.bottom, 20)

                default:
                    Text("Invalid form type")
                        .padding()
                }
            } else {
                Text("Invalid form type ID")
                    .padding()
            }

            HStack(spacing: 40) { // Adjust spacing between buttons
                CircularButton(title: "Back", action: handleBackButton, color: .backButton)
                CircularButton(title: "Submit", action: handleSubmitButton, color: .submitButton)
            }
            .padding(.bottom, 30)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(20)
        .padding()
    }

    private func handleBackButton() {
        withAnimation {
            selectorState = .item // Return to item selection state
        }
    }

    private func handleSubmitButton() {
        saveExerciseInstance()

        withAnimation(.easeInOut(duration: 0.3)) {
            reps = ""
            weight = ""
            duration = ""
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring()) {
                selectorState = .item
            }
        }
    }
}


struct GroupNode: View {
    let group: String
    @Binding var selectedGroup: String?
    @Binding var showItemNodes: Bool
    @Binding var selectorState: ExerciseSelectorState
    @Binding var activeMuscleGroups: [String]
    let color: Color

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 5)
            .frame(width: 50, height: 50)
            .background(Circle().fill(.menuGray.shadow(.inner(radius: 5, x: 3, y: 3))))
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                    if selectedGroup == group {
                        // Toggle item nodes
                        showItemNodes.toggle()
                        if !showItemNodes {
                            selectedGroup = nil
                            selectorState = .group
                            activateAllMuscleGroups()
                        }
                    } else {
                        selectedGroup = group
                        showItemNodes = true
                        selectorState = .item
                        activateGroupMuscle()
                    }
                    print("ExerciseSelectorState: \(selectorState)")
                }
            }
    }

    private func activateAllMuscleGroups() {
        activeMuscleGroups = MuscleDataLoader().muscles.map { $0.muscleGroup }.removingDuplicates()
        print("Activated Muscle Groups: \(activeMuscleGroups)")
    }

    private func activateGroupMuscle() {
        activeMuscleGroups = [group]
        print("Activated Muscle Group: \(activeMuscleGroups)")
    }
}

struct CircularButton: View {
    let title: String
    let action: () -> Void
    let color: Color

    var body: some View {
        Button(action: action) {
            Circle()
                .stroke(Color(color), lineWidth: 8)
                .frame(width: 90, height: 90) // Slightly smaller size
                .overlay(
                    VStack {
                        Text(title)
                            .font(.body)
                            .foregroundColor(.alternateBackround) // Text color
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                )
                .background(Circle().fill(.clear.shadow(.inner(color: .white, radius: 5, x: -5, y: -5))))
                .background(Circle().fill(Color(color).shadow(.inner(radius: 6, x: 6, y: 6))))
        }
        .frame(width: 90, height: 90) // Ensure the button size matches the frame
    }
}

struct ItemNode: View {
    let color: Color
    let isSelected: Bool
    let exerciseName: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 5)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? color.shadow(.inner(radius: 5, x: 3, y: 3)) : Color("MenuGrayColor").shadow(.inner(radius: 5, x: 3, y: 3)))
                )

            Text(cleanExerciseName(exerciseName))
                .font(.caption2)
                .foregroundColor(isSelected ? textColor(for: color) : darkerColor(color)) // Adjust text color based on selection
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 50)
                .padding(2)
        }
    }

    // Helper function to clean the exercise name
    private func cleanExerciseName(_ name: String) -> String {
        let wordsToRemove = ["Dumbbell", "Barbell"]
        var cleanedName = name
        for word in wordsToRemove {
            cleanedName = cleanedName.replacingOccurrences(of: word, with: "")
        }
        return cleanedName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Helper function to darken the color if above threshold
    private func darkerColor(_ color: Color) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Define a brightness threshold
        let brightnessThreshold: CGFloat = 0.5

        // If the brightness is above the threshold, lower it to the threshold
        if brightness > brightnessThreshold {
            brightness = brightnessThreshold
        }

        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }

    // Helper function to determine text color based on brightness
    private func textColor(for color: Color) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Define a brightness threshold
        let brightnessThreshold: CGFloat = 0.5

        // Return black if brightness is above threshold, otherwise return white
        return brightness > brightnessThreshold ? .black : .white
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
