//
//  MechanicViewModel.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

// MARK: - ViewModel
@MainActor
class MechanicViewModel: ObservableObject {
    @Published var monthlyReports: [MonthlyReport] = []
    @Published var currentMonthReport: MonthlyReport?
    @Published var fuelEntries: [FuelEntry] = []
    @Published var customers: [Customer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let notificationManager = NotificationManager.shared
    private let widgetDataManager = WidgetDataManager.shared
    
    private let userDefaults = UserDefaults.standard
    private let monthlyReportsKey = "monthlyReports"
    private let fuelEntriesKey = "fuelEntries"
    private let customersKey = "customers"
    
    init() {
        // Načíst data přímo na main thread pro rychlejší start
        monthlyReports = loadMonthlyReportsBackground()
        fuelEntries = loadFuelEntriesBackground()
        customers = loadCustomersBackground()
        setupCurrentMonth()
        updateWidgetData()
    }
    
    func loadMonthlyReports() {
        if let data = userDefaults.data(forKey: monthlyReportsKey) {
            if let reports = try? JSONDecoder().decode([MonthlyReport].self, from: data) {
                monthlyReports = reports
            } else {
                monthlyReports = []
            }
        } else {
            monthlyReports = []
        }
    }
    
    // Načítání dat na pozadí bez aktualizace @Published properties
    nonisolated private func loadMonthlyReportsBackground() -> [MonthlyReport] {
        let localUserDefaults = UserDefaults.standard
        if let data = localUserDefaults.data(forKey: monthlyReportsKey) {
            if let decodedReports = try? JSONDecoder().decode([MonthlyReport].self, from: data) {
                return decodedReports
            }
        }
        return []
    }
    
    func saveMonthlyReports() {
        if let data = try? JSONEncoder().encode(monthlyReports) {
            userDefaults.set(data, forKey: monthlyReportsKey)
        }
    }
    
    func setupCurrentMonth() {
        let calendar = Calendar.current
        let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        // Najít existující report pro aktuální měsíc
        if let existingReport = monthlyReports.first(where: { report in
            calendar.isDate(report.month, equalTo: currentMonth, toGranularity: .month)
        }) {
            currentMonthReport = existingReport
        } else {
            // Vytvořit nový report pouze pokud neexistuje žádný pro aktuální měsíc
            let newReport = MonthlyReport(month: currentMonth)
            currentMonthReport = newReport
            monthlyReports.append(newReport)
            saveMonthlyReports()
        }
    }
    
    var currentMonthStats: (drivingHours: Double, workingHours: Double, kilometers: Double) {
        let calendar = Calendar.current
        let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        // Použít currentMonthReport pokud existuje
        if let currentReport = currentMonthReport {
            let totalDrivingHours = currentReport.workDays.reduce(0) { $0 + $1.drivingHours }
            let totalWorkingHours = currentReport.workDays.reduce(0) { $0 + $1.workingHours }
            let totalKilometers = currentReport.workDays.reduce(0) { $0 + $1.kilometers }
            
            return (totalDrivingHours, totalWorkingHours, totalKilometers)
        }
        
        // Fallback: Najít aktuální měsíc v monthlyReports
        if let currentReport = monthlyReports.first(where: { report in
            calendar.isDate(report.month, equalTo: currentMonth, toGranularity: .month)
        }) {
            let totalDrivingHours = currentReport.workDays.reduce(0) { $0 + $1.drivingHours }
            let totalWorkingHours = currentReport.workDays.reduce(0) { $0 + $1.workingHours }
            let totalKilometers = currentReport.workDays.reduce(0) { $0 + $1.kilometers }
            
            return (totalDrivingHours, totalWorkingHours, totalKilometers)
        }
        
        return (0, 0, 0)
    }
    
    func addWorkDay(_ workDay: WorkDay) {
        let calendar = Calendar.current
        let workDayMonth = calendar.dateInterval(of: .month, for: workDay.date)?.start ?? workDay.date
        
        // Find or create monthly report for the work day's month
        if let existingReportIndex = monthlyReports.firstIndex(where: { report in
            calendar.isDate(report.month, equalTo: workDayMonth, toGranularity: .month)
        }) {
            // Add work day to existing report
            monthlyReports[existingReportIndex].workDays.append(workDay)
            
            // Update current month report if this is the current month
            let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            if calendar.isDate(workDayMonth, equalTo: currentMonth, toGranularity: .month) {
                currentMonthReport = monthlyReports[existingReportIndex]
            }
        } else {
            // Create new monthly report
            var newReport = MonthlyReport(month: workDayMonth)
            newReport.workDays.append(workDay)
            monthlyReports.append(newReport)
            
            // Update current month report if this is the current month
            let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            if calendar.isDate(workDayMonth, equalTo: currentMonth, toGranularity: .month) {
                currentMonthReport = newReport
            }
        }
        
        saveMonthlyReports()
        
        // Aktualizovat currentMonthReport
        setupCurrentMonth()
        
        // Aktualizovat widget data
        updateWidgetData()
    }
    
    func updateWorkDay(_ workDay: WorkDay) {
        let calendar = Calendar.current
        let workDayMonth = calendar.dateInterval(of: .month, for: workDay.date)?.start ?? workDay.date


        // First, find the work day in any report by its ID
        var foundWorkDay: WorkDay?
        var sourceReportIndex: Int?
        var sourceWorkDayIndex: Int?

        for (reportIndex, monthlyReport) in monthlyReports.enumerated() {
            if let workDayIndex = monthlyReport.workDays.firstIndex(where: { $0.id == workDay.id }) {
                foundWorkDay = monthlyReport.workDays[workDayIndex]
                sourceReportIndex = reportIndex
                sourceWorkDayIndex = workDayIndex
                break
            }
        }

        guard let foundWorkDay = foundWorkDay,
              let sourceReportIndex = sourceReportIndex,
              let sourceWorkDayIndex = sourceWorkDayIndex else {
            return
        }

        // Check if the month has changed
        let originalMonth = calendar.dateInterval(of: .month, for: foundWorkDay.date)?.start ?? foundWorkDay.date
        let newMonth = calendar.dateInterval(of: .month, for: workDay.date)?.start ?? workDay.date
        let monthChanged = !calendar.isDate(originalMonth, equalTo: newMonth, toGranularity: .month)


        if monthChanged {
            // Remove work day from source report
            var sourceReport = monthlyReports[sourceReportIndex]
            sourceReport.workDays.remove(at: sourceWorkDayIndex)
            
            // Remove empty month
            if sourceReport.workDays.isEmpty {
                monthlyReports.remove(at: sourceReportIndex)
            } else {
                monthlyReports[sourceReportIndex] = sourceReport
            }

            // Find or create target report for the new month
            var targetReport: MonthlyReport
            var targetReportIndex: Int

            if let existingTargetIndex = monthlyReports.firstIndex(where: { report in
                calendar.isDate(report.month, equalTo: workDayMonth, toGranularity: .month)
            }) {
                targetReport = monthlyReports[existingTargetIndex]
                targetReportIndex = existingTargetIndex
            } else {
                targetReport = MonthlyReport(month: workDayMonth)
                monthlyReports.append(targetReport)
                targetReportIndex = monthlyReports.count - 1
            }

            // Add updated work day to target report
            targetReport.workDays.append(workDay)
            monthlyReports[targetReportIndex] = targetReport
            
            // Update current month report if this is the current month
            let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            if calendar.isDate(workDayMonth, equalTo: currentMonth, toGranularity: .month) {
                currentMonthReport = targetReport
            }
        } else {
            // Update work day in place (same month)
            var sourceReport = monthlyReports[sourceReportIndex]
            sourceReport.workDays[sourceWorkDayIndex] = workDay
            monthlyReports[sourceReportIndex] = sourceReport
            // Update current month report if this is the current month
            let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            if calendar.isDate(workDayMonth, equalTo: currentMonth, toGranularity: .month) {
                currentMonthReport = sourceReport
            }
        }

        saveMonthlyReports()
        
        // Aktualizovat currentMonthReport
        setupCurrentMonth()
    }
    
    func updateWorkDay(_ workDay: WorkDay, in report: MonthlyReport) {
        if let reportIndex = monthlyReports.firstIndex(where: { $0.id == report.id }),
           let workDayIndex = monthlyReports[reportIndex].workDays.firstIndex(where: { $0.id == workDay.id }) {
            monthlyReports[reportIndex].workDays[workDayIndex] = workDay
            
            // Update current month report if this is the current month
            let calendar = Calendar.current
            let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            if calendar.isDate(report.month, equalTo: currentMonth, toGranularity: .month) {
                currentMonthReport = monthlyReports[reportIndex]
            }
            
            saveMonthlyReports()
            
            // Aktualizovat currentMonthReport
            setupCurrentMonth()
            
            // Aktualizovat widget data
            updateWidgetData()
        }
    }
    
    func deleteWorkDay(_ workDay: WorkDay, from report: MonthlyReport) {
        if let reportIndex = monthlyReports.firstIndex(where: { $0.id == report.id }),
           let workDayIndex = monthlyReports[reportIndex].workDays.firstIndex(where: { $0.id == workDay.id }) {
            monthlyReports[reportIndex].workDays.remove(at: workDayIndex)
            
            // Update current month report if this is the current month
            let calendar = Calendar.current
            let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            if calendar.isDate(report.month, equalTo: currentMonth, toGranularity: .month) {
                currentMonthReport = monthlyReports[reportIndex]
            }
            
            saveMonthlyReports()
            
            // Aktualizovat currentMonthReport
            setupCurrentMonth()
            
            // Aktualizovat widget data
            updateWidgetData()
        }
    }
    
    
    func clearAllData() {
        monthlyReports = []
        currentMonthReport = nil
        fuelEntries = []
        customers = []
        userDefaults.removeObject(forKey: monthlyReportsKey)
        userDefaults.removeObject(forKey: fuelEntriesKey)
        userDefaults.removeObject(forKey: customersKey)
        setupCurrentMonth()
    }
    
    func generateTestData() {
        clearAllData()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate data for last 3 months
        for monthOffset in 1...3 {
            if let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) {
                let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
                var monthlyReport = MonthlyReport(month: monthStart)
                
                // Generate work days for this month
                let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<29
                var workDaysCount = 0
                var vacationDaysCount = 0
                var sickDaysCount = 0
                
                for day in range {
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                        let weekday = calendar.component(.weekday, from: date)
                        // Only add work days (Monday-Friday)
                        if weekday != 1 && weekday != 7 { // 1 = Sunday, 7 = Saturday
                            workDaysCount += 1
                            
                            // 1 den dovolené a 1 den lékaře za měsíc
                            if vacationDaysCount < 1 && Double.random(in: 0...1) < 0.1 {
                                let vacationDay = WorkDay(
                                    date: date,
                                    drivingHours: 0.0,
                                    workingHours: 0.0,
                                    kilometers: 0.0,
                                    city: "",
                                    notes: "Dovolená",
                                    isCompleted: true,
                                    dayType: .vacation
                                )
                                monthlyReport.workDays.append(vacationDay)
                                vacationDaysCount += 1
                            } else if sickDaysCount < 1 && Double.random(in: 0...1) < 0.1 {
                                let sickDay = WorkDay(
                                    date: date,
                                    drivingHours: 0.0,
                                    workingHours: 0.0,
                                    kilometers: 0.0,
                                    city: "",
                                    notes: "Nemoc / Lékař",
                                    isCompleted: true,
                                    dayType: .sick
                                )
                                monthlyReport.workDays.append(sickDay)
                                sickDaysCount += 1
                            } else {
                                // Normální pracovní den
                                let workDay = generateRealisticWorkDay(for: date)
                                monthlyReport.workDays.append(workDay)
                            }
                        }
                    }
                }
                
                // Only add month if it has work days
                if !monthlyReport.workDays.isEmpty {
                    monthlyReports.append(monthlyReport)
                }
            }
        }
        
