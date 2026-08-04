//
//  DayView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 8/1/26.
//

import SwiftUI

struct DayView: View {
    // let means these are passed in from HomeView, not stored locally
    let date: Date
    let activities: [Activity]
    @State private var showNewActivity = false
    @State private var showEditActivity = false
    @State private var activityToEdit: Activity? = nil

    // Formats the date into a readable string e.g. "Monday, August 3"
    private var title: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Activity list — shows a placeholder if no activities are scheduled
                if activities.isEmpty {
                    Text("No activities planned.")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                } else {
                    ForEach(activities) { activity in
                        ActivityDetailCard(activity: activity, onEdit: {
                            activityToEdit = activity
                            showEditActivity = true
                        })
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        // + button in the top right — opens CreateActivityView with this day's date pre-filled
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewActivity = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(isPresented: $showNewActivity) {
            CreateActivityView(initialDate: date)
        }
        .navigationDestination(isPresented: $showEditActivity) {
            if let activity = activityToEdit {
                CreateActivityView(activity: activity)
            }
        }
    }
}

// Card showing the details of a single activity
struct ActivityDetailCard: View {
    let activity: Activity
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconFor(activity.type))
                    .foregroundStyle(activity.type.color)
                Text(activity.name)
                    .font(.headline)
                // Time sits directly after the name; shown only if the user set one
                if let time = activity.time {
                    Text(time, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color(.darkGray))
                        .padding(6)
                        .background(Circle().fill(Color(.systemGray6)))
                }
            }

            // Distance — only shown for runs and walks that have distance set
            if activity.type == .run || activity.type == .walk, let distance = activity.distance, let unit = activity.distanceUnit {
                Text("Distance: \(distance, format: .number.precision(.fractionLength(2))) \(unit.rawValue)")
                    .font(.subheadline)
            }

            // Pace tag, plan tag, and pace — only shown for runs
            if activity.type == .run {
                HStack(spacing: 8) {
                    if let tag = activity.paceTag {
                        Text(tag.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tag.color.opacity(0.85))
                            .clipShape(Capsule())
                    }
                    if let plan = activity.plan {
                        Text(plan.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.appAccent.opacity(0.85))
                            .clipShape(Capsule())
                    }
                    if let pace = activity.pace, let unit = activity.distanceUnit {
                        Text("\(pace / 60):\(String(format: "%02d", pace % 60)) min/\(unit.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Duration — only shown for rock climbing
            if activity.type == .rockClimb, let duration = activity.duration {
                Text("Duration: \(duration) min")
                    .font(.subheadline)
            }

            // Notes — only shown if present and non-empty
            if let notes = activity.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        // Card background uses the activity type's color at low opacity
        .background(activity.type.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

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
