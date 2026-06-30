import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var showAddSheet = false
    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.localizedName.localizedCaseInsensitiveContains(searchText) }
    }

    private var groupedExercises: [(BodyPart, [Exercise])] {
        let dict = Dictionary(grouping: filteredExercises, by: { $0.bodyPart })
        return BodyPart.allCases.compactMap { part in
            if let items = dict[part], !items.isEmpty {
                return (part, items)
            }
            return nil
        }
    }

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
                } else if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedExercises, id: \.0) { part, items in
                        Section(header: Text(part.displayName)) {
                            ForEach(items) { exercise in
                                NavigationLink(destination: ExerciseChartView(exercise: exercise)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.localizedName)
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
                                    modelContext.delete(items[index])
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: String(localized: "common.search", defaultValue: "운동 검색"))
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
    @State private var bodyPart: BodyPart = .chest

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
                
                Section {
                    Picker(String(localized: "exercises.bodyPart", defaultValue: "Body Part"), selection: $bodyPart) {
                        ForEach(BodyPart.allCases, id: \.self) { part in
                            Text(part.displayName).tag(part)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(String(localized: "exercises.bodyPartHeader", defaultValue: "Target Area"))
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
                        let exercise = Exercise(name: name, type: type, bodyPart: bodyPart)
                        modelContext.insert(exercise)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
