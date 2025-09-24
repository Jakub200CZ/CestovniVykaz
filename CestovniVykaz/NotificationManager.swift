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
    
    func scheduleDailyReminder() {
        guard isAuthorized else { return }
        
        // Zrušit existující notifikace
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Vytvořit obsah notifikace
        let content = UNMutableNotificationContent()
        content.title = "Cestovní výkaz"
        content.body = "Nezapomeňte vyplnit výkaz za dnešní den!"
        content.sound = .default
        content.badge = 1
        
        // Nastavit čas na 20:00 každý den
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
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
                print("Daily reminder scheduled successfully")
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
    
    func scheduleTestNotification() {
        guard isAuthorized else { return }
        
        // Vytvořit obsah test notifikace
        let content = UNMutableNotificationContent()
        content.title = "Cestovní výkaz"
        content.body = "Nezapomeňte vyplnit výkaz za dnešní den!"
        content.sound = .default
        content.badge = 1
        
        // Nastavit trigger na 15 sekund
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 15,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "testNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling test notification: \(error)")
            } else {
                print("Test notification scheduled successfully")
            }
        }
    }
}
