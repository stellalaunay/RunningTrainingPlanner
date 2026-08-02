//
//  Plan.swift
//  RunningTrainingPlanner
//

import SwiftData
import Foundation

@Model
final class Plan {
    var name: String
    var distance: Double
    var raceDate: Date
    var goalTimeSeconds: Int?
    @Relationship(deleteRule: .cascade, inverse: \Activity.plan)
    var activities: [Activity] = []

    init(name: String, distance: Double, raceDate: Date, goalTimeSeconds: Int? = nil) {
        self.name = name
        self.distance = distance
        self.raceDate = raceDate
        self.goalTimeSeconds = goalTimeSeconds
    }
}
