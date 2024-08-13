import SwiftUI
import CoreData

struct DynamicDashboard: View {
    @Binding var isVisible: Bool
    @Binding var muscleNames: [String]
    @ObservedObject var exerciseData: ExerciseData
    @Binding var selectedExercise: Exercise?
    @Binding var selectedExerciseForForm: Exercise?
    @Binding var exerciseInputs: [ExerciseInstance]
    var onSelectExercise: (Exercise) -> Void
    var muscleDataLoader: MuscleDataLoader

    @State private var activeSection: ActiveSection = .main

    enum ActiveSection {
        case main, exerciseExplorer, exerciseForm, history, data
    }

    var body: some View {
        VStack {
            HStack {
                Text(headerTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .background(Color(UIColor(named: "ModelBackgroundColor") ?? .black))
            .cornerRadius(25)
            .padding([.leading, .trailing, .top], 5)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.clear)
                    .shadow(color: .black.opacity(0.5), radius: -4, x: 2, y: 2)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .white.opacity(0.5), radius: -4, x: -2, y: -2)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            )
            .onTapGesture {
                withAnimation {
                    isVisible.toggle()
                }
            }

            if isVisible {
                ScrollView {
                    VStack(spacing: 20) {
                        switch activeSection {
                        case .main:
                            menuTiles
                        case .exerciseExplorer:
                            VStack {
                                // Display chart as a separate tile
                                if let selectedExercise = selectedExercise {
                                    ExerciseChartsTile(exercise: selectedExercise)
                                        .frame(height: 350)
                                        .padding(.horizontal)
                                        .background(Color.black.opacity(0.0))
                                        .cornerRadius(10)
                                        .padding(.top, 10)
                                }
                            }
                        case .exerciseForm:
                            ExerciseFormTile(
                                selectedExercise: $selectedExerciseForForm,
                                exercises: exerciseData.exercises,
                                onSelectExercise: onSelectExercise,
                                onSubmit: { exerciseInstance in
                                    exerciseInputs.append(exerciseInstance)
                                }
                            )
                        case .history:
                            HistoryView()
                        case .data:
                            DataView() // Navigate to DataView
                        }
                    }
                    .padding(.top, 10)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: isVisible ? UIScreen.main.bounds.height * 0.5 : 65)
        .background(Color.modelBackground.opacity(0.9))
        .cornerRadius(30)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        withAnimation {
                            isVisible = true
                        }
                    } else if value.translation.height > 50 {
                        withAnimation {
                            isVisible = false
                        }
                    } else if value.translation.width > 100 {
                        withAnimation {
                            if activeSection != .main {
                                activeSection = .main
                            }
                        }
                    }
                }
        )
    }

    private var menuTiles: some View {
        VStack(spacing: 20) {
            MenuTile(title: "Exercise Explorer", action: { activeSection = .exerciseExplorer })
            MenuTile(title: "Exercise Form", action: { activeSection = .exerciseForm })
            MenuTile(title: "History", action: { activeSection = .history })
            MenuTile(title: "Data", action: { activeSection = .data }) // Data section added
        }
    }

    private var headerTitle: String {
        var components: [String] = []
        if let exercise = selectedExercise {
            components.append(exercise.exerciseName)
        }
        if !muscleNames.isEmpty {
            components.append(muscleNames.joined(separator: ", "))
        }
        return components.joined(separator: ": ")
    }
}



struct MenuTile: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.menuGray.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}
