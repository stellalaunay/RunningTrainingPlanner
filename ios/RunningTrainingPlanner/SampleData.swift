//
//  SampleData.swift
//  RunningTrainingPlanner
//

import Foundation

// Shared sample data used across views during UI development — replaced by API data once wired
enum SampleData {

    // Returns a Date for a given weekday number (2=Mon … 7=Sat, 1=Sun) in the current week
    static func weekday(_ weekday: Int) -> Date {
        let cal = Calendar.current
        let today = Date.now
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        var target = DateComponents()
        target.yearForWeekOfYear = comps.yearForWeekOfYear
        target.weekOfYear = comps.weekOfYear
        target.weekday = weekday
        return cal.date(from: target) ?? today
    }

    static let activities: [Activity] = [
        Activity(activityId: UUID(), planId: nil, name: "Easy Run", date: weekday(2), time: "7:00 AM",
                 type: .run, notes: "Zone 2, conversational pace", distance: 8.0, distanceUnit: .km,
                 pace: 330, paceTag: .easy, duration: nil, createdAt: .now, userId: UUID()),
        Activity(activityId: UUID(), planId: nil, name: "Strength Training", date: weekday(3), time: "6:30 PM",
                 type: .strengthTraining, notes: nil, distance: nil, distanceUnit: nil,
                 pace: nil, paceTag: nil, duration: nil, createdAt: .now, userId: UUID()),
        Activity(activityId: UUID(), planId: nil, name: "Tempo Run", date: weekday(4), time: "7:00 AM",
                 type: .run, notes: nil, distance: 10.0, distanceUnit: .km,
                 pace: 285, paceTag: .speed, duration: nil, createdAt: .now, userId: UUID()),
        Activity(activityId: UUID(), planId: nil, name: "Rock Climb", date: weekday(5), time: "5:30 PM",
                 type: .rockClimb, notes: nil, distance: nil, distanceUnit: nil,
                 pace: nil, paceTag: nil, duration: 90, createdAt: .now, userId: UUID()),
        Activity(activityId: UUID(), planId: nil, name: "Long Run", date: weekday(7), time: "8:00 AM",
                 type: .run, notes: "Easy effort, bring water", distance: 18.0, distanceUnit: .km,
                 pace: 360, paceTag: .longRun, duration: nil, createdAt: .now, userId: UUID()),
    ]

    static let plans: [Plan] = [
        Plan(planId: UUID(), userId: UUID(), name: "Boston Marathon", distance: 42.2,
             raceDate: Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now,
             goalTimeSeconds: 13500, createdAt: .now, isPublic: false),
        Plan(planId: UUID(), userId: UUID(), name: "10K Race", distance: 10.0,
             raceDate: Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now,
             goalTimeSeconds: nil, createdAt: .now, isPublic: false),
    ]
}
