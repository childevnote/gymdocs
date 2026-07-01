import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query private var records: [WorkoutRecord]
    @Query private var sets: [SetRecord]
    @Query private var routines: [Routine]
    @Query private var routineExercises: [RoutineExercise]
    @State private var showExportShare = false
    @State private var showImportPicker = false
    @State private var showImportAlert = false
    @State private var importMessage = ""
    @State private var exportURLs: [URL]?
    @State private var showClearAlert = false
    @AppStorage("appColorScheme") private var appColorScheme = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("appLanguage") private var appLanguage = 0 // 0: System, 1: EN, 2: KO, 3: JA

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: $appColorScheme) {
                        Text(String(localized: "settings.theme.system", defaultValue: "시스템 설정")).tag(0)
                        Text(String(localized: "settings.theme.light", defaultValue: "라이트 모드")).tag(1)
                        Text(String(localized: "settings.theme.dark", defaultValue: "다크 모드")).tag(2)
                    } label: {
                        SettingsLabel(title: String(localized: "settings.theme", defaultValue: "화면 모드"), systemImage: "moon.fill", color: .indigo)
                    }
                    .pickerStyle(.navigationLink)
                    Picker(selection: $appLanguage) {
                        Text(String(localized: "settings.language.system", defaultValue: "시스템 설정")).tag(0)
                        Text("English").tag(1)
                        Text("한국어").tag(2)
                        Text("日本語").tag(3)
                    } label: {
                        SettingsLabel(title: String(localized: "settings.language", defaultValue: "언어 설정"), systemImage: "globe", color: .cyan)
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text(String(localized: "settings.appearance", defaultValue: "화면 및 언어"))
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        SettingsLabel(title: String(localized: "settings.export"), systemImage: "square.and.arrow.up", color: .blue)
                    }

                    Button {
                        showImportPicker = true
                    } label: {
                        SettingsLabel(title: String(localized: "settings.import"), systemImage: "square.and.arrow.down", color: .green)
                    }
                    
                    Button {
                        exportCSV()
                    } label: {
                        SettingsLabel(title: String(localized: "settings.exportCSV", defaultValue: "Excel(CSV)로 내보내기"), systemImage: "doc.text.magnifyingglass", color: .orange)
                    }
                } header: {
                    Text(String(localized: "settings.backup"))
                } footer: {
                    Text(String(localized: "settings.backupFooter"))
                }

                Section {
                    Text("GymDocs v1.0")
                        .foregroundStyle(.secondary)
                } header: {
                    Text(String(localized: "settings.about"))
                }

                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        SettingsLabel(title: String(localized: "settings.clearAllData"), systemImage: "trash.fill", color: .red)
                    }
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .sheet(isPresented: $showExportShare) {
                if let urls = exportURLs {
                    ShareSheet(activityItems: urls)
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                importData(result: result)
            }
            .alert(String(localized: "settings.importResult"), isPresented: $showImportAlert) {
                Button(String(localized: "common.ok")) { }
            } message: {
                Text(importMessage)
            }
            .alert(String(localized: "settings.clearAlertTitle"), isPresented: $showClearAlert) {
                Button(String(localized: "common.cancel"), role: .cancel) { }
                Button(String(localized: "common.delete"), role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text(String(localized: "settings.clearAlertMessage"))
            }
        }
    }

    private func clearAllData() {
        do {
            try modelContext.delete(model: RoutineExercise.self)
            try modelContext.delete(model: Routine.self)
            try modelContext.delete(model: SetRecord.self)
            try modelContext.delete(model: WorkoutRecord.self)
            try modelContext.delete(model: Exercise.self)
            
            Exercise.seedDefaultExercises(into: modelContext)
            
            importMessage = String(localized: "settings.clearSuccess")
            showImportAlert = true
        } catch {
            importMessage = error.localizedDescription
            showImportAlert = true
        }
    }

    private func exportData() {
        let settingsDTO = SettingsDTO(
            hasCompletedOnboarding: UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"),
            userHeight: UserDefaults.standard.double(forKey: "userHeight"),
            userWeight: UserDefaults.standard.double(forKey: "userWeight")
        )
        
        let backup = BackupData(
            version: 1,
            settings: settingsDTO,
            exercises: exercises.map { ExerciseDTO(from: $0) },
            records: records.map { WorkoutRecordDTO(from: $0) },
            sets: sets.map { SetRecordDTO(from: $0) },
            routines: routines.map { RoutineDTO(from: $0) },
            routineExercises: routineExercises.map { RoutineExerciseDTO(from: $0) }
        )

        do {
            let data = try JSONEncoder().encode(backup)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "GymDocs_backup_\(formatter.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            exportURLs = [tempURL]
            showExportShare = true
        } catch {
            importMessage = error.localizedDescription
            showImportAlert = true
        }
    }

    private func exportCSV() {
        if let urls = CSVExporter.generateCSVURLs(routines: routines, records: records) {
            exportURLs = urls
            showExportShare = true
        } else {
            importMessage = String(localized: "settings.noDataToExport", defaultValue: "내보낼 데이터가 없습니다.")
            showImportAlert = true
        }
    }

    private func importData(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importMessage = String(localized: "settings.importAccessError")
                showImportAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let backup = try JSONDecoder().decode(BackupData.self, from: data)

                // Wipe existing data before import
                try modelContext.delete(model: RoutineExercise.self)
                try modelContext.delete(model: Routine.self)
                try modelContext.delete(model: SetRecord.self)
                try modelContext.delete(model: WorkoutRecord.self)
                try modelContext.delete(model: Exercise.self)

                // Restore Settings
                if let settings = backup.settings {
                    UserDefaults.standard.set(settings.hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
                    UserDefaults.standard.set(settings.userHeight, forKey: "userHeight")
                    UserDefaults.standard.set(settings.userWeight, forKey: "userWeight")
                }

                // Insert exercises
                var exerciseMap: [UUID: Exercise] = [:]
                for dto in backup.exercises {
                    let exercise = Exercise(name: dto.name, type: dto.type, bodyPart: dto.bodyPart)
                    exercise.id = dto.id
                    exercise.createdAt = dto.createdAt
                    modelContext.insert(exercise)
                    exerciseMap[dto.id] = exercise
                }

                // Insert records
                var recordMap: [UUID: WorkoutRecord] = [:]
                for dto in backup.records {
                    if let exercise = exerciseMap[dto.exerciseId] {
                        let record = WorkoutRecord(date: dto.date, exercise: exercise)
                        record.id = dto.id
                        modelContext.insert(record)
                        recordMap[dto.id] = record
                    }
                }

                // Insert sets
                for dto in backup.sets {
                    if let record = recordMap[dto.workoutRecordId] {
                        let setRecord = SetRecord(order: dto.order, workoutRecord: record)
                        setRecord.id = dto.id
                        setRecord.weight = dto.weight
                        setRecord.reps = dto.reps
                        setRecord.timeDuration = dto.timeDuration
                        setRecord.restTimeAfterSet = dto.restTimeAfterSet
                        setRecord.rangeOfMotion = dto.rangeOfMotion
                        setRecord.isCompleted = dto.isCompleted
                        modelContext.insert(setRecord)
                    }
                }
                
                // Insert routines
                var routineMap: [UUID: Routine] = [:]
                if let backupRoutines = backup.routines {
                    for dto in backupRoutines {
                        let routine = Routine(name: dto.name)
                        routine.id = dto.id
                        routine.createdAt = dto.createdAt
                        modelContext.insert(routine)
                        routineMap[dto.id] = routine
                    }
                }
                
                // Insert routine exercises
                if let backupRoutineEx = backup.routineExercises {
                    for dto in backupRoutineEx {
                        guard let rId = dto.routineId, let routine = routineMap[rId] else { continue }
                        guard let exId = dto.exerciseId, let exercise = exerciseMap[exId] else { continue }
                        
                        let rEx = RoutineExercise(order: dto.order, type: dto.type, exercise: exercise)
                        rEx.id = dto.id
                        routine.exercises.append(rEx)
                    }
                }

                importMessage = String(localized: "settings.importSuccess")
                showImportAlert = true
            } catch {
                importMessage = error.localizedDescription
                showImportAlert = true
            }

        case .failure(let error):
            importMessage = error.localizedDescription
            showImportAlert = true
        }
    }
}

// MARK: - ShareSheet UIKit wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsLabel: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)
        }
    }
}
