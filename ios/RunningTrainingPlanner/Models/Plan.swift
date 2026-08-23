//
//  Plan.swift
//  RunningTrainingPlanner
//

import Foundation

struct Plan: Codable, Identifiable, Hashable {
    var id: UUID { planId }
    let planId: UUID
    let userId: UUID
    let name: String
    let distance: String
    let raceDate: Date
    let goalTimeSeconds: Int?
    let createdAt: Date
    let isPublic: Bool?
    let planColor: String

    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case userId = "user_id"
        case name
        case distance
        case raceDate = "race_date"
        case goalTimeSeconds = "goal_time_seconds"
        case createdAt = "created_at"
        case isPublic = "is_public"
        case planColor = "plan_color"
    }
}
