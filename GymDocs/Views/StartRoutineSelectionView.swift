import SwiftUI
import SwiftData

struct StartRoutineSelectionView: View {
    let routines: [Routine]
    @Binding var isPresented: Bool
    var onStart: (Routine) -> Void
    
    @State private var selectedRoutineID: UUID?
    
    var body: some View {
        NavigationStack {
            List(routines) { routine in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name).font(.headline)
                        Text("\(routine.exercises.count)개 운동")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedRoutineID == routine.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedRoutineID = routine.id
                }
            }
            .navigationTitle("루틴 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { isPresented = false }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if let id = selectedRoutineID, let routine = routines.first(where: { $0.id == id }) {
                        onStart(routine)
                    }
                } label: {
                    Text("시작")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.hapticPress)
                .background(selectedRoutineID == nil ? Color.gray : Color.blue)
                .clipShape(Capsule())
                .padding()
                .disabled(selectedRoutineID == nil)
            }
        }
        .presentationDetents([.fraction(0.66)])
    }
}
