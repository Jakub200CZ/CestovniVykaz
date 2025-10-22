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
        
        // Nastavit čas na zadaný čas každý den (pouze pracovní dny)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = 2 // Pondělí
        dateComponents.weekdayOrdinal = 1 // První pondělí v týdnu
        
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
                print("Daily reminder scheduled for \(hour):\(String(format: "%02d", minute)) (weekdays only)")
            }
        }
        
        // Přidat notifikace pro všechny pracovní dny (úterý-pátek)
        for weekday in 3...6 { // 3 = úterý, 4 = středa, 5 = čtvrtek, 6 = pátek
            var weekdayComponents = DateComponents()
            weekdayComponents.hour = hour
            weekdayComponents.minute = minute
            weekdayComponents.weekday = weekday
            
            let weekdayTrigger = UNCalendarNotificationTrigger(
                dateMatching: weekdayComponents,
                repeats: true
            )
            
            let weekdayRequest = UNNotificationRequest(
                identifier: "dailyReminder_\(weekday)",
                content: content,
                trigger: weekdayTrigger
            )
            
            UNUserNotificationCenter.current().add(weekdayRequest) { error in
                if let error = error {
                    print("Error scheduling weekday notification: \(error)")
                } else {
                    print("Weekday reminder scheduled for weekday \(weekday)")
                }
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
