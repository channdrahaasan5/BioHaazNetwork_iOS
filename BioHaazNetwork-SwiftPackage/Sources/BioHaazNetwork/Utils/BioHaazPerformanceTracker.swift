//
//  BioHaazPerformanceTracker.swift
//  BioHaazNetwork
//
//  Tracks API performance metrics for analytics and monitoring
//

import Foundation

//public protocol BioHaazPerformanceTracker {
//    func track(request: URLRequest, duration: TimeInterval, success: Bool, speed: Double?)
//}

public class BioHaazDefaultPerformanceTracker: BioHaazPerformanceTracker {
    public var onReport: ((BioHaazPerformanceReport) -> Void)?
    public init(onReport: ((BioHaazPerformanceReport) -> Void)? = nil) {
        self.onReport = onReport
    }
    public func track(request: URLRequest, duration: TimeInterval, success: Bool, speed: Double?) {
        let report = BioHaazPerformanceReport(
            url: request.url?.absoluteString ?? "",
            method: request.httpMethod ?? "",
            duration: duration,
            success: success,
            speed: speed
        )
        onReport?(report)
    }
}

public struct BioHaazPerformanceReport {
    public let url: String
    public let method: String
    public let duration: TimeInterval
    public let success: Bool
    public let speed: Double?
} 
