//
//  RunningTrainingPlannerApp.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/28/26.
//

import SwiftUI
import SwiftData

@main
struct RunningTrainingPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Activity.self, Plan.self])
    }
}
