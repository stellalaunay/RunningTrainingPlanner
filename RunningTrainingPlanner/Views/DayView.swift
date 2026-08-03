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

    // Formats the date into a readable string e.g. "Monday, August 3"
    private var title: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Date header — teal rounded container anchoring the brand theme
                // .frame(maxWidth: .infinity, alignment: .leading) makes it span the full width with left-aligned text
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Activity list — shows a placeholder if no activities are scheduled
                if activities.isEmpty {
                    Text("No activities planned.")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                } else {
                    ForEach(activities) { activity in
                        ActivityDetailCard(activity: activity)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // + button in the top right — opens CreateActivityView with this day's date pre-filled
        .toolbar {
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
    }
}

// Card showing the details of a single activity
struct ActivityDetailCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                Spacer()
                // Time is optional — only shown if the user set one
                if let time = activity.time {
                    Text(time, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Distance — only shown for runs and walks that have distance set
            if activity.type == .run || activity.type == .walk, let distance = activity.distance, let unit = activity.distanceUnit {
                Text("Distance: \(distance, format: .number.precision(.fractionLength(2))) \(unit.rawValue)")
                    .font(.subheadline)
            }

            // Pace — only shown for runs; pace is stored as total seconds, converted here to min:sec
            if activity.type == .run, let pace = activity.pace, let unit = activity.distanceUnit {
                Text("Pace: \(pace / 60):\(String(format: "%02d", pace % 60)) min/\(unit.rawValue)")
                    .font(.subheadline)
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
}
