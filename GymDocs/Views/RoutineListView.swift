import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    var session = ActiveRoutineSession.shared
    @State private var showAddAlert = false
    @State private var showLimitAlert = false
    @State private var newRoutineName = ""

    var body: some View {
        NavigationStack {
            List {
                if routines.isEmpty {
                    ContentUnavailableView(
                        String(localized: "routines.empty", defaultValue: "루틴이 없습니다"),
                        systemImage: "list.bullet.clipboard",
                        description: Text(String(localized: "routines.emptyDescription", defaultValue: "새로운 루틴을 추가해보세요."))
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(routines) { routine in
                        NavigationLink(destination: RoutineDetailView(routine: routine)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(routine.name)
                                        .font(.headline)
                                    Text(String(localized: "routines.exerciseCount", defaultValue: "\(routine.exercises.count)개 운동"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if session.isCurrentRoutine(routine.id) {
                                    Spacer()
                                    Label("진행 중", systemImage: "figure.run")
                                        .font(.caption2)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "FFD52E"))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.hapticPress)
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(routine)
                            } label: {
                                Label(String(localized: "common.delete", defaultValue: "삭제"), systemImage: "trash")
                            }
                        }
                    }
                    }
                }
            }
            .navigationTitle(String(localized: "routines.title", defaultValue: "내 루틴"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if routines.count >= 20 {
                            showLimitAlert = true
                        } else {
                            newRoutineName = ""
                            showAddAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert(String(localized: "routines.addTitle", defaultValue: "루틴 추가"), isPresented: $showAddAlert) {
                TextField(String(localized: "routines.namePlaceholder", defaultValue: "루틴 이름"), text: $newRoutineName)
                Button(String(localized: "common.cancel", defaultValue: "취소"), role: .cancel) { }
                Button(String(localized: "common.save", defaultValue: "저장")) {
                    let trimmed = newRoutineName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let routine = Routine(name: trimmed)
                        modelContext.insert(routine)
                    }
                }
            }
            .alert(String(localized: "routines.limitTitle", defaultValue: "루틴 개수 제한"), isPresented: $showLimitAlert) {
                Button(String(localized: "common.ok", defaultValue: "확인"), role: .cancel) { }
            } message: {
                Text(String(localized: "routines.limitMessage", defaultValue: "루틴은 최대 20개까지만 만들 수 있습니다."))
            }
        }
    }
}
