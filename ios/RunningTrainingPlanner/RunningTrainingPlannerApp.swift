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

    init() {
        // Skip Firebase setup when Xcode is rendering a SwiftUI preview — it crashes the preview host
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoggedIn {
                    HomeView()
                } else {
                    LoginView(authManager: authManager)
                }
            }
            // Start listening for sign-in/sign-out events when the app first appears
            .task { authManager.startListening() }
        }
    }
}
