//
//  BioHaazOfflineQueue.swift
//  BioHaazNetwork
//
//  Enhanced offline queue with background processing support
//

import Foundation

public class BioHaazOfflineQueue {
    public static let shared = BioHaazOfflineQueue()
    private var queue: [BioHaazOfflineQueueItem] = []
    private let queueKey = "BioHaazOfflineQueue"
    private let maxQueueSize = 1000
    
    private init() {
        loadQueue()
    }
    
    public func add(
        _ request: URLRequest,
        priority: BioHaazOfflineQueueItem.Priority = .normal,
        maxRetries: Int = 3
    ) -> Result<Void, BioHaazNetworkError> {
        // Check for duplicate requests before adding
        if let existingIndex = findDuplicateRequest(request) {
            let existingItem = queue[existingIndex]
            
            // Update priority if new request has higher priority
            if priority.rawValue > existingItem.priority.rawValue {
                queue[existingIndex] = BioHaazOfflineQueueItem(
                    id: existingItem.id, // Keep same ID
                    request: request,
                    timestamp: existingItem.timestamp, // Keep original timestamp
                    retryCount: existingItem.retryCount,
                    priority: priority,
                    maxRetries: max(maxRetries, existingItem.maxRetries)
                )
                saveQueue()
                
                BioHaazLogger.shared.logOfflineQueue(
                    action: "UPDATED_PRIORITY",
                    queueCount: queue.count,
                    priority: priority.rawValue.description,
                    requestId: existingItem.id
                )
            } else {
                BioHaazLogger.shared.logOfflineQueue(
                    action: "DUPLICATE_SKIPPED",
                    queueCount: queue.count,
                    priority: existingItem.priority.rawValue.description,
                    requestId: existingItem.id
                )
            }
            
            return .success(())
        }
        
        // Check queue size limit
        if queue.count >= maxQueueSize {
            // Remove oldest low priority items
            queue = queue.filter { $0.priority != .low } + queue.filter { $0.priority == .low }
            if queue.count >= maxQueueSize {
                queue.removeFirst(queue.count - maxQueueSize + 1)
            }
        }
        
        let item = BioHaazOfflineQueueItem(
            request: request,
            priority: priority,
            maxRetries: maxRetries
        )
        queue.append(item)
        saveQueue()
        
        // Log offline queue action
        BioHaazLogger.shared.logOfflineQueue(
            action: "ADDED",
            queueCount: queue.count,
            priority: priority.rawValue.description,
            requestId: item.id
        )
        
        return .success(())
    }
    
    /// Find duplicate request in the queue
    private func findDuplicateRequest(_ request: URLRequest) -> Int? {
        return queue.firstIndex { existingItem in
            // Compare URL
            guard existingItem.request.url == request.url else { return false }
            
            // Compare HTTP method
            guard existingItem.request.httpMethod == request.httpMethod else { return false }
            
            // Compare body content for POST/PUT requests
            if let existingBody = existingItem.request.httpBody,
               let newBody = request.httpBody {
                return existingBody == newBody
            } else if existingItem.request.httpBody == nil && request.httpBody == nil {
                return true
            }
            
            return false
        }
    }
    
    /// Process queue items synchronously (legacy method - items removed immediately)
    /// NOTE: This method removes items immediately before async requests complete.
    /// For async processing, use getSortedQueue() and manually remove items after completion.
    public func processQueue(using handler: @escaping (URLRequest) -> Void, sendNotifications: Bool = true) -> Result<Void, BioHaazNetworkError> {
        // Log queue processing start
        BioHaazLogger.shared.logOfflineQueue(
            action: "PROCESSING_START",
            queueCount: queue.count
        )
        
        let initialQueueCount = queue.count
        
        // Sort by priority (critical first) and timestamp (FIFO within same priority)
        let sortedQueue = getSortedQueue()
        
        var processedItems: [String] = []
        var failedItems: [BioHaazOfflineQueueItem] = []
        
        for item in sortedQueue {
            handler(item.request)
            processedItems.append(item.id)
            
            // Log individual item processing
            BioHaazLogger.shared.logOfflineQueue(
                action: "PROCESSED",
                queueCount: queue.count,
                priority: item.priority.rawValue.description,
                requestId: item.id
            )
            
            // If processing failed, increment retry count
            if item.canRetry() {
                failedItems.append(item.withIncrementedRetry())
            }
        }
        
        // Remove processed items and add failed items back
        queue = queue.filter { !processedItems.contains($0.id) } + failedItems
        saveQueue()
        
        // MARK: - Notification Service (Commented for next version)
        // Send notification for processed requests (only if requested)
        // let processedCount = processedItems.count
        // let failedCount = failedItems.count
        // 
        // if sendNotifications {
        //     if processedCount > 0 {
        //         BioHaazNotificationService.shared.sendOfflineRequestProcessedNotification(
        //             processedCount: processedCount
        //         )
        //     }
        //     
        //     if failedCount > 0 {
        //         BioHaazNotificationService.shared.sendOfflineRequestFailedNotification(
        //             failedCount: failedCount
        //         )
        //     }
        // }
        
        // Log queue processing completion
        BioHaazLogger.shared.logOfflineQueue(
            action: "PROCESSING_COMPLETE",
            queueCount: queue.count
        )
        
        return .success(())
    }
    
