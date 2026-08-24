//
//  ActivitiesView.swift
//  RunningTrainingPlanner
//

import SwiftUI

// Controls which half of the timeline is shown
private enum ActivitySegment: String, CaseIterable {
    case upcoming = "Upcoming"
    case past = "Past"
}

struct ActivitiesView: View {
    @State private var activities: [Activity] = []
    @State private var loadFailed = false
    @State private var selectedSegment: ActivitySegment = .upcoming
    @State private var showNewActivity = false
    @State private var showEditActivity = false
    @State private var activityToEdit: Activity? = nil

    private let calendar = Calendar.current

    // Stable string key for each date section (e.g. "2026-08-20")
    private static let sectionIDFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // Activities grouped by calendar day, filtered and sorted by the selected segment.
    // Upcoming: today and future, oldest first (today at top).
    // Past: before today, newest first (most recent at top).
    private var groupedByDay: [(id: String, date: Date, activities: [Activity])] {
        let today = calendar.startOfDay(for: .now)
        let grouped = Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.date)
        }
        let filtered = grouped.filter { date, _ in
            selectedSegment == .upcoming ? date >= today : date < today
        }
        return filtered
            .map { date, acts in
                let id = Self.sectionIDFormatter.string(from: date)
                return (id: id, date: date, activities: acts.sorted { $0.date < $1.date })
            }
            .sorted { lhs, rhs in
                // Upcoming: chronological (today at top); Past: reverse (most recent at top)
                selectedSegment == .upcoming ? lhs.date < rhs.date : lhs.date > rhs.date
            }
    }

    // Section header text — friendly labels for nearby dates
    private func headerTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }

    private func loadActivities() async {
        loadFailed = false
        do {
            activities = try await APIService.fetchMyActivities()
        } catch {
            loadFailed = true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker — stays fixed below the nav bar as the list scrolls
                Picker("", selection: $selectedSegment) {
                    ForEach(ActivitySegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                ScrollView {
                    // pinnedViews keeps date headers visible as the user scrolls
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        if loadFailed {
                            Text("Couldn't load activities. Check your connection.")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else if groupedByDay.isEmpty {
                            Text(selectedSegment == .upcoming ? "No upcoming activities." : "No past activities.")
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                        ForEach(groupedByDay, id: \.id) { group in
                            Section {
                                ForEach(group.activities) { activity in
                                    ActivityDetailCard(activity: activity, onEdit: {
                                        activityToEdit = activity
                                        showEditActivity = true
                                    })
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                // Sticky date header with a background so it sits above the cards
                                Text(headerTitle(for: group.date))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGroupedBackground))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            // Re-fetches on every tab switch so plan color changes are reflected immediately
            .onAppear { Task { await loadActivities() } }
            // Re-fetch after returning from create or edit so new/updated activities appear immediately
            .onChange(of: showNewActivity) { _, isShowing in
                if !isShowing { Task { await loadActivities() } }
            }
            .onChange(of: showEditActivity) { _, isShowing in
                if !isShowing { Task { await loadActivities() } }
            }
            .navigationDestination(isPresented: $showNewActivity) {
                CreateActivityView()
            }
            .navigationDestination(isPresented: $showEditActivity) {
                if let activity = activityToEdit {
                    CreateActivityView(activity: activity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Activities")
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
        }
    }
}

#Preview {
    ActivitiesView()
}
