import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.eu.jakubsedlacek.CestovniVykaz.widget")
    
    private init() {}
    
    // MARK: - Data Keys
    private let totalHoursKey = "widget_total_hours"
    private let totalKilometersKey = "widget_total_kilometers"
    private let totalEarningsKey = "widget_total_earnings"
    private let lastUpdatedKey = "widget_last_updated"
    
    // MARK: - Save Data
    func saveWidgetData(totalHours: Double, totalKilometers: Double, totalEarnings: Double) {
        userDefaults?.set(totalHours, forKey: totalHoursKey)
        userDefaults?.set(totalKilometers, forKey: totalKilometersKey)
        userDefaults?.set(totalEarnings, forKey: totalEarningsKey)
        userDefaults?.set(Date(), forKey: lastUpdatedKey)
        
        // Update widget timeline
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Load Data
    func getTotalHours() -> Double {
        let value = userDefaults?.double(forKey: totalHoursKey) ?? 0.0
        print("DEBUG: WidgetDataManager - Loading Total Hours: \(value)")
        return value
    }
    
    func getTotalKilometers() -> Double {
        let value = userDefaults?.double(forKey: totalKilometersKey) ?? 0.0
        print("DEBUG: WidgetDataManager - Loading Total Kilometers: \(value)")
        return value
    }
    
    func getTotalEarnings() -> Double {
        let value = userDefaults?.double(forKey: totalEarningsKey) ?? 0.0
        print("DEBUG: WidgetDataManager - Loading Fuel Costs: \(value)")
        return value
    }
    
    func getLastUpdated() -> Date {
        return userDefaults?.object(forKey: lastUpdatedKey) as? Date ?? Date()
    }
}
