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

struct Activity: Codable, Identifiable {
    var id: UUID { activityId }
    let activityId: UUID
    let planId: UUID?
    let name: String
    let date: Date
    let time: String?
    let type: ActivityType
    let notes: String?
    let distance: Double?
    let distanceUnit: DistanceUnit?
    let pace: Int?
    let paceTag: PaceTag?
    let duration: Int?
    let createdAt: Date
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case activityId = "activity_id"
        case planId = "plan_id"
        case name
        case date
        case time
        case type
        case notes
        case distance
        case distanceUnit = "distance_unit"
        case pace
        case paceTag = "pace_tag"
        case duration
        case createdAt = "created_at"
        case userId = "user_id"
    }
}
