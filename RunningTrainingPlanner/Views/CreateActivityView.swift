//
//  SelectActivityTypeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/31/26.
//
import SwiftUI
import SwiftData

struct CreateActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Fetches all plans from SwiftData so the user can tag this activity to one
    @Query private var plans: [Plan]

    @State private var name: String = ""
    @State private var selectedType: ActivityType? = nil
    @State private var notes: String = ""
    @State private var date: Date
    @State private var time: Date? = nil        // nil means no time has been set
    @State private var showTimePicker = false   // controls the time DisclosureGroup

    // Both required fields must be filled; guards against whitespace-only names.
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedType != nil
    }

    // Allows an optional starting date to be passed in (e.g. from DayView), defaulting to today.
    // _date is the internal way to set a @State variable from an init parameter.
    init(initialDate: Date = .now) {
        _date = State(initialValue: initialDate)
    }
    @State private var distance: Double? = nil
    @State private var distanceUnit: DistanceUnit = .miles
    @State private var paceMinutes: Int = 0
    @State private var paceSeconds: Int = 0
    @State private var selectedPaceTag: PaceTag? = nil
    @State private var showPacePicker = false
    @State private var selectedPlan: Plan? = nil  // optional — activity doesn't have to belong to a plan
    @State private var duration: Int = 10

    var body: some View {
        VStack(spacing: 0) {
        Form {
            // Name and type section
            Section {
                TextField("Activity name", text: $name)
                Picker("Activity Type", selection: $selectedType) {
                    // The nil option must be typed as ActivityType? so it matches selectedType.
                    Text("Choose a type...").tag(nil as ActivityType?)
                    // id: \.self means each enum case identifies itself — required for ForEach over enum values.
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as ActivityType?)
                    }
                }
            }

            // Date, time, and activity-specific fields
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)

                // Collapsible time row — shows "Not set" until the user opens it.
                // When first opened, initializes to the current time so the wheels have a sensible default.
                DisclosureGroup(
                    isExpanded: $showTimePicker,
                    content: {
                        // Binding wraps time (Date?) into the non-optional Date the picker needs
                        DatePicker("", selection: Binding(get: { time ?? .now }, set: { time = $0 }), displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    },
                    label: {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(time.map { $0.formatted(.dateTime.hour().minute()) } ?? "Not set")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
                .onChange(of: showTimePicker) { _, newValue in
                    // Set a default time the first time the picker is opened
                    if newValue && time == nil {
                        time = .now
                    }
                }

                // Distance field — only shown for run and walk types
                if selectedType == .run || selectedType == .walk {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("", value: $distance, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing) // aligns the number to the right like other form values
                            .frame(width: 70)
                        Picker("Unit", selection: $distanceUnit) {
                            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu) // compact dropdown instead of a wheel
                        .labelsHidden()
                        .tint(.primary) // matches the color of other form text instead of defaulting to blue
                    }
                }

                // Run type picker — only shown for runs
                if selectedType == .run {
                    Picker("Run type", selection: $selectedPaceTag) {
                        Text("None").tag(nil as PaceTag?)
                        ForEach(PaceTag.allCases, id: \.self) { tag in
                            Text(tag.rawValue).tag(tag as PaceTag?)
                        }
                    }
                }

                // Pace picker — only shown for runs
                if selectedType == .run {
                    // Collapsible row — tapping the label shows/hides the pickers.
                    // isExpanded: when showPacePicker is true the pickers are visible; tapping the row flips it.
                    DisclosureGroup(
                        isExpanded: $showPacePicker,
                        content: {
                            HStack {
                                Spacer()
                                Picker("Minutes", selection: $paceMinutes) {
                                    ForEach(0..<60) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 50)
                                Text(":")
                                Picker("Seconds", selection: $paceSeconds) {
                                    // %02d zero-pads to two digits (e.g. 5 → "05")
                                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 50)
                                Text("min/\(distanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            }
                        },
                        label: {
                            HStack {
                                Text("Pace")
                                Spacer()
                                Text("\(paceMinutes):\(String(format: "%02d", paceSeconds)) min/\(distanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    )
                }

                // Duration picker — only shown for rock climbing
                if selectedType == .rockClimb {
                    // stride generates values from 10 to 300 in steps of 10 (10, 20, 30 ... 300)
                    Picker("Duration", selection: $duration) {
                        ForEach(Array(stride(from: 10, through: 300, by: 10)), id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                }

            }

            // Plan section — only shown if at least one plan exists
            if !plans.isEmpty {
                Section {
                    Picker("Plan", selection: $selectedPlan) {
                        Text("None").tag(nil as Plan?)
                        ForEach(plans) { plan in
                            Text(plan.name).tag(plan as Plan?)
                        }
                    }
                }
            }

            // Notes section
            Section {
                // axis: .vertical makes the field grow downward as the user types more text
                TextField("Notes", text: $notes, axis: .vertical)
            }

        }
        .contentMargins(.top, 20, for: .scrollContent) // space between top nav bar and first field

        Button("Create Activity") {
            saveActivity()
        }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color(.systemGray4)) // grey when invalid, blue when ready
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom)
            .disabled(!isFormValid) // prevents tapping when form is incomplete
        }
        .navigationTitle("Activity")
        .toolbar {
            // "Activity" title centered in the nav bar, slightly larger than the default inline size
            ToolbarItem(placement: .principal) {
                Text("Activity")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
    }

    private func saveActivity() {
        guard let type = selectedType else { return }

        // Only save pace if the user set a non-zero value; convert min+sec to total seconds
        let pace: Int? = (paceMinutes > 0 || paceSeconds > 0) ? paceMinutes * 60 + paceSeconds : nil

        let activity = Activity(
            name: name,
            date: date,
            time: time,
            type: type,
            notes: notes.isEmpty ? nil : notes,
            distance: (type == .run || type == .walk) ? distance : nil,
            distanceUnit: (type == .run || type == .walk) ? distanceUnit : nil,
            pace: type == .run ? pace : nil,
            paceTag: type == .run ? selectedPaceTag : nil,
            duration: type == .rockClimb ? duration : nil
        )
        activity.plan = selectedPlan
        modelContext.insert(activity)
        dismiss()
    }

}

#Preview {
    let container = try! ModelContainer(for: Activity.self, Plan.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return NavigationStack {
        CreateActivityView()
    }
    .modelContainer(container)
}
