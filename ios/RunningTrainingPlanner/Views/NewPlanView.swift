//
//  NewPlanView.swift
//  RunningTrainingPlanner
//

import SwiftUI
import SwiftData

struct NewPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // @State variables are local to this view — when their value changes, SwiftUI automatically re-renders the UI.
    @State private var name: String = ""
    @State private var goalDistance: Double? = nil
    @State private var goalHours: Int = 0
    @State private var goalMinutes: Int = 0
    @State private var goalSeconds: Int = 0
    @State private var showGoalTimePicker = false
    @State private var raceDate: Date = Date.now

    // Both required fields must be filled; guards against whitespace-only names.
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && goalDistance != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                // First section
                Section {
                    TextField("Plan name", text: $name)
                    TextField("Distance", value: $goalDistance, format: .number)
                        .keyboardType(.decimalPad)
                }

                // Race date section
                Section {
                    DatePicker("Race date", selection: $raceDate, displayedComponents: .date)
                }

                // Goal time section
                Section {
                    // Collapsible row — tapping the label shows/hides the pickers.
                    // isExpanded: when showGoalTimePicker is true the pickers are visible; tapping the row flips it.
                    DisclosureGroup(
                        isExpanded: $showGoalTimePicker,
                        content: {
                            HStack {
                                Spacer()
                                Picker("Hours", selection: $goalHours) {
                                    // $0 is the current number as ForEach counts 0–23.
                                    // .tag sets the value saved to goalHours when that row is selected.
                                    ForEach(0..<24) { Text("\($0)h").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70) // keeps this column at a fixed narrow width
                                Text(":")
                                Picker("Minutes", selection: $goalMinutes) {
                                    // %02d zero-pads to two digits (e.g. 5 → "05")
                                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60)
                                Text(":")
                                Picker("Seconds", selection: $goalSeconds) {
                                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60)
                                Spacer()
                            }
                            .labelsHidden() // hides the "Hours" / "Minutes" / "Seconds" labels above each wheel
                        },
                        label: {
                            HStack {
                                Text("Goal time")
                                Spacer()
                                Text("\(goalHours):\(String(format: "%02d", goalMinutes)):\(String(format: "%02d", goalSeconds))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    )
                }
            }
            .contentMargins(.top, 20, for: .scrollContent) // space between top nav bar and first field

            Button("Create Plan") {
                savePlan()
            }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.appAccent : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(!isFormValid) // prevents tapping when form is incomplete
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Run Plan")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }
    private func savePlan() {
        guard let distance = goalDistance else { return }

        // Only save goal time if the user set a non-zero value; convert h/m/s to total seconds
        let goalTime: Int? = (goalHours > 0 || goalMinutes > 0 || goalSeconds > 0)
            ? goalHours * 3600 + goalMinutes * 60 + goalSeconds
            : nil

        let plan = Plan(name: name, distance: distance, raceDate: raceDate, goalTimeSeconds: goalTime)
        modelContext.insert(plan)
        dismiss()
    }

}

#Preview {
    let container = try! ModelContainer(for: Activity.self, Plan.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    NavigationStack {
        NewPlanView()
    }
    .modelContainer(container)
}