    public func clear() -> Result<Void, BioHaazNetworkError> {
        queue.removeAll()
        saveQueue()
        return .success(())
    }
    
    public func getQueueCount() -> Int {
        return queue.count
    }
    
    /// Remove a specific item from the queue by ID (called after successful processing)
    public func removeItem(id: String) {
        let beforeCount = queue.count
        queue.removeAll { $0.id == id }
        if queue.count < beforeCount {
            saveQueue()
            BioHaazLogger.shared.logOfflineQueue(
                action: "REMOVED_SUCCESS",
                queueCount: queue.count,
                requestId: id
            )
        }
    }
    
    /// Update item retry count after failed processing
    public func updateItemForRetry(id: String) -> Bool {
        guard let index = queue.firstIndex(where: { $0.id == id }) else {
            return false
        }
        
        let item = queue[index]
        if item.canRetry() {
            queue[index] = item.withIncrementedRetry()
            saveQueue()
            BioHaazLogger.shared.logOfflineQueue(
                action: "RETRY_INCREMENTED",
                queueCount: queue.count,
                requestId: id
            )
            return true
        } else {
            // Max retries reached, remove item
            queue.remove(at: index)
            saveQueue()
            BioHaazLogger.shared.logOfflineQueue(
                action: "REMOVED_MAX_RETRIES",
                queueCount: queue.count,
                requestId: id
            )
            return false
        }
    }
    
    /// Get sorted queue items without removing them (for async processing)
    public func getSortedQueue() -> [BioHaazOfflineQueueItem] {
        return queue.sorted { first, second in
            if first.priority.rawValue != second.priority.rawValue {
                return first.priority.rawValue > second.priority.rawValue
            }
            return first.timestamp < second.timestamp
        }
    }
    
    /// Get queue statistics including duplicate information
    public func getQueueStatistics() -> [String: Any] {
        let priorityCount = Dictionary(grouping: queue, by: { $0.priority })
            .mapValues { $0.count }
        
        let urlCount = Dictionary(grouping: queue, by: { $0.request.url?.absoluteString ?? "unknown" })
            .mapValues { $0.count }
        
        let duplicateUrls = urlCount.filter { $0.value > 1 }
        
        return [
            "totalCount": queue.count,
            "priorityBreakdown": priorityCount,
            "duplicateUrls": duplicateUrls,
            "duplicateCount": duplicateUrls.values.reduce(0, +) - duplicateUrls.count
        ]
    }
    
    public func getQueueStatus() -> (total: Int, byPriority: [BioHaazOfflineQueueItem.Priority: Int]) {
        var byPriority: [BioHaazOfflineQueueItem.Priority: Int] = [:]
        for priority in BioHaazOfflineQueueItem.Priority.allCases {
            byPriority[priority] = queue.filter { $0.priority == priority }.count
        }
        return (total: queue.count, byPriority: byPriority)
    }
    
    private func saveQueue() {
        do {
            let data = try JSONEncoder().encode(queue)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            print("Failed to save offline queue: \(error)")
        }
    }
    
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return }
        do {
            queue = try JSONDecoder().decode([BioHaazOfflineQueueItem].self, from: data)
        } catch {
            print("Failed to load offline queue: \(error)")
            queue = []
        }
    }
}

// MARK: - BioHaazOfflineQueueItem Extensions
extension BioHaazOfflineQueueItem {
    func canRetry() -> Bool {
        return retryCount < maxRetries
    }
}
