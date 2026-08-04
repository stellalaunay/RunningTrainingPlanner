//
//  ProfileView.swift
//  RunningTrainingPlanner
//

import SwiftUI
import SwiftData
import PhotosUI

// TODO: Once login/onboarding is built, user creation moves there. This view should only ever receive an existing user.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    var body: some View {
        if let user = users.first {
            ProfileFormView(user: user)
        } else {
            // Temporary: creates a blank user so the profile page is accessible before login is implemented
            ProgressView()
                .onAppear {
                    modelContext.insert(User(firstName: "", lastName: ""))
                }
        }
    }
}

// The profile editing form — all fields are local copies until the user taps Save
struct ProfileFormView: View {
    let user: User
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Local copies of all user fields — not written to the model until Save is tapped
    @State private var firstName: String
    @State private var lastName: String
    @State private var defaultDistanceUnit: DistanceUnit
    @State private var profilePhotoData: Data?
    @State private var selectedPhoto: PhotosPickerItem? = nil

    // Pace picker visibility
    @State private var showEasyPacePicker = false
    @State private var showLongRunPacePicker = false
    @State private var showSpeedPacePicker = false

    // Local minute/second state for each pace wheel
    @State private var easyPaceMin: Int
    @State private var easyPaceSec: Int
    @State private var longRunPaceMin: Int
    @State private var longRunPaceSec: Int
    @State private var speedPaceMin: Int
    @State private var speedPaceSec: Int

    @State private var showDiscardAlert = false

    // Initialize all local state from the model so the form shows current saved values
    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _defaultDistanceUnit = State(initialValue: user.defaultDistanceUnit)
        _profilePhotoData = State(initialValue: user.profilePhotoData)
        _easyPaceMin = State(initialValue: user.easyPace.map { $0 / 60 } ?? 0)
        _easyPaceSec = State(initialValue: user.easyPace.map { $0 % 60 } ?? 0)
        _longRunPaceMin = State(initialValue: user.longRunPace.map { $0 / 60 } ?? 0)
        _longRunPaceSec = State(initialValue: user.longRunPace.map { $0 % 60 } ?? 0)
        _speedPaceMin = State(initialValue: user.speedPace.map { $0 / 60 } ?? 0)
        _speedPaceSec = State(initialValue: user.speedPace.map { $0 % 60 } ?? 0)
    }

    // Pace totals derived from wheel state; nil if both wheels are at 0 (treated as "not set")
    private var currentEasyPace: Int? { (easyPaceMin > 0 || easyPaceSec > 0) ? easyPaceMin * 60 + easyPaceSec : nil }
    private var currentLongRunPace: Int? { (longRunPaceMin > 0 || longRunPaceSec > 0) ? longRunPaceMin * 60 + longRunPaceSec : nil }
    private var currentSpeedPace: Int? { (speedPaceMin > 0 || speedPaceSec > 0) ? speedPaceMin * 60 + speedPaceSec : nil }

    // True when any local field differs from the saved model — enables the Save button and back-button guard
    private var isModified: Bool {
        firstName != user.firstName ||
        lastName != user.lastName ||
        defaultDistanceUnit != user.defaultDistanceUnit ||
        profilePhotoData != user.profilePhotoData ||
        currentEasyPace != user.easyPace ||
        currentLongRunPace != user.longRunPace ||
        currentSpeedPace != user.speedPace
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                // Profile photo — centered, tappable to open the system photo picker
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let data = profilePhotoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                // Placeholder shown when no photo has been set
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear) // removes the white card background from the photo row

                // Name section
                Section {
                    TextField("First name", text: $firstName)
                    TextField("Last name", text: $lastName)
                }

                // Settings section
                Section(header: Text("Default unit")) {
                    Picker("Default unit", selection: $defaultDistanceUnit) {
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented) // two-option segmented control instead of a dropdown
                }

                // Pace settings — one collapsible row per pace tag
                Section(header: Text("Pace settings")) {
                    // Easy pace
                    DisclosureGroup(isExpanded: $showEasyPacePicker) {
                        HStack {
                            Spacer()
                            Picker("Minutes", selection: $easyPaceMin) {
                                ForEach(0..<60) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            Text(":")
                            Picker("Seconds", selection: $easyPaceSec) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            Text("min/\(defaultDistanceUnit.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        HStack {
                            Text("Easy")
                            Spacer()
                            if let pace = currentEasyPace {
                                Text("\(pace / 60):\(String(format: "%02d", pace % 60)) min/\(defaultDistanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not set").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Long Run pace
                    DisclosureGroup(isExpanded: $showLongRunPacePicker) {
                        HStack {
                            Spacer()
                            Picker("Minutes", selection: $longRunPaceMin) {
                                ForEach(0..<60) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            Text(":")
                            Picker("Seconds", selection: $longRunPaceSec) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            Text("min/\(defaultDistanceUnit.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        HStack {
                            Text("Long Run")
                            Spacer()
                            if let pace = currentLongRunPace {
                                Text("\(pace / 60):\(String(format: "%02d", pace % 60)) min/\(defaultDistanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not set").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Speed pace
                    DisclosureGroup(isExpanded: $showSpeedPacePicker) {
                        HStack {
                            Spacer()
                            Picker("Minutes", selection: $speedPaceMin) {
                                ForEach(0..<60) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            Text(":")
                            Picker("Seconds", selection: $speedPaceSec) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            Text("min/\(defaultDistanceUnit.rawValue)")
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        HStack {
                            Text("Speed")
                            Spacer()
                            if let pace = currentSpeedPace {
                                Text("\(pace / 60):\(String(format: "%02d", pace % 60)) min/\(defaultDistanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not set").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Button("Save Profile") {
                saveProfile()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isModified ? Color.appAccent : Color(.systemGray4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom)
            .disabled(!isModified) // prevents tapping when nothing has changed
        }
        .navigationTitle("Profile")
        // Hides the system back button (and disables swipe-back) when there are unsaved changes
        .navigationBarBackButtonHidden(isModified)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
            }
            // Custom back button shown only when there are unsaved changes — tapping it triggers the discard alert
            if isModified {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard Changes", role: .destructive) { dismiss() }
        } message: {
            Text("You have unsaved changes. Going back will discard them.")
        }
        .onChange(of: selectedPhoto) { _, item in
            // Load the selected photo into local state — not written to the model until Save is tapped
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    profilePhotoData = data
                }
            }
        }
    }

    private func saveProfile() {
        user.firstName = firstName
        user.lastName = lastName
        user.defaultDistanceUnit = defaultDistanceUnit
        user.profilePhotoData = profilePhotoData
        user.easyPace = currentEasyPace
        user.longRunPace = currentLongRunPace
        user.speedPace = currentSpeedPace
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: User.self, Plan.self, Activity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return NavigationStack {
        ProfileView()
    }
    .modelContainer(container)
}
