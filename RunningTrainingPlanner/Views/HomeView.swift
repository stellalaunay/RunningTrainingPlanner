//
//  HomeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 8/1/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // @Query fetches all activities from SwiftData and keeps the list in sync with any changes
    @Query private var activities: [Activity]
    @State private var showNewActivity = false
    @State private var showNewPlan = false
    @State private var showProfile = false
    @State private var showAddMenu = false
    // 0 = this week, -1 = last week, +1 = next week, etc.
    @State private var weekOffset: Int = 0

    // Generates the 7 dates for the displayed week, starting on Monday
    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 2 = Monday
        // Shift the base date by weekOffset weeks to get the target week
        let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: baseDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // "This Week" for the current week; "Week of Jul 27 - Aug 2" for all other weeks
    private var weekTitle: String {
        guard weekOffset != 0, let first = weekDates.first, let last = weekDates.last else {
            return "This Week"
        }
        let firstStr = first.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
        let lastStr = last.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
        return "\(firstStr) - \(lastStr)"
    }

    // Returns activities for a given day, sorted by time (no-time activities go last)
    private func activitiesFor(date: Date) -> [Activity] {
        activities
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { ($0.time ?? .distantFuture) < ($1.time ?? .distantFuture) }
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
                        Text(weekTitle)
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

                    ForEach(weekDates, id: \.self) { date in
                        // Tapping a card navigates to DayView
                        NavigationLink(destination: DayView(date: date, activities: activitiesFor(date: date))) {
                            DayRowView(date: date, activities: activitiesFor(date: date))
                        }
                        .buttonStyle(.plain) // prevents the NavigationLink from applying its own blue tint
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            // Custom dropdown menu — shown when the + button is tapped
            .overlay(alignment: .topLeading) {
                if showAddMenu {
                    ZStack(alignment: .topLeading) {
                        // Invisible full-screen tap area — tapping outside the menu closes it
                        Color.clear
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showAddMenu = false
                                }
                            }
                        // Menu container
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { showAddMenu = false }
                                showNewActivity = true
                            } label: {
                                Text("New Activity")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            Divider()
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { showAddMenu = false }
                                showNewPlan = true
                            } label: {
                                Text("New Plan")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                        }
                        .fixedSize() // shrinks the container to fit its content instead of expanding to fill the screen
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity)) // slides down + fades in when appearing
                    }
                }
            }
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
            .toolbar {
                // + button on the left — toggles the dropdown menu
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showAddMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                // Profile button on the right (placeholder)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person")
                    }
                }
            }
            .navigationDestination(isPresented: $showNewActivity) {
                CreateActivityView()
            }
            .navigationDestination(isPresented: $showNewPlan) {
                NewPlanView()
            }
            .navigationDestination(isPresented: $showProfile) {
                ProfileView()
            }
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
                ForEach(activities) { activity in
                    HStack(spacing: 8) {
                        Image(systemName: iconFor(activity.type))
                            .foregroundStyle(activity.type.color)
                        Text(activity.name)
                            .font(.subheadline)
                        Spacer()
                        if let time = activity.time {
                            Text(time, format: .dateTime.hour().minute())
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
    let container = try! ModelContainer(for: Activity.self, Plan.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return HomeView()
        .modelContainer(container)
}
