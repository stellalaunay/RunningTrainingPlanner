//
//  ProfileView.swift
//  RunningTrainingPlanner
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    // AuthManager holds the already-fetched user so we don't re-fetch on every tab switch
    let authManager: AuthManager

    var body: some View {
        // NavigationStack is required for toolbar items and pushed screens to work
        NavigationStack {
            Group {
                if let user = authManager.currentUser {
                    ProfileFormView(user: user, authManager: authManager)
                } else if authManager.profileLoadFailed {
                    // Shown if the fetch errors — e.g. backend is down or user record doesn't exist yet
                    ContentUnavailableView("Profile unavailable", systemImage: "person.circle",
                        description: Text("Could not load your profile. Check your connection and try again."))
                } else {
                    ProgressView()
                }
            }
        }
    }
}

// The profile editing form — all fields are local copies until the user taps Save
struct ProfileFormView: View {
    // Tracks what's actually saved on the backend — updated after each successful save
    // so isModified resets correctly and the form reflects persisted values
    @State private var savedUser: User
    let authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    // Local copies of all user fields — not written to the model until Save is tapped
    @State private var firstName: String
    @State private var lastName: String
    @State private var defaultDistanceUnit: DistanceUnit
    @State private var profilePhotoData: Data?       // newly picked photo, not yet saved
    @State private var savedPhotoUrl: String?         // URL of the photo currently saved on the backend
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
    @State private var showSavedBanner = false
    @State private var showSettings = false
    @State private var errorMessage: String? = nil

    // Initialize all local state from the model so the form shows current saved values
    init(user: User, authManager: AuthManager) {
        _savedUser = State(initialValue: user)
        self.authManager = authManager
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _defaultDistanceUnit = State(initialValue: user.defaultDistanceUnit ?? .miles)
        _profilePhotoData = State(initialValue: nil)
        _savedPhotoUrl = State(initialValue: user.profilePhotoUrl)
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

    // True when any local field differs from the last successfully saved values
    private var isModified: Bool {
        firstName != savedUser.firstName ||
        lastName != savedUser.lastName ||
        defaultDistanceUnit != (savedUser.defaultDistanceUnit ?? .miles) ||
        currentEasyPace != savedUser.easyPace ||
        currentLongRunPace != savedUser.longRunPace ||
        currentSpeedPace != savedUser.speedPace ||
        profilePhotoData != nil
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
                                // Newly picked photo — shown before the user taps Save
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let urlStr = savedPhotoUrl, let url = URL(string: urlStr) {
                                // Previously saved photo loaded from Firebase Storage
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                // Placeholder shown when no photo has been saved
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

                // Default pace settings — one collapsible row per pace tag
                Section(header: Text("Default Pace Settings")) {
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

            // Save button — disabled when nothing has changed
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
            .disabled(!isModified)
        }
        // Green banner that slides down from the top and auto-hides after 2 seconds
        .overlay(alignment: .top) {
            if showSavedBanner {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Profile saved!")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSavedBanner)
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
            // Gear icon navigates to account settings (sign out, delete account)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            AccountSettingsView(authManager: authManager)
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard Changes", role: .destructive) { dismiss() }
        } message: {
            Text("You have unsaved changes. Going back will discard them.")
        }
        // Error alert — shown when save fails
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
        Task {
            do {
                // If a new photo was picked, upload it to Firebase Storage and get the URL
                var photoUrl: String? = nil
                if let data = profilePhotoData,
                   let uiImage = UIImage(data: data),
                   let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    photoUrl = try await APIService.uploadProfilePhoto(jpegData)
                }
                let updated = try await APIService.updateProfile(
                    firstName: firstName,
                    lastName: lastName,
                    defaultDistanceUnit: defaultDistanceUnit,
                    easyPace: currentEasyPace,
                    longRunPace: currentLongRunPace,
                    speedPace: currentSpeedPace,
                    profilePhotoUrl: photoUrl
                )
                savedUser = updated
                authManager.currentUser = updated  // keep the cached profile in sync
                savedPhotoUrl = updated.profilePhotoUrl
                profilePhotoData = nil // photo is now persisted — clear local data
                showSavedBanner = true
                try? await Task.sleep(for: .seconds(2))
                showSavedBanner = false
            } catch {
                errorMessage = "Could not save profile. Please check your connection and try again."
            }
        }
    }
}

// Account actions screen — reached via the gear icon on the profile page
struct AccountSettingsView: View {
    let authManager: AuthManager
    @State private var showDeleteAlert = false
    @State private var errorMessage: String? = nil

    var body: some View {
        List {
            // Sign out — no confirmation needed, easy to undo by logging back in
            Section {
                Button("Sign Out") {
                    authManager.signOut()
                }
                .foregroundStyle(Color.appAccent)
            }

            // Delete account — shown separately and in red to signal it's destructive
            Section {
                Button("Delete Account") {
                    showDeleteAlert = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Account Settings")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This will permanently delete your account and all your data. This cannot be undone.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func deleteAccount() {
        Task {
            do {
                try await APIService.deleteUser()
                // Backend has deleted the Firebase account and DB row — clear local session
                authManager.signOut()
            } catch {
                errorMessage = "Could not delete your account. Please check your connection and try again."
            }
        }
    }
}

#Preview {
    ProfileView(authManager: AuthManager())
}
