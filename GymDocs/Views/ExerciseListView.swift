import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var selectedBodyPart: BodyPart? = nil

    private var filteredExercises: [Exercise] {
        var result = exercises
        if !searchText.isEmpty {
            result = result.filter { $0.localizedName.localizedCaseInsensitiveContains(searchText) }
        }
        if let bodyPart = selectedBodyPart {
            result = result.filter { $0.bodyPart == bodyPart }
        }
        return result
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
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button {
                            selectedBodyPart = nil
                        } label: {
                            Text(String(localized: "common.all", defaultValue: "All"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedBodyPart == nil ? Color(hex: "FFD52E") : .secondary)
                        .foregroundStyle(.primary)

                        ForEach(BodyPart.allCases, id: \.self) { part in
                            Button {
                                selectedBodyPart = part
                            } label: {
                                Text(part.displayName)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedBodyPart == part ? Color(hex: "FFD52E") : .secondary)
                            .foregroundStyle(.primary)
                        }
                    }
                    .padding()
                }
                
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
                                    Text(exercise.localizedName)
                                        .font(.body)
                                }
                                .buttonStyle(.hapticPress)
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
