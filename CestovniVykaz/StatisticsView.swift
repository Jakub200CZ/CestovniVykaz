//
//  StatisticsView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

// MARK: - Statistics View
struct StatisticsView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @State private var selectedTimeRange: TimeRange = .allTime
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    enum TimeRange: String, CaseIterable {
        case currentMonth = "Tento"
        case lastMonth = "Minulý"
        case last3Months = "Poslední 3"
        case allTime = "Celkově"
    }
    
    var filteredReports: [MonthlyReport] {
        let calendar = Calendar.current
        let now = Date()
        
        let baseReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty } // Filtrovat prázdné měsíce
        
        switch selectedTimeRange {
        case .currentMonth:
            return baseReports.filter { report in
                calendar.isDate(report.month, equalTo: now, toGranularity: .month)
            }
        case .lastMonth:
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                return baseReports.filter { report in
                    calendar.isDate(report.month, equalTo: lastMonth, toGranularity: .month)
                }
            }
            return []
        case .last3Months:
            return baseReports.filter { report in
                let monthsAgo = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: monthsAgo) ?? now
                return report.month > threeMonthsAgo && report.month < monthsAgo
            }
        case .allTime:
            return baseReports
        }
    }
    
    var periodStats: (totalHours: Double, totalKilometers: Double, totalFuelCost: Double) {
        let totalHours = filteredReports.reduce(0) { $0 + $1.totalHours }
        let totalKilometers = filteredReports.reduce(0) { $0 + $1.totalKilometers }
        
        // Calculate fuel costs for the selected period
        let calendar = Calendar.current
        let now = Date()
        let filteredFuelEntries: [FuelEntry]
        
        switch selectedTimeRange {
        case .currentMonth:
            filteredFuelEntries = viewModel.fuelEntries.filter { entry in
                calendar.isDate(entry.date, equalTo: now, toGranularity: .month)
            }
        case .lastMonth:
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredFuelEntries = viewModel.fuelEntries.filter { entry in
                    calendar.isDate(entry.date, equalTo: lastMonth, toGranularity: .month)
                }
            } else {
                filteredFuelEntries = []
            }
        case .last3Months:
            let monthsAgo = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: monthsAgo) ?? now
            filteredFuelEntries = viewModel.fuelEntries.filter { entry in
                entry.date > threeMonthsAgo && entry.date < monthsAgo
            }
        case .allTime:
            filteredFuelEntries = viewModel.fuelEntries
        }
        
        let totalFuelCost = filteredFuelEntries.reduce(0) { $0 + $1.price }
        
        return (totalHours, totalKilometers, totalFuelCost)
    }
    
    // Formátování kilometrů pro lepší čitelnost
    private func formatKilometers(_ kilometers: Double) -> String {
        if kilometers >= 1000 {
            return String(format: "%.1fK", kilometers / 1000)
        } else {
            return String(format: "%.0f", kilometers)
        }
    }
    
    // Formátování měny pro lepší čitelnost
    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fK", amount / 1000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Period Stats based on selected time range
                    VStack(spacing: 20) {
                        Text("Statistiky za \(selectedTimeRange.rawValue.lowercased())")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            StatCard(
                                title: "Celkem hodin",
                                value: periodStats.totalHours.formattedTime(useTimePicker: useTimePicker),
                                icon: "clock.fill",
                                color: DesignSystem.Colors.primary
                            )
                            
                            StatCard(
                                title: "Celkem km",
                                value: formatKilometers(periodStats.totalKilometers),
                                icon: "speedometer",
                                color: DesignSystem.Colors.secondary
                            )
                            
                            StatCard(
                                title: "Palivo",
                                value: "\(formatCurrency(periodStats.totalFuelCost)) Kč",
                                icon: "fuelpump.fill",
                                color: DesignSystem.Colors.accent
                            )
                        }
                    }
                    .cardStyleSecondary()
                    .padding(.horizontal)
                    
                    // Time Range Selector
                    Picker("Časové období", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Monthly Stats
                    VStack(spacing: 16) {
                        Text("Měsíční přehled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if filteredReports.isEmpty {
                            EmptyState(
                                icon: "chart.bar",
                                title: "Žádná data pro vybrané období"
                            )
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(filteredReports.sorted { $0.month > $1.month }, id: \.month) { report in
                                    MonthlyStatRow(report: report, viewModel: viewModel)
                                }
                            }
                        }
                    }
                    .cardStyleSecondary()
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                .padding(.bottom)
            }
            .navigationTitle("Statistiky")
            .navigationBarTitleDisplayMode(.inline)
    }
}


struct MonthlyStatRow: View {
    let report: MonthlyReport
    @ObservedObject var viewModel: MechanicViewModel
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    // Správné skloňování "dny" v češtině
    private func formatDays(_ count: Int) -> String {
        switch count {
        case 1:
            return "1 den"
        case 2...4:
            return "\(count) dny"
        default:
            return "\(count) dnů"
        }
    }
    
    // Formátování měsíců v češtině
    private func formatMonthYear(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let monthNames = [
            "leden", "únor", "březen", "duben", "květen", "červen",
            "červenec", "srpen", "září", "říjen", "listopad", "prosinec"
        ]
        
        return "\(monthNames[month - 1]) \(year)"
    }
    
    // Get fuel cost for this month
    private var monthlyFuelCost: Double {
        let calendar = Calendar.current
        return viewModel.fuelEntries.filter { entry in
            calendar.isDate(entry.date, equalTo: report.month, toGranularity: .month)
        }.reduce(0) { $0 + $1.price }
    }
    
    // Formátování kilometrů pro lepší čitelnost
    private func formatKilometers(_ kilometers: Double) -> String {
        if kilometers >= 1000 {
            return String(format: "%.1fK", kilometers / 1000)
        } else {
            return String(format: "%.0f", kilometers)
        }
    }
    
    // Formátování měny pro lepší čitelnost
    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "%.1fK", amount / 1000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Month info
            VStack(alignment: .leading, spacing: 2) {
                Text(formatMonthYear(report.month))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(formatDays(report.workDays.count))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // Stats in a grid layout - 3 columns (removed work days)
            HStack(spacing: 20) {
                // Hours
                VStack(alignment: .trailing, spacing: 2) {
                    Text(report.totalHours.formattedTime(useTimePicker: useTimePicker))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text("Hodin")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Kilometers
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatKilometers(report.totalKilometers))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text("Km")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Fuel cost
                VStack(alignment: .trailing, spacing: 2) {
                    if monthlyFuelCost > 0 {
                        Text(formatCurrency(monthlyFuelCost))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("Kč")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("-")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        
                        Text("Kč")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
        )
    }
} 
