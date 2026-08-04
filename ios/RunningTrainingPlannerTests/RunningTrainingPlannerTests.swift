//
//  RunningTrainingPlannerTests.swift
//  RunningTrainingPlannerTests
//
//  Created by Stella Launay on 7/28/26.
//

import Testing
import Foundation
@testable import RunningTrainingPlanner

// Known Monday used as a stable base date across all tests
private let knownMonday = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 3))!

// MARK: - WeekNavigator tests

@Suite struct WeekNavigatorTests {

    @Test func datesReturnsSevenDays() {
        let nav = WeekNavigator(offset: 0, baseDate: knownMonday)
        #expect(nav.dates.count == 7)
    }

    @Test func firstDateIsMonday() {
        let nav = WeekNavigator(offset: 0, baseDate: knownMonday)
        // weekday 2 = Monday in Calendar.current (where Sunday = 1)
        let weekday = Calendar.current.component(.weekday, from: nav.dates[0])
        #expect(weekday == 2)
    }

    @Test func datesAreConsecutive() {
        let nav = WeekNavigator(offset: 0, baseDate: knownMonday)
        let dates = nav.dates
        for i in 1..<dates.count {
            let gap = Calendar.current.dateComponents([.day], from: dates[i - 1], to: dates[i]).day
            #expect(gap == 1)
        }
    }

    @Test func titleIsThisWeekAtOffsetZero() {
        let nav = WeekNavigator(offset: 0, baseDate: knownMonday)
        #expect(nav.title == "This Week")
    }

    @Test func titleShowsDateRangeAtPositiveOffset() {
        let nav = WeekNavigator(offset: 1, baseDate: knownMonday)
        #expect(nav.title == "08/10 - 08/16")
    }

    @Test func titleShowsDateRangeAtNegativeOffset() {
        let nav = WeekNavigator(offset: -1, baseDate: knownMonday)
        #expect(nav.title == "07/27 - 08/02")
    }

    @Test func nextWeekStartsOnCorrectMonday() {
        let nav = WeekNavigator(offset: 1, baseDate: knownMonday)
        let expected = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10))!
        #expect(Calendar.current.isDate(nav.dates[0], inSameDayAs: expected))
    }

    @Test func previousWeekStartsOnCorrectMonday() {
        let nav = WeekNavigator(offset: -1, baseDate: knownMonday)
        let expected = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 27))!
        #expect(Calendar.current.isDate(nav.dates[0], inSameDayAs: expected))
    }
}
