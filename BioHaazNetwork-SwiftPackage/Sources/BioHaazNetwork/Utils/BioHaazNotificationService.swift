//
//  BioHaazNotificationService.swift
//  BioHaazNetwork
//
//  Notification service for offline request processing notifications
//

import Foundation
import UserNotifications
import UIKit

public class BioHaazNotificationService {
    public static let shared = BioHaazNotificationService()
    
    private var isPermissionRequested = false
    private var notificationCenter: UNUserNotificationCenter {
        return UNUserNotificationCenter.current()
    }
    
    private init() {}
    
    // MARK: - Permission Management
    
    public func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        guard !isPermissionRequested else {
            checkNotificationStatus(completion: completion)
            return
        }
        
        isPermissionRequested = true
        
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("BioHaazNetwork: Notification permission error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("BioHaazNetwork: Notification permission granted: \(granted)")
                    completion(granted)
                }
            }
        }
    }
    
    public func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
    }
    
    // MARK: - Notification Sending
    
    public func sendOfflineRequestProcessedNotification(
        title: String = "Offline Request Processed",
        body: String = "Your offline request has been successfully processed",
        processedCount: Int = 1
    ) {
        checkNotificationStatus { [weak self] isAuthorized in
            guard isAuthorized else {
                print("BioHaazNetwork: Notifications not authorized, skipping notification")
                return
            }
            
            self?.scheduleNotification(
                title: title,
                body: processedCount > 1 ? "\(processedCount) offline requests have been processed" : body,
                identifier: "biohaaz_offline_processed_\(Date().timeIntervalSince1970)"
            )
        }
    }
    
    public func sendOfflineRequestFailedNotification(
        title: String = "Offline Request Failed",
        body: String = "Some offline requests could not be processed",
        failedCount: Int = 1
    ) {
        checkNotificationStatus { [weak self] isAuthorized in
            guard isAuthorized else {
                print("BioHaazNetwork: Notifications not authorized, skipping notification")
                return
            }
            
            self?.scheduleNotification(
                title: title,
                body: failedCount > 1 ? "\(failedCount) offline requests failed to process" : body,
                identifier: "biohaaz_offline_failed_\(Date().timeIntervalSince1970)"
            )
        }
    }
    
    /// Send a single combined notification with processing results
    public func sendOfflineQueueProcessingSummary(
        processedCount: Int,
        failedCount: Int,
        title: String? = nil,
        customBody: String? = nil
    ) {
        checkNotificationStatus { [weak self] isAuthorized in
            guard isAuthorized else {
                print("BioHaazNetwork: Notifications not authorized, skipping notification")
                return
            }
            
            let notificationTitle: String
            let notificationBody: String
            
            if let customTitle = title, let customBody = customBody {
                notificationTitle = customTitle
                notificationBody = customBody
            } else {
                // Determine title based on results
                if processedCount > 0 && failedCount == 0 {
                    notificationTitle = "Offline Requests Processed"
                    if processedCount == 1 {
                        notificationBody = "1 offline request has been processed successfully"
                    } else {
                        notificationBody = "\(processedCount) offline requests have been processed successfully"
                    }
                } else if processedCount == 0 && failedCount > 0 {
                    notificationTitle = "Offline Requests Failed"
                    if failedCount == 1 {
                        notificationBody = "1 offline request failed to process"
                    } else {
                        notificationBody = "\(failedCount) offline requests failed to process"
                    }
                } else if processedCount > 0 && failedCount > 0 {
                    notificationTitle = "Offline Queue Processing Complete"
                    notificationBody = "\(processedCount) processed, \(failedCount) failed"
                } else {
                    // No requests processed
                    return
                }
            }
            
            self?.scheduleNotification(
                title: notificationTitle,
                body: notificationBody,
                identifier: "biohaaz_offline_summary_\(Date().timeIntervalSince1970)",
                userInfo: [
                    "processedCount": processedCount,
                    "failedCount": failedCount,
                    "source": "BioHaazNetwork"
                ]
            )
        }
    }
    
    public func sendNetworkStatusNotification(
        title: String = "Network Status",
        body: String,
        isOnline: Bool
    ) {
        checkNotificationStatus { [weak self] isAuthorized in
            guard isAuthorized else {
                print("BioHaazNetwork: Notifications not authorized, skipping notification")
                return
            }
            
            let identifier = isOnline ? "biohaaz_network_online" : "biohaaz_network_offline"
            self?.scheduleNotification(
                title: title,
                body: body,
                identifier: identifier
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        userInfo: [String: Any]? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        var notificationUserInfo: [String: Any] = [
            "source": "BioHaazNetwork",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Merge with provided userInfo
        if let providedUserInfo = userInfo {
            notificationUserInfo.merge(providedUserInfo) { (_, new) in new }
        }
        
        content.userInfo = notificationUserInfo
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("BioHaazNetwork: Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("BioHaazNetwork: Notification scheduled successfully")
            }
        }
    }
    
    // MARK: - Notification Management
    
    public func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    public func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    public func getPendingNotificationCount(completion: @escaping (Int) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.count)
            }
        }
    }
    
    public func getDeliveredNotificationCount(completion: @escaping (Int) -> Void) {
        notificationCenter.getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications.count)
            }
        }
    }
}

// MARK: - Notification Categories

extension BioHaazNotificationService {
    
    public enum NotificationCategory: String {
        case offlineProcessed = "OFFLINE_PROCESSED"
        case offlineFailed = "OFFLINE_FAILED"
        case networkStatus = "NETWORK_STATUS"
        
        public var identifier: String {
            return "biohaaz_\(self.rawValue.lowercased())"
        }
    }
    
    public func setupNotificationCategories() {
        let processedCategory = UNNotificationCategory(
            identifier: NotificationCategory.offlineProcessed.identifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let failedCategory = UNNotificationCategory(
            identifier: NotificationCategory.offlineFailed.identifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let networkCategory = UNNotificationCategory(
            identifier: NotificationCategory.networkStatus.identifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([
            processedCategory,
            failedCategory,
            networkCategory
        ])
    }
}






