import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [WorkoutRecord]
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @State private var showAddRoutineAlert = false
    @State private var showRoutineLimitAlert = false
    @State private var newRoutineName = ""
    @Query private var dailySummaries: [DailySummary]
    @State private var selectedDate: Date = Date()
    @State private var recordToNavigate: WorkoutRecord?
    @State private var showAddSheet = false
    @State private var weekOffset: Int = 0
    @State private var showUpdateRoutineAlert = false
    @State private var routinesToUpdate: [Routine] = []
    
    @State private var routineToNavigate: Routine?

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToMonday = currentWeekday == 1 ? -6 : -(currentWeekday - 2)
        
        guard let startOfCurrentWeek = calendar.date(byAdding: .day, value: daysToMonday, to: today),
              let startOfTargetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfCurrentWeek) else {
            return []
        }
        
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfTargetWeek) }
    }

    private var recordsForSelectedDate: [WorkoutRecord] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: selectedDate)
        return allRecords.filter { cal.startOfDay(for: $0.date) == startOfDay }
    }

    private var currentSummary: DailySummary? {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        return dailySummaries.first(where: { $0.date == startOfDay })
    }

    private var isFinished: Bool {
        currentSummary?.isFinished == true
    }

    private var hasAtLeastOneCompletedSet: Bool {
        recordsForSelectedDate.contains(where: { record in
            record.sets.contains(where: { $0.isCompleted })
        })
    }

    private var monthLabel: String {
        guard let firstDay = weekDays.first, let lastDay = weekDays.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let firstMonth = formatter.string(from: firstDay)
        let lastMonth = formatter.string(from: lastDay)
        if firstMonth == lastMonth {
            return "\(firstMonth) \(Calendar.current.component(.year, from: firstDay))"
        } else {
            return "\(firstMonth) - \(lastMonth)"
        }
    }

    private var weekDaysView: some View {
        VStack(spacing: 12) {
            HStack {
                Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left").padding(.horizontal, 8) }
                Spacer()
                if !monthLabel.isEmpty { Text(monthLabel).font(.subheadline).bold() }
                Spacer()
                Button { weekOffset += 1 } label: { Image(systemName: "chevron.right").padding(.horizontal, 8) }
                .disabled(weekOffset >= 0)
            }
            .buttonStyle(.plain)
            
            HStack {
                let cal = Calendar.current
                ForEach(weekDays, id: \.self) { day in
                    let isSelected = cal.isDate(day, inSameDayAs: selectedDate)
                    let hasRecords = allRecords.contains { cal.isDate($0.date, inSameDayAs: day) }
                    
                    Button { selectedDate = day } label: {
                        VStack(spacing: 8) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(isSelected ? .black : .secondary)
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.callout).bold()
                                .foregroundStyle(isSelected ? .black : .primary)
                            Circle()
                                .fill(hasRecords ? (isSelected ? .white : Color(hex: "FFD52E")) : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color(hex: "FFD52E") : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.hapticPress(dimBackground: false))
                }
            }
        }
    }

    private var selectedDateRecordsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recordsForSelectedDate.isEmpty {
                Text(String(localized: "home.noRecords", defaultValue: "해당 날짜의 운동 기록이 없습니다."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(recordsForSelectedDate) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.exercise?.localizedName ?? "알 수 없는 운동")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        let completedSets = record.sets.filter { $0.isCompleted }.sorted { $0.order < $1.order }
                        if completedSets.isEmpty {
                            Text(String(localized: "home.noCompletedSets", defaultValue: "완료된 세트 없음"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(completedSets) { setRecord in
                                Text(setText(for: setRecord, exerciseType: record.exercise?.type ?? .weightAndReps))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func setText(for setRecord: SetRecord, exerciseType: ExerciseType) -> String {
        switch exerciseType {
        case .weightAndReps, .assistedWeightAndReps:
            let weightStr = setRecord.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", setRecord.weight) : String(format: "%.1f", setRecord.weight)
            return "\(setRecord.order)세트: \(weightStr)kg × \(setRecord.reps)회"
        case .repsOnly:
            return "\(setRecord.order)세트: \(setRecord.reps)회"
        case .timeOnly:
            return "\(setRecord.order)세트: \(setRecord.timeDuration)초"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StreakBannerView(dailySummaries: dailySummaries)
                }

                Section {
                    VStack(spacing: 16) {
                        weekDaysView
                        selectedDateRecordsView
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                Section {
                    if routines.isEmpty {
                        Text(String(localized: "routines.emptyDescription", defaultValue: "새로운 루틴을 추가해보세요."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(routine.name)
                                                .font(.headline)
                                            Text(String(localized: "routines.exerciseCount", defaultValue: "\(routine.exercises.count)개 운동"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.footnote.bold())
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                }
                            }
                            .buttonStyle(.hapticPress)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(routine)
                                } label: {
                                    Label(String(localized: "common.delete", defaultValue: "삭제"), systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(String(localized: "routines.title", defaultValue: "내 루틴"))
                        Spacer()
                        Button {
                            if routines.count >= 20 {
                                showRoutineLimitAlert = true
                            } else {
                                newRoutineName = ""
                                showAddRoutineAlert = true
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.body.bold())
                        }
                        .textCase(nil)
                    }
                }

            }
            .navigationTitle(String(localized: "home.title"))

            .sheet(isPresented: $showAddSheet) {
                AddWorkoutRecordView(date: selectedDate) { newRecord in
                    recordToNavigate = newRecord
                }
            }
            .navigationDestination(item: $recordToNavigate) { record in
                WorkoutDetailView(record: record, isLocked: isFinished)
            }
            .navigationDestination(item: $routineToNavigate) { routine in
                RoutineDetailView(routine: routine)
            }
            .onReceive(NotificationCenter.default.publisher(for: .startWorkoutWithRoutine)) { notification in
                if let routineId = notification.object as? UUID,
                   let matched = routines.first(where: { $0.id == routineId }) {
                    routineToNavigate = matched
                }
            }
            .alert(String(localized: "routines.addTitle", defaultValue: "루틴 추가"), isPresented: $showAddRoutineAlert) {
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
            .alert(String(localized: "routines.limitTitle", defaultValue: "루틴 개수 제한"), isPresented: $showRoutineLimitAlert) {
                Button(String(localized: "common.ok", defaultValue: "확인"), role: .cancel) { }
            } message: {
                Text(String(localized: "routines.limitMessage", defaultValue: "루틴은 최대 20개까지만 만들 수 있습니다."))
            }
            .alert("루틴 업데이트", isPresented: $showUpdateRoutineAlert) {
                Button("업데이트", role: .destructive) {
                    updateRoutinesFromToday()
                }
                Button("건너뛰기", role: .cancel) { }
            } message: {
                if routinesToUpdate.count == 1 {
                    Text("오늘 진행한 운동 기록을 바탕으로 '\(routinesToUpdate.first?.name ?? "")' 루틴의 기본 중량과 횟수를 업데이트하시겠습니까?")
                } else {
                    Text("오늘 진행한 운동 기록을 바탕으로 사용된 루틴들의 기본 중량과 횟수를 업데이트하시겠습니까?")
                }
            }
        }
    }
    private func updateRoutinesFromToday() {
        for routine in routinesToUpdate {
            // Find records for this routine
            let relevantRecords = recordsForSelectedDate.filter { $0.originRoutineID == routine.id }
            
            for record in relevantRecords {
                guard let exercise = record.exercise else { continue }
                // Find matching routine exercise
                if let rExercise = routine.exercises.first(where: { $0.exercise?.id == exercise.id }) {
                    // Delete old routine sets
                    for oldSet in rExercise.sets {
                        modelContext.delete(oldSet)
                    }
                    rExercise.sets.removeAll()
                    
                    // Create new routine sets from completed sets
                    let completedSets = record.sets.filter { $0.isCompleted }.sorted { $0.order < $1.order }
                    for (i, setRecord) in completedSets.enumerated() {
                        let newRoutineSet = RoutineSet(order: i + 1)
                        newRoutineSet.weight = setRecord.weight
                        newRoutineSet.reps = setRecord.reps
                        newRoutineSet.timeDuration = setRecord.timeDuration
                        newRoutineSet.routineExercise = rExercise
                        modelContext.insert(newRoutineSet)
                    }
                }
            }
        }
        routinesToUpdate.removeAll()
    }
}

struct WorkoutRecordRow: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.exercise?.localizedName ?? "")
                .font(.headline)
            HStack {
                Text("\(record.sets.count) " + String(localized: "home.sets"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if record.totalVolume > 0 {
                    Text("·")
                        .foregroundStyle(.secondary)
                    if record.exercise?.type == .weightAndReps {
                        Text(String(format: "%.0f kg", record.totalVolume))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatDuration(Int(record.totalVolume)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

func formatDuration(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    if m > 0 {
        return String(format: "%dm %ds", m, s)
    }
    return String(format: "%ds", s)
}
