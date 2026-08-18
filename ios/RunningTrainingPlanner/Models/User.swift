//
//  User.swift
//  RunningTrainingPlanner
//

import Foundation

struct User: Codable {
    let userId: UUID
    let firstName: String
    let lastName: String
    let profilePhotoUrl: String?
    let defaultDistanceUnit: DistanceUnit?
    let easyPace: Int?
    let longRunPace: Int?
    let speedPace: Int?
    let createdAt: Date
    let firebaseUid: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case profilePhotoUrl = "profile_photo_url"
        case defaultDistanceUnit = "default_distance_unit"
        case easyPace = "easy_pace"
        case longRunPace = "long_run_pace"
        case speedPace = "speed_pace"
        case createdAt = "created_at"
        case firebaseUid = "firebase_uid"
    }
}
