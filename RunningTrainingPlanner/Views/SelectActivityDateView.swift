//
//  CreatePlan.swift
//  RunningTrainingPlanner
//
//  Created by Stella Launay on 7/29/26.
//


import SwiftUI

struct SelectActivityDateView: View {
    @State private var selectedDate = Date.now
    @State private var navigateToNextPage = false


    var body: some View {
        NavigationStack {
            VStack {
                Text("Select a date")
                    .font(.title2)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: 2)
                            .fill(Color.blue.opacity(0.1))
                    )
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxHeight: 400)
                    .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .onChange(of: selectedDate) { oldValue, newValue in
                        // Trigger page transition immediately or with a tiny delay
                        navigateToNextPage = true
                    }
            }
        }
        .navigationDestination(isPresented: $navigateToNextPage) {
            SelectActivityTypeView(date: selectedDate)
        }
        
    }
}

#Preview {
    SelectActivityDateView()
}
