//
//  NewPlanView.swift
//  RunningTrainingPlanner
//

import SwiftUI

struct NewPlanView: View {
    var body: some View {
        Text("New Plan")
            .foregroundStyle(.secondary)
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NewPlanView()
    }
}
