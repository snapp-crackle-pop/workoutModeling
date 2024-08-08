//
//  DynamicDashboard.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/4/24.
//

struct DynamicDashboard: View {
    @Binding var isVisible: Bool
    @Binding var muscleName: String?
    @Binding var selectedExercise: Exercise?
    @ObservedObject var exerciseData: ExerciseData
    
    @State private var showingExerciseForm = false

    var body: some View {
        VStack {
            HStack {
                Text(muscleName ?? "No Muscle Selected")
                    .font(.headline)
                    .padding()
                
                Spacer()
            }
            .background(Color.gray.opacity(0.8))
            .cornerRadius(10)
            .padding([.leading, .trailing, .top])
            
            // Exercise Explorer
            ExerciseExplorer(selectedMuscleName: $muscleName, selectedExercise: $selectedExercise, exerciseData: exerciseData)
            
            // Button to open the Exercise Form
            if let exercise = selectedExercise {
                Button(action: {
                    showingExerciseForm.toggle()
                }) {
                    Text("Open Exercise Form")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .sheet(isPresented: $showingExerciseForm) {
                    ExerciseForm(exercise: exercise)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: isVisible ? UIScreen.main.bounds.height * 0.3 : 50) // Adjustable height
        .background(Color.gray.opacity(0.9))
        .cornerRadius(15)
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < 0 { // Swipe up to expand
                        withAnimation {
                            isVisible = true
                        }
                    } else if value.translation.height > 0 { // Swipe down to collapse
                        withAnimation {
                            isVisible = false
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation {
                isVisible.toggle()
            }
        }
    }
}
