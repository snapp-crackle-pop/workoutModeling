import SwiftUI

struct ExerciseSelector: View {
    @Binding var selectedExercise: Exercise? // Binding for the selected exercise
    @Binding var showSelector: Bool
    var exercises: [Exercise]
    var onSelectExercise: (Exercise) -> Void
    var muscleDataLoader: MuscleDataLoader

    // Define muscle group colors
    private let muscleGroupColors: [String: Color] = [
        "Neck": .red,
        "Shoulders": .green,
        "Upper Arms": .blue,
        "Forearms": .orange,
        "Back": .purple,
        "Chest": .yellow,
        "Waist": .brown,
        "Hips": .pink,
        "Thighs": .indigo,
        "Calves": .cyan
    ]

    @State private var selectedGroup: String? = nil
    @State private var selectedExerciseID: String? = nil // Track selected exercise ID
    @State private var showItemNodes: Bool = false
    @State private var groupPositions: [String: CGPoint] = [:] // Store initial positions of group nodes

    private var muscleGroups: [String] {
        let groups = exercises.flatMap { exercise in
            extractMuscleGroups(from: exercise.targetMuscleIDs)
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
                                showSelector = false // Hide the selector when the background is tapped
                            }
                        }

                    ForEach(muscleGroups, id: \.self) { group in
                        let groupPosition = calculateGroupPosition(group: group, geometry: geometry)
                        let centerPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                        GroupNode(
                            group: group,
                            selectedGroup: $selectedGroup,
                            showItemNodes: $showItemNodes,
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
                        .opacity(selectedGroup == nil || selectedGroup == group ? 1 : 0)
                        .scaleEffect(selectedGroup == nil || selectedGroup == group ? 1 : 0.1)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: selectedGroup)

                        if selectedGroup == group {
                            ForEach(filteredExercises(for: group), id: \.exerciseID) { exercise in
                                let index = filteredExercises(for: group).firstIndex(of: exercise) ?? 0
                                let angle = Double(index) / Double(filteredExercises(for: group).count) * 2 * .pi
                                let radius: CGFloat = 100
                                let offsetX = showItemNodes ? radius * CGFloat(cos(angle)) : 0
                                let offsetY = showItemNodes ? radius * CGFloat(sin(angle)) : 0

                                ItemNode(color: muscleGroupColors[group] ?? .gray, isSelected: selectedExerciseID == exercise.exerciseID)
                                    .position(centerPosition)
                                    .offset(x: offsetX, y: offsetY)
                                    .scaleEffect(showItemNodes ? 1.0 : 0.1)
                                    .opacity(showItemNodes ? 1.0 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: showItemNodes)
                                    .onTapGesture {
                                        selectedExerciseID = exercise.exerciseID
                                        selectedExercise = exercise
                                        onSelectExercise(exercise)
                                        highlightMuscles(for: exercise)
                                    }
                            }
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
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

    private func filteredExercises(for group: String) -> [Exercise] {
        exercises.filter { exercise in
            let exerciseGroups = extractMuscleGroups(from: exercise.targetMuscleIDs)
            return exerciseGroups.contains(group)
        }
    }

    private func extractMuscleGroups(from muscleIDs: String) -> [String] {
        // Split the muscle IDs by commas, trim whitespaces, and remove any brackets
        let ids = muscleIDs
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Use compactMap to filter and transform the muscle IDs into muscle groups
        let groups: [String] = ids.compactMap { id -> String? in
            guard let intID = Int(id) else {
                return nil
            }
            return muscleDataLoader.muscles.first(where: { $0.muscleID == intID })?.muscleGroup
        }

        return groups
    }

    private func highlightMuscles(for exercise: Exercise) {
        // Implement muscle highlighting logic here
        let muscleIDs = extractMuscleIDs(from: exercise.targetMuscleIDs)
        activateMuscleColors(for: muscleIDs)
    }

    private func extractMuscleIDs(from muscleIDs: String) -> [Int] {
        // Convert muscle IDs from String to Int
        return muscleIDs
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    private func activateMuscleColors(for muscleIDs: [Int]) {
        // Logic to activate muscle colors based on the muscle IDs
        // This function will handle the UI changes for highlighting the muscles
    }
}

struct GroupNode: View {
    let group: String
    @Binding var selectedGroup: String?
    @Binding var showItemNodes: Bool
    let color: Color

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 5)
            .frame(width: 50, height: 50)
            .background(Circle().fill(.shadow(.inner(radius:5,x:2,y:2)))) //Color.white))
            //.shadow(color: .gray, radius: 5, x: 5, y: 5)
            //.shadow(color: .white, radius: 5, x: -5, y: -5)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                    if selectedGroup == group {
                        showItemNodes.toggle()
                        if !showItemNodes {
                            selectedGroup = nil
                        }
                    } else {
                        selectedGroup = group
                        showItemNodes = true
                    }
                }
            }
    }
}

struct ItemNode: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 5)
            .frame(width: 50, height: 50)
            .background(Circle().fill(isSelected ? color : Color.white )) // Change background color when selected
            //.shadow(color: .gray, radius: 5, x: 5, y: 5)
            //.shadow(color: .white, radius: 5, x: -5, y: -5)
    }
}
