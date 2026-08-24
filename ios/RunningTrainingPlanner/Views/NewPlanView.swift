//
//  NewPlanView.swift
//  RunningTrainingPlanner
//

import SwiftUI

// The four supported race distances. Distances are always stored in km.
enum RaceDistance: CaseIterable {
    case fiveK, tenK, halfMarathon, marathon

    var label: String {
        switch self {
        case .fiveK: return "5K"
        case .tenK: return "10K"
        case .halfMarathon: return "Half Marathon"
        case .marathon: return "Marathon"
        }
    }

    var distanceKm: Double {
        switch self {
        case .fiveK: return 5.0
        case .tenK: return 10.0
        case .halfMarathon: return 21.0975
        case .marathon: return 42.195
        }
    }

    // Maps a stored distance label (e.g. "Marathon") back to a RaceDistance case
    static func from(label: String) -> RaceDistance? {
        allCases.first { $0.label == label }
    }
}

struct NewPlanView: View {
    @Environment(\.dismiss) private var dismiss

    // When non-nil, the view is in edit mode and will update this plan instead of creating a new one
    let plan: Plan?
    let isModal: Bool

    @State private var name: String
    @State private var selectedRace: RaceDistance?
    @State private var goalHours: Int
    @State private var goalMinutes: Int
    @State private var goalSeconds: Int
    @State private var showGoalTimePicker: Bool
    @State private var raceDate: Date

    @State private var isPublic: Bool
    @State private var selectedColor: String
    @State private var showDiscardAlert = false
    @State private var showDeleteAlert = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    private var isEditMode: Bool { plan != nil }

    // Both required fields must be filled; guards against whitespace-only names.
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedRace != nil
    }

    // True when any field differs from the saved plan (edit mode), or when the user has
    // entered any data in creation mode — used to gate the discard alert.
    private var isModified: Bool {
        guard let p = plan else {
            // In creation mode, warn if the user has typed a name or picked a distance
            return !name.isEmpty || selectedRace != nil
        }
        let currentGoalSeconds = goalHours * 3600 + goalMinutes * 60 + goalSeconds
        return name != p.name ||
               selectedRace != RaceDistance.from(label: p.distance) ||
               raceDate != p.raceDate ||
               currentGoalSeconds != (p.goalTimeSeconds ?? 0) ||
               isPublic != (p.isPublic ?? false) ||
               selectedColor != p.planColor
    }

    // In edit mode the button is only active when there's something to save
    private var canSave: Bool {
        isEditMode ? (isFormValid && isModified) : isFormValid
    }

    // Creation mode: blank form. Edit mode: pre-filled from the existing plan.
    init(plan: Plan? = nil, isModal: Bool = false) {
        self.plan = plan
        self.isModal = isModal
        if let p = plan {
            _name = State(initialValue: p.name)
            _selectedRace = State(initialValue: RaceDistance.from(label: p.distance))
            _raceDate = State(initialValue: p.raceDate)
            let totalSeconds = p.goalTimeSeconds ?? 0
            _goalHours = State(initialValue: totalSeconds / 3600)
            _goalMinutes = State(initialValue: (totalSeconds % 3600) / 60)
            _goalSeconds = State(initialValue: totalSeconds % 60)
            _isPublic = State(initialValue: p.isPublic ?? false)
            _selectedColor = State(initialValue: p.planColor)
            _showGoalTimePicker = State(initialValue: false)
        } else {
            _name = State(initialValue: "")
            _selectedRace = State(initialValue: nil)
            _raceDate = State(initialValue: Date.now)
            _goalHours = State(initialValue: 0)
            _goalMinutes = State(initialValue: 0)
            _goalSeconds = State(initialValue: 0)
            _isPublic = State(initialValue: false)
            _selectedColor = State(initialValue: "#808080")
            _showGoalTimePicker = State(initialValue: false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                // Name and race type section
                Section {
                    TextField("Plan name", text: $name)
                    // Race distance picker — replaces free-form distance entry
                    Picker("Race distance", selection: $selectedRace) {
                        Text("Select distance").tag(nil as RaceDistance?)
                        ForEach(RaceDistance.allCases, id: \.self) { race in
                            Text(race.label).tag(race as RaceDistance?)
                        }
                    }
                }

                // Race date section
                Section {
                    DatePicker("Race date", selection: $raceDate, displayedComponents: .date)
                }

                // Goal time section
                Section {
                    // Collapsible row — tapping the label shows/hides the pickers.
                    DisclosureGroup(
                        isExpanded: $showGoalTimePicker,
                        content: {
                            HStack {
                                Spacer()
                                Picker("Hours", selection: $goalHours) {
                                    ForEach(0..<24) { Text("\($0)h").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                Text(":")
                                Picker("Minutes", selection: $goalMinutes) {
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

                // Plan color section — circles pulled from the active theme's palette
                Section("Plan color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(AppPalette.planColorOptions, id: \.self) { hex in
                                Button {
                                    selectedColor = hex
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 30, height: 30)
                                        // Border shows which color is selected
                                        if selectedColor == hex {
                                            Circle()
                                                .strokeBorder(Color.primary, lineWidth: 2)
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Visibility section
                Section {
                    Toggle("Make public", isOn: $isPublic)
                }
            }
            .contentMargins(.top, 20, for: .scrollContent)

            if isEditMode {
                // Delete button — only visible when editing an existing plan
                Button("Delete Plan", role: .destructive) {
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
                Button("Create Plan") {
                    savePlan()
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
                Text(isEditMode ? "Edit Plan" : "New Run Plan")
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
            } else if isEditMode && isModified {
                // Custom back button shown only when there are unsaved changes
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            // Checkmark save button — only visible in edit mode
            if isEditMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        savePlan()
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
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deletePlan() }
        } message: {
            Text("This will permanently delete \"\(plan?.name ?? "this plan")\". This action cannot be undone.")
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
    }

    private func savePlan() {
        guard let race = selectedRace else { return }
        let totalSeconds = goalHours * 3600 + goalMinutes * 60 + goalSeconds
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                if let existing = plan {
                    // Edit mode — update the existing plan
                    _ = try await APIService.updatePlan(
                        id: existing.planId,
                        name: name,
                        distance: race.label,
                        raceDate: raceDate,
                        goalTimeSeconds: totalSeconds > 0 ? totalSeconds : nil,
                        isPublic: isPublic,
                        planColor: selectedColor
                    )
                } else {
                    // Create mode — post a new plan
                    _ = try await APIService.createPlan(
                        name: name,
                        distance: race.label,
                        raceDate: raceDate,
                        goalTimeSeconds: totalSeconds > 0 ? totalSeconds : nil,
                        isPublic: isPublic,
                        planColor: selectedColor
                    )
                }
                dismiss()
            } catch {
                errorMessage = "Could not save plan. Please check your connection and try again."
            }
        }
    }

    private func deletePlan() {
        guard let existing = plan else { return }
        Task {
            do {
                try await APIService.deletePlan(id: existing.planId)
                dismiss()
            } catch {
                errorMessage = "Could not delete plan. Please check your connection and try again."
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewPlanView()
    }
}
