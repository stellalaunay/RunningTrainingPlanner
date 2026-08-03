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

    // Generates the 7 dates for the current week, starting on Monday
    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 2 = Monday
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        // Adds 0–6 days to the start of the week to produce each day
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // Returns activities for a given day, sorted by time (no-time activities go last)
    private func activitiesFor(date: Date) -> [Activity] {
        activities
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { ($0.time ?? .distantFuture) < ($1.time ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            // Weekly schedule — one card per day
            ScrollView {
                VStack(spacing: 12) {
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
            .toolbar {
                // "This Week" title centered in the nav bar
                ToolbarItem(placement: .principal) {
                    Text("This Week")
                        .font(.title)
                        .fontWeight(.bold)
                }
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
                Text("Profile Page")
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
        .background(isToday ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Today's card also gets a visible border
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 1.5)
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
    let container = try! ModelContainer(for: Activity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return HomeView()
        .modelContainer(container)
}
