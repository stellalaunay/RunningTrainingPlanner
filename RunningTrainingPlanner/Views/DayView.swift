//
//  DayView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 8/1/26.
//

import SwiftUI

struct DayView: View {
    let date: Date
    let activities: [Activity]
    @State private var showNewActivity = false

    private var title: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Date header — teal rounded container anchoring the brand theme
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)

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

struct ActivityDetailCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                Spacer()
                if let time = activity.time {
                    Text(time, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if activity.type == .run || activity.type == .walk, let distance = activity.distance, let unit = activity.distanceUnit {
                Text("Distance: \(distance, format: .number.precision(.fractionLength(2))) \(unit.rawValue)")
                    .font(.subheadline)
            }

            if activity.type == .run, let paceMin = activity.paceMinutes, let paceSec = activity.paceSeconds, let unit = activity.distanceUnit {
                Text("Pace: \(paceMin):\(String(format: "%02d", paceSec)) min/\(unit.rawValue)")
                    .font(.subheadline)
            }

            if activity.type == .rockClimb, let duration = activity.duration {
                Text("Duration: \(duration) min")
                    .font(.subheadline)
            }

            if let notes = activity.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(activity.type.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
