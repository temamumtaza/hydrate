import Foundation
import UserNotifications
import SwiftUI

class HydrationManager: ObservableObject {
    @Published var remainingTarget: Double = 2000 // ml (jumlah yang harus diminum)
    @Published var dailyGoal: Double = 2000 // ml (target harian total)
    @Published var reminderInterval: TimeInterval = 3600 // 1 hour in seconds
    @Published var nextReminderTime: Date = Date().addingTimeInterval(3600)
    @Published var showCelebration: Bool = false // Track when to show celebration
    @Published var isNotificationAuthorized: Bool = false // Track notification authorization
    
    private var timer: Timer?
    private var uiUpdateTimer: Timer? // New timer for UI updates
    private let userDefaults = UserDefaults.standard
    private let remainingKey = "remainingTarget"
    private let goalKey = "dailyGoal"
    private let intervalKey = "reminderInterval"
    private let lastResetDateKey = "lastResetDate"
    
    // App theme colors - consistent with UI
    private let accentColor = Color(red: 0.29, green: 0.48, blue: 0.97)
    
    init() {
        loadData()
        setupNotifications()
        startTimer()
        startUIUpdateTimer() // Start separate timer for UI updates
        checkForDailyReset()
        updateNextReminderTime()
    }
    
    deinit {
        timer?.invalidate()
        uiUpdateTimer?.invalidate()
    }
    
    func loadData() {
        // Load saved values from UserDefaults
        dailyGoal = userDefaults.double(forKey: goalKey) != 0 ? userDefaults.double(forKey: goalKey) : 2000
        reminderInterval = userDefaults.double(forKey: intervalKey) != 0 ? userDefaults.double(forKey: intervalKey) : 3600
        remainingTarget = userDefaults.double(forKey: remainingKey)
        
        // Calculate remaining target only if it hasn't been initialized
        if remainingTarget <= 0 {
            remainingTarget = dailyGoal
        }
        
        updateNextReminderTime()
    }
    
    func saveData() {
        userDefaults.set(remainingTarget, forKey: remainingKey)
        userDefaults.set(dailyGoal, forKey: goalKey)
        userDefaults.set(reminderInterval, forKey: intervalKey)
    }
    
    func drinkWater(amount: Double) {
        // Previous remaining amount before drinking
        let previousRemaining = remainingTarget
        
        // Kurangi target yang tersisa dengan jumlah air yang diminum
        remainingTarget = max(0, remainingTarget - amount)
        saveData()
        
        // Check if the goal was just reached (previous > 0 and now == 0)
        if previousRemaining > 0 && remainingTarget == 0 {
            // Trigger celebration!
            showCelebration = true
            
            // Send a celebration notification
            sendCelebrationNotification()
        }
    }
    
    func resetTarget() {
        // Reset target ke nilai awal (dailyGoal)
        remainingTarget = dailyGoal
        showCelebration = false
        saveData()
        userDefaults.set(Date(), forKey: lastResetDateKey)
    }
    
    func checkForDailyReset() {
        guard let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date else {
            userDefaults.set(Date(), forKey: lastResetDateKey)
            return
        }
        
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            resetTarget()
        }
    }
    
    func updateDailyGoal(to newGoal: Double) {
        // Calculate how much water has been consumed so far
        let consumed = dailyGoal - remainingTarget
        
        // Update the goal
        dailyGoal = newGoal
        
        // Update remaining target by subtracting already consumed water from new goal
        // This prevents resetting progress when updating goal
        if consumed < newGoal {
            remainingTarget = newGoal - consumed
        } else {
            // If they've already consumed more than the new goal, keep remainingTarget at 0
            remainingTarget = 0
            showCelebration = true
        }
        
        saveData()
    }
    
    func updateReminderInterval(to newInterval: TimeInterval) {
        reminderInterval = newInterval
        saveData()
        restartTimer()
        updateNextReminderTime()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = granted
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                }
            }
        }
        
        // Check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isNotificationAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func updateNextReminderTime() {
        nextReminderTime = Date().addingTimeInterval(reminderInterval)
        
        // Force UI update
        objectWillChange.send()
    }
    
    func triggerNotification() {
        // Make sure we have permission before trying to send a notification
        if isNotificationAuthorized {
            // Clear any pending notifications first
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Send the notification immediately
            DispatchQueue.main.async { [weak self] in
                self?.sendNotification(immediate: true)
                self?.updateNextReminderTime()
            }
        } else {
            // Request permission if not authorized
            setupNotifications()
        }
    }
    
    private func sendNotification(immediate: Bool = false) {
        let content = UNMutableNotificationContent()
        
        // Array of friendly reminder messages
        let reminderMessages = [
            "It's hydration time! Just a friendly reminder that your body needs water. 💧",
            "Water break! Take a moment to hydrate - your future self will thank you. 🌊",
            "Staying hydrated is a form of self-care. Time for some refreshment! 🥤",
            "Your friendly hydration reminder is here! Take a sip and stay energized. ⚡",
            "Hydration checkpoint! Remember to drink water for better focus and energy. 🧠"
        ]
        
        // Get a random message
        let randomMessage = reminderMessages.randomElement() ?? "Time to hydrate!"
        
        content.title = "Hydration Reminder"
        content.body = "\(randomMessage) You still need to drink \(Int(remainingTarget))ml to reach your \(Int(dailyGoal))ml goal."
        content.sound = UNNotificationSound.default
        
        // Add a blue color hint to the notification (will be used on platforms that support it)
        content.categoryIdentifier = "hydration_reminder"
        
        // Create a trigger that delivers the notification immediately or with a 1 second delay
        let timeInterval = immediate ? 0.1 : 1.0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Create the request with a unique identifier
        let identifier = immediate ? "test-notification-\(UUID().uuidString)" : UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    private func sendCelebrationNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Congratulations! 🎉"
        content.body = "You've reached your daily hydration goal of \(Int(dailyGoal))ml! Amazing job taking care of yourself!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "hydration_celebration"
        
        // Create a trigger that delivers the notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "celebration-\(UUID().uuidString)", content: content, trigger: trigger)
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending celebration notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func startTimer() {
        // Cancel any existing timer first
        timer?.invalidate()
        
        // Create a new timer with the current reminder interval
        timer = Timer.scheduledTimer(withTimeInterval: reminderInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Send notification
            self.sendNotification()
            
            // Update next reminder time
            self.updateNextReminderTime()
        }
        
        // Make sure the timer runs even if the app is in the background
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // New method to start a UI update timer that runs more frequently
    private func startUIUpdateTimer() {
        uiUpdateTimer?.invalidate()
        
        // Create a timer that updates the UI every second
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Force UI update to refresh the countdown
            self.objectWillChange.send()
        }
        
        if let uiUpdateTimer = uiUpdateTimer {
            RunLoop.main.add(uiUpdateTimer, forMode: .common)
        }
    }
    
    private func restartTimer() {
        // Invalidate the existing timer
        timer?.invalidate()
        timer = nil
        
        // Start a new timer with the updated interval
        startTimer()
    }
    
    var progressPercentage: Double {
        // Progress dihitung sebagai persentase target yang sudah diminum
        // 0% berarti belum minum sama sekali (remainingTarget == dailyGoal)
        // 100% berarti sudah minum semuanya (remainingTarget == 0)
        return 1.0 - min(remainingTarget / dailyGoal, 1.0)
    }
    
    // Format time remaining until next reminder
    func formattedTimeRemaining() -> String {
        let timeRemaining = max(0, nextReminderTime.timeIntervalSince(Date()))
        
        if timeRemaining <= 0 {
            return "now"
        }
        
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
} 