import SwiftUI
import Foundation

struct SettingsView: View {
    @ObservedObject var hydrationManager: HydrationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showNotificationAlert = false
    
    @State private var dailyGoal: Double
    @State private var reminderInterval: Double
    
    // Define constant colors for consistency (same as in PopoverView)
    private let accentColor = Color(red: 0.29, green: 0.48, blue: 0.97)  // Blue accent
    private let backgroundColor = Color(red: 0.12, green: 0.12, blue: 0.14)  // Dark background
    private let secondaryColor = Color(red: 0.22, green: 0.22, blue: 0.25)  // Slightly lighter dark
    private let textColor = Color.white
    private let secondaryTextColor = Color.gray
    
    private let reminderIntervals = [
        5.0: "5 minutes",
        15.0: "15 minutes",
        30.0: "30 minutes",
        45.0: "45 minutes",
        60.0: "1 hour",
        90.0: "1.5 hours",
        120.0: "2 hours",
        180.0: "3 hours",
        240.0: "4 hours"
    ]
    
    init(hydrationManager: HydrationManager) {
        self.hydrationManager = hydrationManager
        _dailyGoal = State(initialValue: hydrationManager.dailyGoal)
        _reminderInterval = State(initialValue: hydrationManager.reminderInterval / 60) // Convert to minutes
    }
    
    var body: some View {
        ZStack {
            // Main background - keep this to fill the entire sheet
            secondaryColor.edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title2)
                    .bold()
                    .foregroundColor(textColor)
                    .padding(.top, 10)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Water Goal")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        HStack {
                            Slider(value: $dailyGoal, in: 500...5000, step: 100)
                                .accentColor(accentColor)
                                .onChange(of: dailyGoal) { newValue in
                                    hydrationManager.logUserAction(action: "Adjust Daily Goal", details: "\(Int(newValue))ml")
                                }
                            HStack(spacing: 0) {
                                Text("\(Int(dailyGoal))")
                                    .foregroundColor(textColor)
                                    .frame(width: 50, alignment: .trailing)
                                
                                Text(" ml")
                                    .foregroundColor(secondaryTextColor)
                                    .frame(width: 20, alignment: .leading)
                            }
                            .frame(width: 70)
                        }
                        
                        Text("Recommended: 2000-3000 ml per day")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reminder Interval")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Picker("Remind me every:", selection: $reminderInterval) {
                            ForEach(Array(reminderIntervals.keys).sorted(), id: \.self) { minutes in
                                Text(reminderIntervals[minutes] ?? "\(Int(minutes)) min").tag(minutes)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                        .accentColor(accentColor)
                        .onChange(of: reminderInterval) { newValue in
                            hydrationManager.logUserAction(action: "Change Reminder Interval", details: reminderIntervals[newValue] ?? "\(Int(newValue)) min")
                        }
                        
                        // Display next reminder time
                        HStack {
                            Text("Next reminder in:")
                                .foregroundColor(secondaryTextColor)
                            Text(hydrationManager.formattedTimeRemaining())
                                .bold()
                                .foregroundColor(textColor)
                                .onReceive(timer) { _ in
                                    // Update timer display
                                }
                        }
                        .font(.caption)
                        .padding(.top, 4)
                        
                        Text("How often you want to be reminded to drink water")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.horizontal)
                    
                    // Test notification button
                    HStack {
                        Button("Test Notification") {
                            hydrationManager.logUserAction(action: "Test Notification")
                            if hydrationManager.isNotificationAuthorized {
                                hydrationManager.triggerNotification()
                            } else {
                                showNotificationAlert = true
                            }
                        }
                        .buttonStyle(ConsistentButtonStyle(color: accentColor, isSmall: true))
                        .padding(.top, 5)
                        
                        if !hydrationManager.isNotificationAuthorized {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.footnote)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Add all buttons in one row
                HStack {
                    Button("Cancel") {
                        hydrationManager.logUserAction(action: "Cancel Settings")
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(ConsistentButtonStyle(color: accentColor, isOutlined: true))
                    
                    Spacer()
                    
                    // Quit button in the middle
                    Button("Quit App") {
                        hydrationManager.logUserAction(action: "Quit App")
                        // Using a more direct method to quit the app even in debug mode
                        exit(0)
                    }
                    .buttonStyle(ConsistentButtonStyle(color: .red))
                    
                    Spacer()
                    
                    Button("Save") {
                        hydrationManager.logUserAction(action: "Save Settings", details: "Goal: \(Int(dailyGoal))ml, Interval: \(reminderIntervals[reminderInterval] ?? "\(Int(reminderInterval)) min")")
                        // Save settings
                        hydrationManager.updateDailyGoal(to: dailyGoal)
                        hydrationManager.updateReminderInterval(to: reminderInterval * 60) // Convert to seconds
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(ConsistentButtonStyle(color: accentColor))
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .frame(width: 300)
            .alert("Notification Permission Required", isPresented: $showNotificationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    hydrationManager.logUserAction(action: "Open System Notifications Settings")
                    // Open system settings app
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable notifications for the Hydrate app in System Settings to receive hydration reminders.")
            }
        }
    }
} 