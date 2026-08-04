//
//  Plan.swift
//  RunningTrainingPlanner
//

import SwiftUI
import SwiftData

@Model
final class Plan {
    var planId: UUID = UUID()
    var userId: UUID?               // FK for backend — mirrors the user relationship below
    var name: String
    var distance: Double
    var raceDate: Date
    var goalTimeSeconds: Int?
    var user: User?                 // SwiftData relationship — back-reference to User.plans
    @Relationship(deleteRule: .cascade, inverse: \Activity.plan)
    var activities: [Activity] = []

    init(name: String, distance: Double, raceDate: Date, goalTimeSeconds: Int? = nil) {
        self.name = name
        self.distance = distance
        self.raceDate = raceDate
        self.goalTimeSeconds = goalTimeSeconds
    }
}
