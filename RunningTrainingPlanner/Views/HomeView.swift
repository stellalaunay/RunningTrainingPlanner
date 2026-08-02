//
//  HomeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 8/1/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var activities: [Activity]
    @State private var showNewActivity = false
    @State private var showProfile = false

    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private func activitiesFor(date: Date) -> [Activity] {
        activities.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(weekDates, id: \.self) { date in
                        DayRowView(date: date, activities: activitiesFor(date: date))
                    }
                }
                .padding()
            }
            .navigationTitle("This Week")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showNewActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
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
            .navigationDestination(isPresented: $showProfile) {
                Text("Profile Page")
            }
        }
    }
}

struct DayRowView: View {
    let date: Date
    let activities: [Activity]

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.headline)
                    .fontWeight(isToday ? .bold : .regular)
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
                            .foregroundStyle(Color.accentColor)
                        Text(activity.type.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text(activity.time, format: .dateTime.hour().minute())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isToday ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
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
    let container = try! ModelContainer(for: Activity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let calendar = Calendar.current
    let nine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    let six = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
    container.mainContext.insert(Activity(date: Date(), time: nine, type: .run))
    container.mainContext.insert(Activity(date: Date(), time: noon, type: .strengthTraining))
    container.mainContext.insert(Activity(date: Date(), time: six, type: .rockClimb))
    return HomeView()
        .modelContainer(container)
}
