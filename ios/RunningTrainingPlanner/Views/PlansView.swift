//
//  PlansView.swift
//  RunningTrainingPlanner
//

import SwiftUI

// Controls which half of the plan list is shown
private enum PlanSegment: String, CaseIterable {
    case active = "Active"
    case past = "Past"
}

struct PlansView: View {
    @State private var plans: [Plan] = []
    @State private var loadFailed = false
    @State private var selectedSegment: PlanSegment = .active
    @State private var showNewPlan = false
    @State private var showEditPlan = false
    @State private var planToEdit: Plan? = nil

    private func loadPlans() async {
        loadFailed = false
        do {
            plans = try await APIService.fetchMyPlans()
        } catch {
            loadFailed = true
        }
    }

    // Plans whose race date is today or in the future, sorted soonest first
    private var activePlans: [Plan] {
        let today = Calendar.current.startOfDay(for: .now)
        return plans
            .filter { $0.raceDate >= today }
            .sorted { $0.raceDate < $1.raceDate }
    }

    // Plans whose race date has already passed, sorted most recent first
    private var pastPlans: [Plan] {
        let today = Calendar.current.startOfDay(for: .now)
        return plans
            .filter { $0.raceDate < today }
            .sorted { $0.raceDate > $1.raceDate }
    }

    // Plans shown in the current segment
    private var visiblePlans: [Plan] {
        selectedSegment == .active ? activePlans : pastPlans
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker — stays fixed below the nav bar as the list scrolls
                Picker("", selection: $selectedSegment) {
                    ForEach(PlanSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if loadFailed {
                            Text("Couldn't load plans. Check your connection.")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else if visiblePlans.isEmpty {
                            Text(selectedSegment == .active ? "No active plans." : "No past plans.")
                                .foregroundStyle(.secondary)
                                .padding()
                        }

                        ForEach(visiblePlans) { plan in
                            planCard(plan)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Plans")
                        .font(.title)
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewPlan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $showNewPlan) {
                NewPlanView(isModal: true)
            }
            .navigationDestination(isPresented: $showEditPlan) {
                if let plan = planToEdit {
                    NewPlanView(plan: plan)
                }
            }
            .task { await loadPlans() }
            .onChange(of: showNewPlan) { _, isShowing in
                if !isShowing { Task { await loadPlans() } }
            }
            .onChange(of: showEditPlan) { _, isShowing in
                if !isShowing { Task { await loadPlans() } }
            }
        }
    }

    // Card with a left-side colored bar using the plan's saved color
    @ViewBuilder
    private func planCard(_ plan: Plan) -> some View {
        HStack(spacing: 0) {
            // Left accent bar — color chosen by the user when the plan was created
            Rectangle()
                .fill(Color(hex: plan.planColor))
                .frame(width: 4)

            // Card content
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(.body)
                    HStack(spacing: 4) {
                        Text(plan.distance)
                        Text("·")
                        Text(plan.raceDate, format: .dateTime.month(.abbreviated).day().year())
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                // Edit button — .plain prevents the whole card from capturing the tap
                Button {
                    planToEdit = plan
                    showEditPlan = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color(.darkGray))
                        .padding(6)
                        .background(Circle().fill(Color(.systemGray6)))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }


}

#Preview {
    PlansView()
}
