//
//  CreatePlan.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/29/26.
//


import SwiftUI

struct CreatePlan: View {
    @State private var today = Date.now

    var body: some View {
        VStack {
            Text("Enter your race date")
                .font(.largeTitle)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 2)
                        .fill(Color.blue.opacity(0.1))
                )
            DatePicker("Enter your birthday", selection: $today, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .frame(maxHeight: 400)
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        }
    }
}

#Preview {
    CreatePlan()
}
