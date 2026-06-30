import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        String(localized: "exercises.empty"),
                        systemImage: "dumbbell",
                        description: Text(String(localized: "exercises.emptyDescription"))
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(exercises) { exercise in
                        NavigationLink(destination: ExerciseChartView(exercise: exercise)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.body)
                                Text(exercise.type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(exercises[index])
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "exercises.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddExerciseView()
            }
        }
    }
}

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type: ExerciseType = .weightAndReps

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "exercises.name"), text: $name)
                } header: {
                    Text(String(localized: "exercises.nameHeader"))
                }

                Section {
                    Picker(String(localized: "exercises.type"), selection: $type) {
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(String(localized: "exercises.typeHeader"))
                }
            }
            .navigationTitle(String(localized: "exercises.addTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        let exercise = Exercise(name: name, type: type)
                        modelContext.insert(exercise)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
