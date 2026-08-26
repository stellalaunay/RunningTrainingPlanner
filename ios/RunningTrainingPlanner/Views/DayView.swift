//
//  DayView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 8/1/26.
//

import SwiftUI

struct DayView: View {
    let date: Date
    // localActivities is the live list; seeded from HomeView's snapshot then refreshed on each appear
    @State private var localActivities: [Activity]
    @State private var loadFailed = false
    @State private var showNewActivity = false
    @State private var showEditActivity = false
    @State private var activityToEdit: Activity? = nil
    // Set to the new date when an activity is moved to a different day; drives the toast message
    @State private var movedToDate: Date? = nil

    init(date: Date, activities: [Activity]) {
        self.date = date
        self._localActivities = State(initialValue: activities)
    }

    private func loadActivities() async {
        loadFailed = false
        do {
            let all = try await APIService.fetchMyActivities()
            localActivities = all.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        } catch {
            // Keep showing whatever was already loaded from HomeView's snapshot
            if localActivities.isEmpty { loadFailed = true }
        }
    }

    // Formats the date into a readable string e.g. "Monday, August 3"
    private var title: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Activity list — shows a placeholder if no activities are scheduled
                if loadFailed {
                    Text("Couldn't load activities. Check your connection.")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                } else if localActivities.isEmpty {
                    Text("No activities planned.")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                } else {
                    ForEach(localActivities.sorted { lhs, rhs in
                        switch (lhs.time, rhs.time) {
                        case let (l?, r?): return l < r
                        case (nil, _?):    return false  // no time goes last
                        case (_?, nil):    return true
                        case (nil, nil):   return false
                        }
                    }) { activity in
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
        .task { await loadActivities() }
        .onChange(of: showNewActivity) { _, isShowing in
            if !isShowing { Task { await loadActivities() } }
        }
        .onChange(of: showEditActivity) { _, isShowing in
            if !isShowing { Task { await loadActivities() } }
        }
        .navigationDestination(isPresented: $showNewActivity) {
            CreateActivityView(initialDate: date, isModal: true)
        }
        .navigationDestination(isPresented: $showEditActivity) {
            if let activity = activityToEdit {
                CreateActivityView(activity: activity, onDateChanged: { movedToDate = $0 })
            }
        }
        // Toast shown when an activity's date is changed during editing — fades out automatically
        .overlay(alignment: .bottom) {
            if let movedDate = movedToDate {
                Text("Activity moved to \(movedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.8))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: movedToDate)
        // Auto-dismiss the toast after 2.5 seconds
        .task(id: movedToDate) {
            guard movedToDate != nil else { return }
            try? await Task.sleep(for: .seconds(2.5))
            movedToDate = nil
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
                // Pace tag sits right of the name — run only
                if activity.type == .run, let tag = activity.paceTag {
                    Text(tag.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tag.color.opacity(0.85))
                        .clipShape(Capsule())
                }
                // Time sits after the name/tag; shown only if the user set one
                if let time = activity.formattedTime {
                    Text(time)
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

            // Distance — only shown for runs and walks; pace value follows on the same line for runs
            if activity.type == .run || activity.type == .walk, let distance = activity.distance, let unit = activity.distanceUnit {
                HStack {
                    Text("Distance: \(distance, format: .number.precision(.fractionLength(2))) \(unit.rawValue)")
                        .font(.subheadline)
                    if activity.type == .run, let pace = activity.pace {
                        Spacer()
                        Text("\(pace / 60):\(String(format: "%02d", pace % 60)) min/\(unit.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Plan tag — shown for any activity type when linked to a plan
            if let planName = activity.planName {
                Text(planName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: activity.planColor ?? "#808080").opacity(0.65))
                    .clipShape(Capsule())
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

#Preview {
    let sampleActivity = Activity(
        activityId: UUID(),
        planId: nil,
        name: "Morning Run",
        date: .now,
        time: "7:30 AM",
        type: .run,
        notes: "Easy effort, felt good.",
        distance: 8.0,
        distanceUnit: .km,
        pace: 330,
        paceTag: .easy,
        duration: nil,
        createdAt: .now,
        userId: UUID(),
        isPublic: false,
        planName: nil,
        planColor: nil
    )
    NavigationStack {
        DayView(date: .now, activities: [sampleActivity])
    }
}
