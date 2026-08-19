//
//  ActivitiesView.swift
//  RunningTrainingPlanner
//

import SwiftUI

struct ActivitiesView: View {
    @State private var activities: [Activity] = []
    @State private var plans: [Plan] = []
    // false = Activities list, true = Plans list
    @State private var showingPlans = false

    var body: some View {
        NavigationStack {
            List {
                if showingPlans {
                    // Plans list
                    ForEach(plans) { plan in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.name)
                                .font(.body)
                            HStack(spacing: 4) {
                                Text(plan.distance, format: .number.precision(.fractionLength(1)))
                                Text("km ·")
                                Text(plan.raceDate, format: .dateTime.month(.abbreviated).day().year())
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    // Activities list
                    ForEach(activities) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: iconFor(activity.type))
                                .foregroundStyle(activity.type.color)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.name)
                                    .font(.body)
                                Text(activity.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    // Fetch activities and plans concurrently
                    async let fetchedActivities = APIService.fetchMyActivities()
                    async let fetchedPlans = APIService.fetchMyPlans()
                    activities = try await fetchedActivities
                    plans = try await fetchedPlans
                } catch {
                    // Lists stay empty if fetch fails
                }
            }
            .toolbar {
                // Segmented picker in the nav bar center — switches between the two lists
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $showingPlans) {
                        Text("Activities").tag(false)
                        Text("Plans").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
        }
    }

    // Maps each activity type to its SF Symbol icon name
    private func iconFor(_ type: ActivityType) -> String {
        switch type {
        case .run: return "figure.run"
        case .strengthTraining: return "dumbbell"
        case .walk: return "figure.walk"
        case .rockClimb: return "figure.climbing"
        case .other: return "star"
        }
    }
}

#Preview {
    ActivitiesView()
}
