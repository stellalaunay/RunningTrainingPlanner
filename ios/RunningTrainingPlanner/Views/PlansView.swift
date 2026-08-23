//
//  PlansView.swift
//  RunningTrainingPlanner
//

import SwiftUI

struct PlansView: View {
    @State private var plans: [Plan] = []
    @State private var loadFailed = false
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if loadFailed {
                        Text("Couldn't load plans. Check your connection.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else if plans.isEmpty {
                        Text("You have no plans.")
                            .foregroundStyle(.secondary)
                            .padding()
                    }

                    // Active plans section
                    if !activePlans.isEmpty {
                        sectionHeader("Active")
                        ForEach(activePlans) { plan in
                            planCard(plan)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }

                    // Past plans section
                    if !pastPlans.isEmpty {
                        sectionHeader("Past")
                        ForEach(pastPlans) { plan in
                            planCard(plan)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical, 4)
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
                NewPlanView()
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

    // Section label — matches the sticky headers in ActivitiesView
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))
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