        saveMonthlyReports()
        
        // Reload data to ensure consistency - na main thread
        DispatchQueue.main.async {
            self.loadMonthlyReports()
            self.setupCurrentMonth()
        }
    }
    
    private func generateRealisticWorkDay(for date: Date) -> WorkDay {
        // 5% šance na dovolenou, 3% šance na nemoc
        let randomValue = Double.random(in: 0...1)
        if randomValue < 0.05 {
            return WorkDay(
                date: date,
                drivingHours: 0.0,
                workingHours: 0.0,
                kilometers: 0.0,
                city: "",
                notes: "Dovolená",
                isCompleted: true,
                dayType: .vacation
            )
        } else if randomValue < 0.08 {
            return WorkDay(
                date: date,
                drivingHours: 0.0,
                workingHours: 0.0,
                kilometers: 0.0,
                city: "",
                notes: "Nemoc / Lékař",
                isCompleted: true,
                dayType: .sick
            )
        }
        
        // Celkové hodiny: 180-220h rozdělit na měsíc (cca 20 pracovních dnů) = 9-11h denně
        let totalHours = Double.random(in: 9...11)
        
        // 80% práce, 20% jízda
        let workingHours = totalHours * 0.8
        let drivingHours = totalHours * 0.2
        
        // Kilometry: průměrná rychlost 70km/h * hodiny jízdy
        let kilometers = drivingHours * 70
        
        // Náhodné město z ČR
        let cities = [
            "Praha", "Brno", "Ostrava", "Plzeň", "Liberec", "Olomouc", "Ústí nad Labem",
            "České Budějovice", "Hradec Králové", "Pardubice", "Zlín", "Havířov",
            "Karlovy Vary", "Jablonec nad Nisou", "Mladá Boleslav", "Český Krumlov",
            "Kutná Hora", "Telč", "Třebíč", "Znojmo", "Tábor", "Písek", "Strakonice",
            "Prachatice", "Vimperk", "Příbram", "Benešov", "Kolín", "Nymburk", "Mělník",
            "Kralupy nad Vltavou", "Beroun", "Rakovník", "Kladno", "Slaný", "Louny",
            "Žatec", "Chomutov", "Most", "Litvínov", "Děčín", "Rumburk", "Varnsdorf",
            "Turnov", "Semily", "Jilemnice", "Trutnov", "Vrchlabí", "Jičín", "Náchod",
            "Rychnov nad Kněžnou", "Chrudim", "Svitavy", "Ústí nad Orlicí", "Prostějov",
            "Přerov", "Hranice", "Šumperk", "Zábřeh", "Jeseník", "Opava", "Kravaře",
            "Hlučín", "Karvina", "Český Těšín", "Frýdek-Místek", "Frýdlant nad Ostravicí",
            "Kopřivnice", "Nový Jičín", "Bílovec", "Fulnek", "Klimkovice", "Bohumín",
            "Orlová", "Petřvald", "Rychvald", "Stonava", "Třinec", "Jablunkov"
        ]
        
        let randomCity = cities.randomElement() ?? "Praha"
        
        // Náhodné poznámky
        let notes = [
            "Oprava klimatizace", "Výměna oleje", "Kontrola brzd", "Oprava motoru",
            "Výměna filtrů", "Kontrola elektroinstalace", "Oprava převodovky", "Výměna svíček",
            "Kontrola tlaku v pneumatikách", "Oprava startéru", "Výměna baterie", "Kontrola světel",
            "Oprava topení", "Výměna kapalin", "Kontrola výfuku", "Oprava řízení",
            "Výměna řemenů", "Kontrola spojky", "Oprava brzd", "Výměna pneumatik"
        ]
        
        let randomNote = notes.randomElement() ?? "Oprava vozidla"
        
        return WorkDay(
            date: date,
            drivingHours: drivingHours,
            workingHours: workingHours,
            kilometers: kilometers,
            city: randomCity,
            notes: randomNote,
            isCompleted: true,
            dayType: .work
        )
    }
    
    // MARK: - Fuel Management
    func loadFuelEntries() {
        if let data = userDefaults.data(forKey: fuelEntriesKey) {
            if let entries = try? JSONDecoder().decode([FuelEntry].self, from: data) {
                fuelEntries = entries.sorted { $0.date > $1.date }
            } else {
                fuelEntries = []
            }
        } else {
            fuelEntries = []
        }
    }
    
    nonisolated private func loadFuelEntriesBackground() -> [FuelEntry] {
        let localUserDefaults = UserDefaults.standard
        if let data = localUserDefaults.data(forKey: fuelEntriesKey) {
            if let decodedEntries = try? JSONDecoder().decode([FuelEntry].self, from: data) {
                return decodedEntries.sorted { $0.date > $1.date }
            }
        }
        return []
    }
    
    func saveFuelEntries() {
        if let data = try? JSONEncoder().encode(fuelEntries) {
            userDefaults.set(data, forKey: fuelEntriesKey)
        }
    }
    
    func addFuelEntry(_ fuelEntry: FuelEntry) {
        fuelEntries.append(fuelEntry)
        fuelEntries.sort { $0.date > $1.date }
        saveFuelEntries()
    }
    
    func updateFuelEntry(_ fuelEntry: FuelEntry) {
        if let index = fuelEntries.firstIndex(where: { $0.id == fuelEntry.id }) {
            fuelEntries[index] = fuelEntry
            fuelEntries.sort { $0.date > $1.date }
            saveFuelEntries()
        }
    }
    
    func deleteFuelEntry(_ fuelEntry: FuelEntry) {
        fuelEntries.removeAll { $0.id == fuelEntry.id }
        saveFuelEntries()
    }
    
    // Computed properties pro statistiky tankování
    var totalFuelAmount: Double {
        fuelEntries.reduce(0) { $0 + $1.fuelAmount }
    }
    
    var totalFuelCost: Double {
        fuelEntries.reduce(0) { $0 + $1.price }
    }
    
    var averagePricePerLiter: Double {
        let totalAmount = totalFuelAmount
        return totalAmount > 0 ? totalFuelCost / totalAmount : 0
    }
    
    var fuelEntriesThisMonth: [FuelEntry] {
        let calendar = Calendar.current
        let currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        return fuelEntries.filter { entry in
            calendar.isDate(entry.date, equalTo: currentMonth, toGranularity: .month)
        }
    }
    
    var monthlyFuelCost: Double {
        fuelEntriesThisMonth.reduce(0) { $0 + $1.price }
    }
    
    var monthlyFuelAmount: Double {
        fuelEntriesThisMonth.reduce(0) { $0 + $1.fuelAmount }
    }
    
    // MARK: - Customer Management
    
    func loadCustomers() {
        customers = loadCustomersBackground()
    }
    
    nonisolated private func loadCustomersBackground() -> [Customer] {
        let localUserDefaults = UserDefaults.standard
        if let data = localUserDefaults.data(forKey: customersKey),
           let decodedCustomers = try? JSONDecoder().decode([Customer].self, from: data) {
            return decodedCustomers
        }
        return []
    }
    
    func saveCustomers() {
        guard let data = try? JSONEncoder().encode(customers) else { return }
        userDefaults.set(data, forKey: customersKey)
    }
    
    func addCustomer(_ customer: Customer) {
        customers.append(customer)
        saveCustomers()
    }
    
    func updateCustomer(_ customer: Customer) {
        if let index = customers.firstIndex(where: { $0.id == customer.id }) {
            customers[index] = customer
            saveCustomers()
        }
    }
    
    func deleteCustomer(_ customer: Customer) {
        customers.removeAll { $0.id == customer.id }
        saveCustomers()
    }
    
    // MARK: - Notification Support
    
    func checkIfWorkDayCompleted(for date: Date) -> Bool {
        let calendar = Calendar.current
        
        // Kontrola, zda je datum pracovní den
        let weekday = calendar.component(.weekday, from: date)
        guard weekday != 1 && weekday != 7 else { return true } // Víkendy
        
        // Kontrola, zda existuje záznam pro dané datum
        let baseReports = monthlyReports.filter { !$0.workDays.isEmpty }
        
        return baseReports.contains { report in
            report.workDays.contains { workDay in
                calendar.isDate(workDay.date, inSameDayAs: date)
            }
        }
    }
    
    func scheduleNotificationsIfNeeded() {
        Task {
            await notificationManager.requestPermission()
            if notificationManager.isAuthorized {
                notificationManager.scheduleDailyReminder()
            }
        }
    }
    
    // MARK: - Debug Functions
    func generateCurrentMonthData() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Generovat data pouze pro aktuální měsíc
        let workDays = generateWorkDaysForMonth(currentMonth)
        
        // Přidat do existujícího reportu nebo vytvořit nový
        if let existingReportIndex = monthlyReports.firstIndex(where: { 
            calendar.isDate($0.month, equalTo: currentMonth, toGranularity: .month) 
        }) {
            // Přidat k existujícímu reportu
            monthlyReports[existingReportIndex].workDays.append(contentsOf: workDays)
        } else {
            // Vytvořit nový report
            var newReport = MonthlyReport(month: currentMonth)
            newReport.workDays = workDays
            monthlyReports.append(newReport)
        }
        
        saveMonthlyReports()
    }
    
    private func generateWorkDaysForMonth(_ month: Date) -> [WorkDay] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<29
        let monthComponent = calendar.component(.month, from: month)
        let yearComponent = calendar.component(.year, from: month)
        
        var workDays: [WorkDay] = []
        
        for day in range {
            var comps = DateComponents()
            comps.year = yearComponent
            comps.month = monthComponent
            comps.day = day
            
            if let date = calendar.date(from: comps) {
                // Pouze pracovní dny (pondělí-pátek)
                if calendar.component(.weekday, from: date) >= 2 && calendar.component(.weekday, from: date) <= 6 {
                    let workDay = generateRealisticWorkDay(for: date)
                    workDays.append(workDay)
                }
            }
        }
        
        return workDays
    }
    
    // MARK: - Widget Data Management
    func updateWidgetData() {
        guard let currentReport = currentMonthReport else { 
            return 
        }
        
        let totalHours = currentReport.totalHours
        let totalKilometers = currentReport.totalKilometers
        let fuelCosts = monthlyFuelCost  // Použít stejnou hodnotu jako v aplikaci
        
        widgetDataManager.saveWidgetData(
            totalHours: totalHours,
            totalKilometers: totalKilometers,
            totalEarnings: fuelCosts  // Změněno z calculateEarnings na fuelCosts
        )
    }
} 