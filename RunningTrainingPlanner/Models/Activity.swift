//
//  Activity.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/30/26.
//

import SwiftUI
import SwiftData


enum ActivityType: String, Codable, CaseIterable {
    case run = "Run"
    case strengthTraining = "Strength Training"
    case walk = "Walk"
    case rockClimb = "Rock Climb"
    case other = "Other"

    var color: Color {
        switch self {
        case .run:              return .orange
        case .strengthTraining: return .blue
        case .walk:             return .green
        case .rockClimb:        return .purple
        case .other:            return .gray
        }
    }
}

enum DistanceUnit: String, Codable, CaseIterable {
    case km = "km"
    case miles = "mi"
}

// Labels a run with its intended effort level — Easy, Long Run, or Speed.
// Later, each tag will map to a user-defined pace range in their profile for auto-fill.
enum PaceTag: String, Codable, CaseIterable {
    case easy = "Easy"
    case longRun = "Long Run"
    case speed = "Speed"

    var color: Color {
        switch self {
        case .easy:    return .green
        case .longRun: return .blue
        case .speed:   return .red
        }
    }
}

@Model
final class Activity {
    var name: String
    var date: Date
    var time: Date?
    var type: ActivityType
    var notes: String?
    var distance: Double?
    var distanceUnit: DistanceUnit?
    var pace: Int?
    var paceTag: PaceTag?
    var duration: Int?
    var plan: Plan?

    init(name: String, date: Date, time: Date? = nil, type: ActivityType, notes: String? = nil, distance: Double? = nil, distanceUnit: DistanceUnit? = nil, pace: Int? = nil, paceTag: PaceTag? = nil, duration: Int? = nil) {
        self.name = name
        self.date = date
        self.time = time
        self.type = type
        self.notes = notes
        self.distance = distance
        self.distanceUnit = distanceUnit
        self.pace = pace
        self.paceTag = paceTag
        self.duration = duration
    }
}
