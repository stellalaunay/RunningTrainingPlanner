//
//  NewPlanView.swift
//  RunningTrainingPlanner
//

import SwiftUI

struct NewPlanView: View {
    @State private var name: String = ""
    @State private var goalDistance: Double? = nil
    @State private var goalHours: Int = 0
    @State private var goalMinutes: Int = 0
    @State private var goalSeconds: Int = 0
    @State private var showGoalTimePicker = false
    @State private var raceDate: Date = Date.now

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && goalDistance != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Plan name", text: $name)
                    TextField("Distance", value: $goalDistance, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section {
                    DatePicker("Race date", selection: $raceDate, displayedComponents: .date)
                }

                Section {
                    DisclosureGroup(
                        isExpanded: $showGoalTimePicker,
                        content: {
                            HStack {
                                Spacer()
                                Picker("Hours", selection: $goalHours) {
                                    ForEach(0..<24) { Text("\($0)h").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                Text(":")
                                Picker("Minutes", selection: $goalMinutes) {
                                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60)
                                Text(":")
                                Picker("Seconds", selection: $goalSeconds) {
                                    ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 60)
                                Spacer()
                            }
                            .labelsHidden()
                        },
                        label: {
                            HStack {
                                Text("Goal time")
                                Spacer()
                                Text("\(goalHours):\(String(format: "%02d", goalMinutes)):\(String(format: "%02d", goalSeconds))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    )
                }
            }
            .contentMargins(.top, 20, for: .scrollContent)

            Button("Create Plan") {}
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(!isFormValid)
        }
        .navigationTitle("New Run Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NewPlanView()
    }
}
