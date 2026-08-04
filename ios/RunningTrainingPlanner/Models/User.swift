//
//  User.swift
//  RunningTrainingPlanner
//

import SwiftUI
import SwiftData

@Model
final class User {
    var userId: UUID = UUID()
    var firstName: String
    var lastName: String
    // Stored as raw bytes; @Attribute(.externalStorage) keeps large binary data out of the main DB file
    @Attribute(.externalStorage) var profilePhotoData: Data?
    var defaultDistanceUnit: DistanceUnit = DistanceUnit.miles
    // Pace per tag, stored as total seconds per distance unit — matches the pace field on Activity
    var easyPace: Int?
    var longRunPace: Int?
    var speedPace: Int?
    // Cascade delete: removing the user also removes all their plans (and via Plan's cascade, their activities)
    @Relationship(deleteRule: .cascade, inverse: \Plan.user)
    var plans: [Plan] = []

    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}
