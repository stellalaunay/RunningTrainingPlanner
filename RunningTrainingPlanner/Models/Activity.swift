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
    case bike = "Bike"
    case other = "Other"
}

@Model
final class Activity {
    var date: Date
    var type: ActivityType
    

    init(date: Date, type: ActivityType) {
        self.date = date
        self.type = type
    }
    

    
}
