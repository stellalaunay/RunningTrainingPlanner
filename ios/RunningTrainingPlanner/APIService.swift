//
//  APIService.swift
//  RunningTrainingPlanner
//

import Foundation
import FirebaseAuth
import FirebaseCore

// All backend API calls. Base URL points to the local FastAPI server.
enum APIService {
    static let baseURL = "http://localhost:8001"

    // Formats a Date as "yyyy-MM-dd" for backend date fields
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // Formats a Date as "HH:mm:ss" for backend time fields
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // Converts a Date to an "HH:mm:ss" string for sending to the backend
    static func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    // Handles both "yyyy-MM-dd" date-only strings (date, race_date) and ISO 8601 datetimes (created_at)
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }
            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            dateOnly.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateOnly.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }()

    // Returns the current user's Firebase ID token. Skips gracefully in Xcode Previews.
    private static func authToken() async throws -> String {
        // FirebaseApp is not configured in Xcode Previews — avoid calling Auth
        guard FirebaseApp.app() != nil else { throw URLError(.userAuthenticationRequired) }
        guard let user = Auth.auth().currentUser else { throw URLError(.userAuthenticationRequired) }
        return try await user.getIDToken()
    }

    // Builds a URLRequest with the auth header and optional JSON body
    private static func request(path: String, method: String, bodyData: Data? = nil) async throws -> URLRequest {
        let token = try await authToken()
        guard let url = URL(string: "\(baseURL)\(path)") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let data = bodyData {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = data
        }
        return req
    }

    // MARK: - Users

    static func createUser(firstName: String, lastName: String) async throws {
        struct Body: Encodable {
            let first_name: String
            let last_name: String
        }
        let body = try JSONEncoder().encode(Body(first_name: firstName, last_name: lastName))
        let req = try await request(path: "/users", method: "POST", bodyData: body)
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Activities

    static func fetchWeekActivities(monday: Date, sunday: Date) async throws -> [Activity] {
        let start = dateFormatter.string(from: monday)
        let end = dateFormatter.string(from: sunday)
        let req = try await request(path: "/activities/filter/week?start_date=\(start)&end_date=\(end)", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode([Activity].self, from: data)
    }

    static func fetchMyActivities() async throws -> [Activity] {
        let req = try await request(path: "/activities/me", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode([Activity].self, from: data)
    }

    static func createActivity(
        name: String, date: Date, type: ActivityType,
        planId: UUID? = nil, time: String? = nil, notes: String? = nil,
        distance: Double? = nil, distanceUnit: DistanceUnit? = nil,
        pace: Int? = nil, paceTag: PaceTag? = nil, duration: Int? = nil
    ) async throws -> Activity {
        struct Body: Encodable {
            let name: String
            let date: String
            let type: ActivityType
            let plan_id: UUID?
            let time: String?
            let notes: String?
            let distance: Double?
            let distance_unit: DistanceUnit?
            let pace: Int?
            let pace_tag: PaceTag?
            let duration: Int?
        }
        let body = try JSONEncoder().encode(Body(
            name: name, date: dateFormatter.string(from: date), type: type,
            plan_id: planId, time: time, notes: notes,
            distance: distance, distance_unit: distanceUnit,
            pace: pace, pace_tag: paceTag, duration: duration
        ))
        let req = try await request(path: "/activities", method: "POST", bodyData: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(Activity.self, from: data)
    }

    static func updateActivity(
        id: UUID, name: String, date: Date, type: ActivityType,
        planId: UUID? = nil, time: String? = nil, notes: String? = nil,
        distance: Double? = nil, distanceUnit: DistanceUnit? = nil,
        pace: Int? = nil, paceTag: PaceTag? = nil, duration: Int? = nil
    ) async throws -> Activity {
        struct Body: Encodable {
            let name: String?
            let date: String?
            let type: ActivityType?
            let plan_id: UUID?
            let time: String?
            let notes: String?
            let distance: Double?
            let distance_unit: DistanceUnit?
            let pace: Int?
            let pace_tag: PaceTag?
            let duration: Int?
        }
        let body = try JSONEncoder().encode(Body(
            name: name, date: dateFormatter.string(from: date), type: type,
            plan_id: planId, time: time, notes: notes,
            distance: distance, distance_unit: distanceUnit,
            pace: pace, pace_tag: paceTag, duration: duration
        ))
        let req = try await request(path: "/activities/\(id)", method: "PUT", bodyData: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(Activity.self, from: data)
    }

    static func deleteActivity(id: UUID) async throws {
        let req = try await request(path: "/activities/\(id)", method: "DELETE")
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Users (profile)

    static func fetchMyProfile() async throws -> User {
        let req = try await request(path: "/users/me", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(User.self, from: data)
    }

    static func updateProfile(
        firstName: String? = nil, lastName: String? = nil,
        defaultDistanceUnit: DistanceUnit? = nil,
        easyPace: Int? = nil, longRunPace: Int? = nil, speedPace: Int? = nil
    ) async throws -> User {
        struct Body: Encodable {
            let first_name: String?
            let last_name: String?
            let default_distance_unit: DistanceUnit?
            let easy_pace: Int?
            let long_run_pace: Int?
            let speed_pace: Int?
        }
        let body = try JSONEncoder().encode(Body(
            first_name: firstName, last_name: lastName,
            default_distance_unit: defaultDistanceUnit,
            easy_pace: easyPace, long_run_pace: longRunPace, speed_pace: speedPace
        ))
        let req = try await request(path: "/users", method: "PUT", bodyData: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(User.self, from: data)
    }

    // MARK: - Plans

    static func fetchMyPlans() async throws -> [Plan] {
        let req = try await request(path: "/plans/me", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode([Plan].self, from: data)
    }

    static func createPlan(
        name: String, distance: Double, raceDate: Date, goalTimeSeconds: Int? = nil
    ) async throws -> Plan {
        struct Body: Encodable {
            let name: String
            let distance: Double
            let race_date: String
            let goal_time_seconds: Int?
        }
        let body = try JSONEncoder().encode(Body(
            name: name, distance: distance,
            race_date: dateFormatter.string(from: raceDate),
            goal_time_seconds: goalTimeSeconds
        ))
        let req = try await request(path: "/plans", method: "POST", bodyData: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(Plan.self, from: data)
    }
}
