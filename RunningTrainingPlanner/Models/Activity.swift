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
}

@Model
final class Activity {
    var date: Date
    var time: Date
    var type: ActivityType

    init(date: Date, time: Date, type: ActivityType) {
        self.date = date
        self.time = time
        self.type = type
    }
    

    
}
