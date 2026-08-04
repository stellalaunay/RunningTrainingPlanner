//
//  WeekNavigator.swift
//  RunningTrainingPlanner
//

import Foundation

// Pure calendar logic for week navigation — extracted from HomeView so it can be unit tested
struct WeekNavigator {
    let offset: Int
    // Injected base date so tests can pass a known date; defaults to now in production
    private let baseDate: Date

    init(offset: Int, baseDate: Date = Date()) {
        self.offset = offset
        self.baseDate = baseDate
    }

    // The 7 days of the target week, starting on Monday
    var dates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 2 = Monday
        let target = calendar.date(byAdding: .weekOfYear, value: offset, to: baseDate) ?? baseDate
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: target) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    // "This Week" for offset 0; "MM/DD - MM/DD" for any other week
    var title: String {
        guard offset != 0, let first = dates.first, let last = dates.last else {
            return "This Week"
        }
        let firstStr = first.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
        let lastStr = last.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
        return "\(firstStr) - \(lastStr)"
    }
}
