//
//  Models.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import Foundation
import SwiftUI

// MARK: - String Extension for Number Conversion
extension String {
    /// Converts comma decimal separator to dot for proper Double conversion
    func normalizedForDouble() -> String {
        return self.replacingOccurrences(of: ",", with: ".")
    }
    
    /// Converts string to Double, handling both comma and dot decimal separators
    func toDouble() -> Double? {
        return Double(self.normalizedForDouble())
    }
}

// MARK: - Time Formatting Extension
extension Double {
    /// Formats time based on user's preference (decimal or time picker format)
    func formattedTime(useTimePicker: Bool) -> String {
        if useTimePicker {
            // Format as HH:MM - převést na celé minuty a pak na HH:MM bez zaokrouhlování
            let totalMinutes = Int(self * 60) // Převést na celé minuty
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return String(format: "%d:%02d", hours, minutes)
        } else {
            // Format as decimal
            return String(format: "%.1f", self)
        }
    }
}

// MARK: - Time Input Field Component
struct TimeInputField: View {
    let title: String
    @Binding var textValue: String
    @Binding var timeValue: Date
    let useTimePicker: Bool
    let placeholder: String
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let disabled: Bool
    
    init(title: String, textValue: Binding<String>, timeValue: Binding<Date>, useTimePicker: Bool, placeholder: String = "0.0h", focusedField: FocusState<Field?>.Binding, field: Field, disabled: Bool = false) {
        self.title = title
        self._textValue = textValue
        self._timeValue = timeValue
        self.useTimePicker = useTimePicker
        self.placeholder = placeholder
        self.focusedField = focusedField
        self.field = field
        self.disabled = disabled
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            
            if useTimePicker {
                DatePicker("", selection: $timeValue, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .disabled(disabled)
                    .onChange(of: timeValue) { _, newValue in
                        // Převést čas na desetinné hodiny pro uložení
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.hour, .minute], from: newValue)
                        let hours = Double(components.hour ?? 0)
                        let minutes = Double(components.minute ?? 0)
                        let decimalHours = hours + (minutes / 60.0)
                        textValue = String(format: "%.1f", decimalHours)
                    }
            } else {
                TextField(placeholder, text: $textValue)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .disabled(disabled)
                    .focused(focusedField, equals: field)
                    .onChange(of: textValue) { _, newValue in
                        // Převést desetinné hodiny na čas pro time picker
                        if let decimalHours = newValue.toDouble() {
                            let hours = Int(decimalHours)
                            let minutes = Int((decimalHours - Double(hours)) * 60)
                            let calendar = Calendar.current
                            var components = DateComponents()
                            components.hour = hours
                            components.minute = minutes
                            if let date = calendar.date(from: components) {
                                timeValue = date
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Field Enum for Focus Management
enum Field: Hashable {
    case customerName
    case city
    case kilometers
    case drivingTime
    case drivingHours
    case workingHours
    case notes
}

// MARK: - Day Type Enum
enum DayType: String, Codable, CaseIterable {
    case work = "work"
    case vacation = "vacation"
    case sick = "sick"
    
    var displayName: String {
        switch self {
        case .work:
            return "Pracovní den"
        case .vacation:
            return "Dovolená"
        case .sick:
            return "Nemoc"
        }
    }
    
    var color: String {
        switch self {
        case .work:
            return "green"
        case .vacation:
            return "blue"
        case .sick:
            return "red"
        }
    }
}

// MARK: - Data Models
struct WorkDay: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var customerName: String
    var drivingHours: Double
    var workingHours: Double
    var kilometers: Double
    var city: String
    var notes: String
    var isCompleted: Bool
    var dayType: DayType
    var createdAt: Date
    
    init(date: Date, customerName: String = "", drivingHours: Double = 0.0, workingHours: Double = 0.0, kilometers: Double = 0.0, city: String = "", notes: String = "", isCompleted: Bool = false, dayType: DayType = .work) {
        self.date = date
        self.customerName = customerName
        self.drivingHours = drivingHours
        self.workingHours = workingHours
        self.kilometers = kilometers
        self.city = city
        self.notes = notes
        self.isCompleted = isCompleted
        self.dayType = dayType
        self.createdAt = Date()
    }
    
    // Custom decoder pro kompatibilitu se starými záznamy
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        customerName = try container.decodeIfPresent(String.self, forKey: .customerName) ?? ""
        drivingHours = try container.decode(Double.self, forKey: .drivingHours)
        workingHours = try container.decode(Double.self, forKey: .workingHours)
        kilometers = try container.decode(Double.self, forKey: .kilometers)
        city = try container.decode(String.self, forKey: .city)
        notes = try container.decode(String.self, forKey: .notes)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Pokus o dekódování dayType, pokud neexistuje, použít .work
        if let dayType = try? container.decode(DayType.self, forKey: .dayType) {
            self.dayType = dayType
        } else {
            // Určit typ podle poznámky pro staré záznamy
            if notes.lowercased().contains("dovolená") {
                self.dayType = .vacation
            } else if notes.lowercased().contains("lékař") || notes.lowercased().contains("nemoc") {
                self.dayType = .sick
            } else {
                self.dayType = .work
            }
        }
    }
}

// MARK: - Monthly Report
struct MonthlyReport: Identifiable, Codable {
    var id = UUID()
    var month: Date
    var workDays: [WorkDay]
    var createdAt: Date
    
    init(month: Date) {
        self.month = month
        self.workDays = []
        self.createdAt = Date()
    }
    
    var totalDrivingHours: Double {
        workDays.reduce(0) { $0 + $1.drivingHours }
    }
    
    var totalWorkingHours: Double {
        workDays.reduce(0) { $0 + $1.workingHours }
    }
    
    var totalKilometers: Double {
        workDays.reduce(0) { $0 + $1.kilometers }
    }
    
    var totalHours: Double {
        totalDrivingHours + totalWorkingHours
    }
    
    // Počítání dnů podle typu
    var vacationDays: Int {
        workDays.filter { $0.dayType == .vacation }.count
    }
    
    var sickDays: Int {
        workDays.filter { $0.dayType == .sick }.count
    }
    
    var workingDays: Int {
        workDays.filter { $0.dayType == .work }.count
    }
}

// MARK: - Fuel Type Enum
enum FuelType: String, Codable, CaseIterable {
    case diesel = "diesel"
    case gasoline95 = "gasoline95"
    case gasoline98 = "gasoline98"
    case lpg = "lpg"
    case cng = "cng"
    
    var displayName: String {
        switch self {
        case .diesel:
            return "Diesel"
        case .gasoline95:
            return "Benzín 95"
        case .gasoline98:
            return "Benzín 98"
        case .lpg:
            return "LPG"
        case .cng:
            return "CNG"
        }
    }
    
    var icon: String {
        switch self {
        case .diesel:
            return "fuelpump.fill"
        case .gasoline95:
            return "fuelpump.fill"
        case .gasoline98:
            return "fuelpump.fill"
        case .lpg:
            return "fuelpump.fill"
        case .cng:
            return "fuelpump.fill"
        }
    }
}

// MARK: - Fuel Models
struct FuelEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var fuelAmount: Double // množství paliva v litrech
    var price: Double // celková cena
    var pricePerLiter: Double // cena za litr
    var fuelType: FuelType // druh paliva
    var location: String // místo tankování
    var notes: String // poznámky
    var createdAt: Date
    
    init(date: Date, fuelAmount: Double, price: Double, fuelType: FuelType = .diesel, location: String = "", notes: String = "") {
        self.date = date
        self.fuelAmount = fuelAmount
        self.price = price
        self.pricePerLiter = fuelAmount > 0 ? price / fuelAmount : 0
        self.fuelType = fuelType
        self.location = location
        self.notes = notes
        self.createdAt = Date()
    }
    
    // Computed property pro cenu za litr
    var calculatedPricePerLiter: Double {
        return fuelAmount > 0 ? price / fuelAmount : 0
    }
}

// MARK: - Customer Model
struct Customer: Identifiable, Codable {
    var id = UUID()
    var name: String
    var city: String
    var kilometers: Double
    var drivingTime: Double // in hours
    var createdAt: Date
    
    init(name: String, city: String, kilometers: Double, drivingTime: Double) {
        self.name = name
        self.city = city
        self.kilometers = kilometers
        self.drivingTime = drivingTime
        self.createdAt = Date()
    }
}
