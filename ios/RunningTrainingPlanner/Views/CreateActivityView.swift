//
//  SelectActivityTypeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/31/26.
//
import SwiftUI

struct CreateActivityView: View {
    @Environment(\.dismiss) private var dismiss

    // Populated from the API once data loading is wired in
    @State private var plans: [Plan] = []

    // When non-nil, the view is in edit mode and will update this activity instead of creating a new one
    let activity: Activity?

    @State private var name: String
    @State private var selectedType: ActivityType?
    @State private var notes: String
    @State private var date: Date
    @State private var time: Date?
    @State private var showTimePicker = false
    @State private var distance: Double?
    @State private var distanceUnit: DistanceUnit
    @State private var paceMinutes: Int
    @State private var paceSeconds: Int
    @State private var selectedPaceTag: PaceTag?
    @State private var showPacePicker = false
    @State private var selectedPlan: Plan?
    @State private var duration: Int

    @State private var showDiscardAlert = false
    @State private var showDeleteAlert = false
    @State private var isSaving = false

    // Both required fields must be filled; guards against whitespace-only names.
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedType != nil
    }

    private var isEditMode: Bool { activity != nil }

    // True when any field differs from the saved activity — only relevant in edit mode.
    private var isModified: Bool {
        guard let a = activity else { return false }
        let currentPace: Int? = (paceMinutes > 0 || paceSeconds > 0) ? paceMinutes * 60 + paceSeconds : nil
        return name != a.name ||
               selectedType != a.type ||
               notes != (a.notes ?? "") ||
               date != a.date ||
               distance != a.distance ||
               distanceUnit != (a.distanceUnit ?? .miles) ||
               currentPace != a.pace ||
               selectedPaceTag != a.paceTag ||
               duration != (a.duration ?? 10)
    }

    // In edit mode the button is only active when there's something to save
    private var canSave: Bool {
        isEditMode ? (isFormValid && isModified) : isFormValid
    }

    // Creation mode: only initialDate is needed; all other fields start empty/default.
    // Edit mode: pre-fills every field from the existing activity.
    init(initialDate: Date = .now, activity: Activity? = nil) {
        self.activity = activity
        if let a = activity {
            _name = State(initialValue: a.name)
            _selectedType = State(initialValue: a.type)
            _notes = State(initialValue: a.notes ?? "")
            _date = State(initialValue: a.date)
            _time = State(initialValue: nil) // time is stored as String in backend; not pre-filled yet
            _distance = State(initialValue: a.distance)
            _distanceUnit = State(initialValue: a.distanceUnit ?? .miles)
            _selectedPaceTag = State(initialValue: a.paceTag)
            _selectedPlan = State(initialValue: nil) // plan linking not wired yet
            _duration = State(initialValue: a.duration ?? 10)
            let totalPace = a.pace ?? 0
            _paceMinutes = State(initialValue: totalPace / 60)
            _paceSeconds = State(initialValue: totalPace % 60)
        } else {
            _date = State(initialValue: initialDate)
            _name = State(initialValue: "")
            _selectedType = State(initialValue: nil)
            _notes = State(initialValue: "")
            _time = State(initialValue: nil)
            _distance = State(initialValue: nil)
            _distanceUnit = State(initialValue: .miles)
            _selectedPaceTag = State(initialValue: nil)
            _selectedPlan = State(initialValue: nil)
            _duration = State(initialValue: 10)
            _paceMinutes = State(initialValue: 0)
            _paceSeconds = State(initialValue: 0)
        }
    }

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

        if isEditMode {
            // Delete button — only visible when editing an existing activity
            Button("Delete Activity", role: .destructive) {
                showDeleteAlert = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemRed))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom)
        } else {
            Button("Create Activity") {
                saveActivity()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSave ? Color.appAccent : Color(.systemGray4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom)
            .disabled(!canSave || isSaving)
        }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Hides the system back button when there are unsaved edits, so the user can't bypass the alert
        .navigationBarBackButtonHidden(isEditMode && isModified)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isEditMode ? "Edit Activity" : "New Activity")
                    .font(.title)
                    .fontWeight(.bold)
            }
            if isEditMode && isModified {
                // Custom back button shown only in edit mode when there are unsaved changes
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            } else if !isEditMode {
                // Cancel button in create mode — dismisses the sheet or pops the navigation stack
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Checkmark save button — only visible in edit mode when there's something to save
            if isEditMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveActivity()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard Edits", role: .destructive) { dismiss() }
        } message: {
            Text("You have unsaved changes. Going back will discard them.")
        }
        .alert("Delete Activity", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteActivity() }
        } message: {
            Text("This will permanently delete \"\(activity?.name ?? "this activity")\". This action cannot be undone.")
        }
        // Loads the user's plans so the plan picker appears if any exist
        .task {
            do {
                plans = try await APIService.fetchMyPlans()
            } catch {
                // Plan picker stays hidden if fetch fails
            }
        }
    }

    private func saveActivity() {
        guard let type = selectedType else { return }
        let paceTotal: Int? = (paceMinutes > 0 || paceSeconds > 0) ? paceMinutes * 60 + paceSeconds : nil
        let timeStr: String? = time.map { APIService.timeString(from: $0) }
        let notesStr: String? = notes.isEmpty ? nil : notes
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                if let existing = activity {
                    // Edit mode — update the existing activity
                    _ = try await APIService.updateActivity(
                        id: existing.activityId,
                        name: name,
                        date: date,
                        type: type,
                        time: timeStr,
                        notes: notesStr,
                        distance: distance,
                        distanceUnit: (type == .run || type == .walk) ? distanceUnit : nil,
                        pace: type == .run ? paceTotal : nil,
                        paceTag: type == .run ? selectedPaceTag : nil,
                        duration: type == .rockClimb ? duration : nil
                    )
                } else {
                    // Create mode — post a new activity
                    _ = try await APIService.createActivity(
                        name: name,
                        date: date,
                        type: type,
                        time: timeStr,
                        notes: notesStr,
                        distance: distance,
                        distanceUnit: (type == .run || type == .walk) ? distanceUnit : nil,
                        pace: type == .run ? paceTotal : nil,
                        paceTag: type == .run ? selectedPaceTag : nil,
                        duration: type == .rockClimb ? duration : nil
                    )
                }
                dismiss()
            } catch {
                // TODO: surface error to user
            }
        }
    }

    private func deleteActivity() {
        guard let existing = activity else { return }
        Task {
            do {
                try await APIService.deleteActivity(id: existing.activityId)
                dismiss()
            } catch {
                // TODO: surface error to user
            }
        }
    }

}

#Preview {
    NavigationStack {
        CreateActivityView()
    }
}
