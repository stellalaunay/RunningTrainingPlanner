//
//  RunningTrainingPlannerApp.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/28/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

// Wraps Firebase's auth state listener and exposes a simple isLoggedIn flag to SwiftUI
@Observable
final class AuthManager {
    var isLoggedIn = false
    private var handle: AuthStateDidChangeListenerHandle?

    func startListening() {
        isLoggedIn = Auth.auth().currentUser != nil
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isLoggedIn = user != nil
        }
    }
}

@main
struct RunningTrainingPlannerApp: App {
    @State private var authManager = AuthManager()
    // Tracks the active tab; tab 2 is intercepted to show the add sheet instead
    @State private var selectedTab = 0
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
                    // Custom binding intercepts tab 2 before it's set, so the tab never visually selects
                    TabView(selection: Binding(
                        get: { selectedTab },
                        set: { newTab in
                            withTransaction(Transaction(animation: nil)) {
                                if newTab == 2 {
                                    showAddSheet = true
                                } else {
                                    selectedTab = newTab
                                }
                            }
                        }
                    )) {
                        HomeView(refreshTrigger: homeRefreshTrigger)
                            .tabItem { Label("Home", systemImage: "house") }
                            .tag(0)
                        ExploreView()
                            .tabItem { Label("Explore", systemImage: "binoculars") }
                            .tag(1)
                        // This tab's content is never shown — tapping it triggers the add sheet
                        Color.clear
                            .tabItem { Label("New Activity", systemImage: "plus.circle.fill") }
                            .tag(2)
                        ActivitiesView()
                            .tabItem { Label("Activities", systemImage: "list.bullet") }
                            .tag(3)
                        ProfileView()
                            .tabItem { Label("Profile", systemImage: "person") }
                            .tag(4)
                    }
                    .animation(nil, value: selectedTab)
                    .sheet(isPresented: $showAddSheet) {
                        NavigationStack {
                            CreateActivityView()
                        }
                        // Suppress any internal animation when the sheet content appears
                        .transaction { $0.animation = nil }
                    }
                    .onChange(of: showAddSheet) { _, isShowing in
                        // When the sheet closes, tell HomeView to reload its week
                        if !isShowing { homeRefreshTrigger += 1 }
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
