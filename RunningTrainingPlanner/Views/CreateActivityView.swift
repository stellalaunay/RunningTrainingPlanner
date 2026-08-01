//
//  SelectActivityTypeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/31/26.
//
import SwiftUI
import SwiftData

enum DistanceUnit: String, CaseIterable {
    case km = "km"
    case miles = "mi"
}

struct CreateActivityView: View {
    let date: Date // accepts passed date
    
    @State private var name: String = ""
    @State private var selectedType: ActivityType? = nil
    @State private var notes: String = ""
    @State private var time: Date = Date.now
    @State private var distance: Double? = nil
    
    @State private var distanceUnit: DistanceUnit = .km

    
    var body: some View {
        Form {
            Section {
                TextField("Activity name", text: $name)

                Picker(selection: $selectedType, label: Text("Choose a type...")) {
                    Text("Choose a type...").tag(nil as ActivityType?)
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as ActivityType?)
                    }
                }
            }

            Section {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                
                HStack {
                    TextField("Distance", value: $distance, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $distanceUnit) {
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 100)
                }
                    
                TextField("Notes", text: $notes, axis: .vertical)
            }
        }
        .contentMargins(.top, 20, for: .scrollContent)
        .navigationTitle("Activity")
    }
    
}

#Preview {
    NavigationStack {
            CreateActivityView(date: Date.now)
        }
}

