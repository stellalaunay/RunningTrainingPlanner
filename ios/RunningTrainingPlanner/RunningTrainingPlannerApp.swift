//
//  RunningTrainingPlannerApp.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/28/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

// Wraps Firebase's auth state listener and exposes a simple isLoggedIn flag to SwiftUI.
// Also fetches and holds the current user's profile so ProfileView doesn't re-fetch on every tab switch.
@Observable
final class AuthManager {
    var isLoggedIn = false
    var currentUser: User? = nil
    var profileLoadFailed = false
    private var handle: AuthStateDidChangeListenerHandle?
    private let userCacheKey = "cachedUser"

    func startListening() {
        // Load the cached profile immediately so the tab bar shows data before the API responds
        currentUser = loadFromCache()
        isLoggedIn = Auth.auth().currentUser != nil
        if isLoggedIn {
            fetchProfile()
        }
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
            if user != nil {
                self?.fetchProfile()
            } else {
                self?.currentUser = nil
                self?.profileLoadFailed = false
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        profileLoadFailed = false
        UserDefaults.standard.removeObject(forKey: userCacheKey)
    }

    func fetchProfile() {
        Task { @MainActor [weak self] in
            do {
                let user = try await APIService.fetchMyProfile()
                self?.updateCurrentUser(user)
            } catch {
                // Only show the error state if we have no cached data to fall back on
                if self?.currentUser == nil {
                    self?.profileLoadFailed = true
                }
            }
        }
    }

    // Sets currentUser and persists it to UserDefaults so it survives app restarts
    func updateCurrentUser(_ user: User) {
        currentUser = user
        saveToCache(user)
    }

    private func saveToCache(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userCacheKey)
        }
    }

    private func loadFromCache() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userCacheKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
}

@main
struct RunningTrainingPlannerApp: App {
    @State private var authManager = AuthManager()
    @State private var selectedTab = 0
    // Remembers which tab was active when + was tapped, so we can return there after the sheet closes
    @State private var previousTab = 0
    @State private var showAddSheet = false
    // Incremented when the add-activity sheet dismisses so HomeView reloads
    @State private var homeRefreshTrigger = 0

    init() {
        // Skip Firebase setup when Xcode is rendering a SwiftUI preview — it crashes the preview host
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoggedIn {
                    TabView(selection: $selectedTab) {
                        HomeView(refreshTrigger: homeRefreshTrigger)
                            .tabItem { Label("Home", systemImage: "house") }
                            .tag(0)
                        PlansView()
                            .tabItem { Label("Plans", systemImage: "list.bullet.clipboard") }
                            .tag(1)
                        // Content never shown — tapping opens the add sheet, then tab returns to previousTab
                        Color.clear
                            .tabItem { Label("New Activity", systemImage: "plus.circle.fill") }
                            .tag(2)
                        ActivitiesView()
                            .tabItem { Label("Activities", systemImage: "list.bullet") }
                            .tag(3)
                        ProfileView(authManager: authManager)
                            .tabItem { Label("Profile", systemImage: "person") }
                            .tag(4)
                    }
                    .onChange(of: selectedTab) { _, newTab in
                        if newTab == 2 {
                            // Don't update previousTab — keep it pointing at the tab the user was on
                            showAddSheet = true
                        } else {
                            previousTab = newTab
                        }
                    }
                    .sheet(isPresented: $showAddSheet) {
                        NavigationStack {
                            CreateActivityView(isModal: true)
                        }
                    }
                    .onChange(of: showAddSheet) { _, isShowing in
                        if !isShowing {
                            // Return to the tab that was active before + was tapped, and reload HomeView
                            selectedTab = previousTab
                            homeRefreshTrigger += 1
                        }
                    }
                } else {
                    LoginView(authManager: authManager)
                }
            }
            .autocorrectionDisabled()
            // Start listening for sign-in/sign-out events when the app first appears
            .task { authManager.startListening() }
        }
    }
}
