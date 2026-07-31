//
//  MainTabView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/30/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Main view
            CreatePlan()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Temporary text placeholder for second Tab
            Text("New Workout Page")
                .tabItem {
                    Label("New Workout", systemImage: "plus")
                }
                .tag(1)
            
            // Temporary text placeholder for third tab
            Text("Profile Page")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
}
