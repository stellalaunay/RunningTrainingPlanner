//
//  MainTabView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/30/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            // Main view
            Text("Home Page")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            SelectActivityDateView()
                .tabItem {
                    Label("New Activity", systemImage: "plus")
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
