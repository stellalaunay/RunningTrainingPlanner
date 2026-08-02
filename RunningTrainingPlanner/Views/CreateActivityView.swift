//
//  SelectActivityTypeView.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/31/26.
//
import SwiftUI
import SwiftData

struct CreateActivityView: View {
    @State private var name: String = ""
    @State private var selectedType: ActivityType? = nil
    @State private var notes: String = ""
    @State private var date: Date
    @State private var includeTime: Bool = false

    init(initialDate: Date = .now) {
        _date = State(initialValue: initialDate)
    }
    @State private var time: Date = Date.now
    @State private var distance: Double? = nil
    @State private var distanceUnit: DistanceUnit = .miles
    @State private var paceMinutes: Int = 0
    @State private var paceSeconds: Int = 0
    @State private var showPacePicker = false
    @State private var duration: Int = 10

    var body: some View {
        VStack(spacing: 0) {
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
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Set time", isOn: $includeTime)
                if includeTime {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }

                if selectedType == .run || selectedType == .walk {
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
                }

                if selectedType == .run {
                    DisclosureGroup(
                        isExpanded: $showPacePicker,
                        content: {
                            HStack {
                                Spacer()
                                Picker("Minutes", selection: $paceMinutes) {
                                    ForEach(0..<60) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 50)
                                Text(":")
                                Picker("Seconds", selection: $paceSeconds) {
                                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 50)
                                Text("min/\(distanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            }
                        },
                        label: {
                            HStack {
                                Text("Pace")
                                Spacer()
                                Text("\(paceMinutes):\(String(format: "%02d", paceSeconds)) min/\(distanceUnit.rawValue)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    )
                }

                if selectedType == .rockClimb {
                    Picker("Duration", selection: $duration) {
                        ForEach(Array(stride(from: 10, through: 300, by: 10)), id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                }

                TextField("Notes", text: $notes, axis: .vertical)
            }

        }
        .contentMargins(.top, 20, for: .scrollContent)

        Button("Create Activity") {}
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Activity")
    }
    
}

#Preview {
    NavigationStack {
        CreateActivityView()
    }
}

