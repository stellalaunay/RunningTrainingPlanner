//
//  HomeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 8/1/26.
//

import SwiftUI

struct HomeView: View {
    // Incremented by the app when the add-activity sheet is dismissed, triggering a reload
    var refreshTrigger: Int = 0
    @State private var activities: [Activity] = []
    @State private var isLoading = false
    @State private var loadFailed = false
    // 0 = this week, -1 = last week, +1 = next week, etc.
    @State private var weekOffset: Int = 0

    private var week: WeekNavigator { WeekNavigator(offset: weekOffset) }

    private func loadWeekActivities() async {
        guard let monday = week.dates.first, let sunday = week.dates.last else { return }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            activities = try await APIService.fetchWeekActivities(monday: monday, sunday: sunday)
        } catch {
            loadFailed = true
        }
    }

    // Returns activities for a given day
    private func activitiesFor(date: Date) -> [Activity] {
        activities.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            // Weekly schedule — title header + one card per day
            ScrollView {
                VStack(spacing: 12) {
                    // Title row — lives in the scroll content so it sits below the nav buttons
                    HStack(spacing: 12) {
                        Button { weekOffset -= 1 } label: {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                                .padding(6)
                                .background(Circle().fill(Color.appAccent.opacity(0.25)))
                        }
                        // Fixed width so the arrows don't shift between "This Week" and date ranges
                        Text(week.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .frame(width: 200, alignment: .center)
                        Button { weekOffset += 1 } label: {
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .padding(6)
                                .background(Circle().fill(Color.appAccent.opacity(0.25)))
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.bottom, 4)

                    ForEach(week.dates, id: \.self) { date in
                        // Tapping a card navigates to DayView
                        NavigationLink(destination: DayView(date: date, activities: activitiesFor(date: date))) {
                            DayRowView(date: date, activities: activitiesFor(date: date))
                        }
                        .buttonStyle(.plain) // prevents the NavigationLink from applying its own blue tint
                    }

                    // Shown below the day cards when the fetch fails
                    if loadFailed {
                        Text("Couldn't load activities. Check your connection.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            // Swipe left to advance to the next week, swipe right to go back
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if value.translation.width < 0 {
                            weekOffset += 1
                        } else {
                            weekOffset -= 1
                        }
                    }
            )
            // Reloads on appear (including returning from DayView), week navigation, and tab sheet dismissal
            .onAppear { Task { await loadWeekActivities() } }
            .onChange(of: weekOffset) { _, _ in Task { await loadWeekActivities() } }
            .onChange(of: refreshTrigger) { _, _ in Task { await loadWeekActivities() } }
        }
    }
}

// Row card for a single day in the weekly schedule
struct DayRowView: View {
    let date: Date
    let activities: [Activity]

    // True if this card represents today
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.headline)
                    .fontWeight(isToday ? .bold : .regular) // today's name is bold
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if activities.isEmpty {
                Text("Rest day")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 2)
            } else {
                ForEach(activities.sorted { lhs, rhs in
                        switch (lhs.time, rhs.time) {
                        case let (l?, r?): return l < r
                        case (nil, _?):    return false
                        case (_?, nil):    return true
                        case (nil, nil):   return false
                        }
                    }) { activity in
                    HStack(spacing: 8) {
                        Image(systemName: iconFor(activity.type))
                            .foregroundStyle(activity.type.color)
                        Text(activity.name)
                            .font(.subheadline)
                        // Distance — only shown for runs and walks when a value is stored
                        if (activity.type == .run || activity.type == .walk),
                           let distance = activity.distance,
                           let unit = activity.distanceUnit {
                            Text("\(distance, format: .number.precision(.fractionLength(0...2))) \(unit.rawValue)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let time = activity.formattedTime {
                            Text(time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        // Today's card gets a subtle accent tint; other days use the standard secondary background
        .background(isToday ? Color.appTodayCard : Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Today's card also gets a visible border
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.appAccent : Color.clear, lineWidth: 1.5)
        )
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
    HomeView()
}
