//
//  NotificationManager.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import UserNotifications
import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        // Inicializovat properties před voláním metod
        self.isAuthorized = false
        self.authorizationStatus = .notDetermined
        checkAuthorizationStatus()
    }
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.updateAuthorizationStatus()
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func updateAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func scheduleDailyReminder(at hour: Int = 20, minute: Int = 0) {
        guard isAuthorized else { return }
        
        // Zrušit existující notifikace
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Vytvořit obsah notifikace
        let content = UNMutableNotificationContent()
        content.title = "Cestovní výkaz"
        content.body = "Nezapomeňte vyplnit výkaz za dnešní den!"
        content.sound = .default
        content.badge = nil
        
        // Nastavit čas na zadaný čas každý den
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Daily reminder cancelled")
    }
    
    func checkIfWorkDayCompleted(for date: Date, viewModel: MechanicViewModel) -> Bool {
        return viewModel.checkIfWorkDayCompleted(for: date)
    }
}
