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
    @State private var duration: Int?

    @State private var showDiscardAlert = false
    @State private var showDeleteAlert = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var userProfile: User? = nil

    // Both required fields must be filled; guards against whitespace-only names.
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedType != nil
    }

    private var isEditMode: Bool { activity != nil }

    // Only plans whose race date is today or later — past plans are excluded from the picker
    private var activePlans: [Plan] {
        let today = Calendar.current.startOfDay(for: .now)
        return plans.filter { $0.raceDate >= today }
    }

    // True when any field differs from the saved activity (edit mode), or when the user has
    // entered any data in creation mode — used to gate the discard alert.
    private var isModified: Bool {
        guard let a = activity else {
            // In creation mode, warn if the user has typed a name or picked a type
            return !name.isEmpty || selectedType != nil
        }
        let currentPace: Int? = (paceMinutes > 0 || paceSeconds > 0) ? paceMinutes * 60 + paceSeconds : nil
        return name != a.name ||
               selectedType != a.type ||
               notes != (a.notes ?? "") ||
               date != a.date ||
               time.map { APIService.timeString(from: $0) } != a.time.flatMap { APIService.date(fromTimeString: $0) }.map { APIService.timeString(from: $0) } ||
               distance != a.distance ||
               distanceUnit != (a.distanceUnit ?? .miles) ||
               currentPace != a.pace ||
               selectedPaceTag != a.paceTag ||
               duration != a.duration ||
               selectedPlan?.planId != a.planId
    }

    // In edit mode the button is only active when there's something to save
    private var canSave: Bool {
        isEditMode ? (isFormValid && isModified) : isFormValid
    }

    // True when the view is presented as a sheet (tab bar +); shows a Cancel button instead of relying on the system back arrow
    let isModal: Bool
    // Called after a successful edit save when the activity's date moved to a different day
    let onDateChanged: ((Date) -> Void)?

    // Creation mode: only initialDate is needed; all other fields start empty/default.
    // Edit mode: pre-fills every field from the existing activity.
    init(initialDate: Date = .now, activity: Activity? = nil, isModal: Bool = false, onDateChanged: ((Date) -> Void)? = nil) {
        self.isModal = isModal
        self.onDateChanged = onDateChanged
        self.activity = activity
        if let a = activity {
            _name = State(initialValue: a.name)
            _selectedType = State(initialValue: a.type)
            _notes = State(initialValue: a.notes ?? "")
            _date = State(initialValue: a.date)
            _time = State(initialValue: a.time.flatMap { APIService.date(fromTimeString: $0) })
            _distance = State(initialValue: a.distance)
            _distanceUnit = State(initialValue: a.distanceUnit ?? .miles)
            _selectedPaceTag = State(initialValue: a.paceTag)
            _selectedPlan = State(initialValue: nil) // pre-filled after plans load in .task
            _duration = State(initialValue: a.duration)
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
            _duration = State(initialValue: nil)
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
                    Picker("Duration", selection: $duration) {
                        Text("Not set").tag(nil as Int?)
                        // stride generates values from 10 to 300 in steps of 10 (10, 20, 30 ... 300)
                        ForEach(Array(stride(from: 10, through: 300, by: 10)), id: \.self) { min in
                            Text("\(min) min").tag(min as Int?)
                        }
                    }
                }

            }

            // Plan section — only shown if at least one active plan exists
            if !activePlans.isEmpty {
                Section {
                    Picker("Plan", selection: $selectedPlan) {
                        Text("None").tag(nil as Plan?)
                        ForEach(activePlans) { plan in
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
        // Hides the system back button when showing our own Cancel or custom back button
        .navigationBarBackButtonHidden((isModal && !isEditMode) || (isEditMode && isModified))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isEditMode ? "Edit Activity" : "New Activity")
                    .font(.title)
                    .fontWeight(.bold)
            }
            if isModal && !isEditMode {
                // Cancel button — shown instead of the system back button when opened modally
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isModified { showDiscardAlert = true } else { dismiss() }
                    }
                }
            } else if isModified {
                // Custom back button shown only in edit mode when there are unsaved changes
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }
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
                    .tint(canSave ? Color.appAccent : nil)
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
        // Error alert — shown when save or delete fails
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        // Loads plans and user profile concurrently; each fails independently so one won't block the other
        .task {
            async let plansTask = APIService.fetchMyPlans()
            async let profileTask = APIService.fetchMyProfile()
            if let fetchedPlans = try? await plansTask {
                plans = fetchedPlans
                if let planId = activity?.planId {
                    selectedPlan = plans.first { $0.planId == planId }
                }
            }
            userProfile = try? await profileTask
        }
        // When the pace tag changes, pre-fill the pace wheels with the user's default for that type.
        // If the user has no default set for that tag, resets to 0:00. Selecting None leaves pace untouched.
        .onChange(of: selectedPaceTag) { _, newTag in
            guard let tag = newTag else { return }
            let defaultSeconds: Int?
            switch tag {
            case .easy:     defaultSeconds = userProfile?.easyPace
            case .longRun:  defaultSeconds = userProfile?.longRunPace
            case .speed:    defaultSeconds = userProfile?.speedPace
            }
            let total = defaultSeconds ?? 0
            paceMinutes = total / 60
            paceSeconds = total % 60
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
                        // If plans failed to load, the picker was never shown — preserve the existing plan association
                        planId: plans.isEmpty ? activity?.planId : selectedPlan?.planId,
                        time: timeStr,
                        notes: notesStr,
                        distance: distance,
                        distanceUnit: (type == .run || type == .walk) ? distanceUnit : nil,
                        pace: type == .run ? paceTotal : nil,
                        paceTag: type == .run ? selectedPaceTag : nil,
                        duration: type == .rockClimb ? duration : nil
                    )
                    // Notify the caller if the activity moved to a different day
                    if !Calendar.current.isDate(date, inSameDayAs: existing.date) {
                        onDateChanged?(date)
                    }
                } else {
                    // Create mode — post a new activity
                    _ = try await APIService.createActivity(
                        name: name,
                        date: date,
                        type: type,
                        planId: selectedPlan?.planId,
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
                errorMessage = "Could not save activity. Please check your connection and try again."
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
                errorMessage = "Could not delete activity. Please check your connection and try again."
            }
        }
    }

}

#Preview {
    NavigationStack {
        CreateActivityView()
    }
}
