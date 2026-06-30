import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query private var records: [WorkoutRecord]
    @Query private var sets: [SetRecord]
    @State private var showExportShare = false
    @State private var showImportPicker = false
    @State private var showImportAlert = false
    @State private var importMessage = ""
    @State private var exportURL: URL?
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(String(localized: "settings.totalExercises"))
                        Spacer()
                        Text("\(exercises.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(String(localized: "settings.totalRecords"))
                        Spacer()
                        Text("\(records.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "settings.stats"))
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        Label(String(localized: "settings.export"), systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showImportPicker = true
                    } label: {
                        Label(String(localized: "settings.import"), systemImage: "square.and.arrow.down")
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
                        Text(String(localized: "settings.clearAllData"))
                    }
                }
            }
            .navigationTitle(String(localized: "settings.title"))
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
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
        let backup = BackupData(
            exercises: exercises.map { ExerciseDTO(from: $0) },
            records: records.map { WorkoutRecordDTO(from: $0) },
            sets: sets.map { SetRecordDTO(from: $0) }
        )

        do {
            let data = try JSONEncoder().encode(backup)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "GymDocs_backup_\(formatter.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            exportURL = tempURL
            showExportShare = true
        } catch {
            importMessage = error.localizedDescription
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

                // Insert exercises
                var exerciseMap: [UUID: Exercise] = [:]
                for dto in backup.exercises {
                    let exercise = Exercise(name: dto.name, type: dto.type)
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
