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
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var selectedTab: Int
    @State private var selectedTimeRange: TimeRange = .allTime
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    enum TimeRange: String, CaseIterable {
        case currentMonth = "Tento měsíc"
        case lastMonth = "Minulý měsíc"
        case last3Months = "Poslední 3 měsíce"
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
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Period Stats based on selected time range
                    VStack(spacing: 20) {
                        Text("\(localizationManager.localizedString("periodStats")) \(selectedTimeRange.rawValue.lowercased())")
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
                                value: String(format: "%.0f", periodStats.totalKilometers),
                                icon: "speedometer",
                                color: DesignSystem.Colors.secondary
                            )
                            
                            StatCard(
                                title: "Výdaje za palivo",
                                value: String(format: "%.0f Kč", periodStats.totalFuelCost),
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
                        Text(localizationManager.localizedString("monthlyOverview"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if filteredReports.isEmpty {
                            EmptyState(
                                icon: "chart.bar",
                                title: localizationManager.localizedString("noDataForPeriod")
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
                .padding(.vertical)
            }
            .navigationTitle("Statistiky")
            .navigationBarTitleDisplayMode(.inline)
    }
}


struct MonthlyStatRow: View {
    let report: MonthlyReport
    @ObservedObject var viewModel: MechanicViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
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
    
    // Get fuel cost for this month
    private var monthlyFuelCost: Double {
        let calendar = Calendar.current
        return viewModel.fuelEntries.filter { entry in
            calendar.isDate(entry.date, equalTo: report.month, toGranularity: .month)
        }.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Month info
            VStack(alignment: .leading, spacing: 2) {
                Text(report.month.formatted(.dateTime.month().year()))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(formatDays(report.workDays.count))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // Stats in a grid layout
            HStack(spacing: 20) {
                // Hours
                VStack(alignment: .trailing, spacing: 2) {
                    Text(report.totalHours.formattedTime(useTimePicker: useTimePicker))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    
                    Text(localizationManager.localizedString("hours"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // Kilometers
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(report.totalKilometers))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    
                    Text(localizationManager.localizedString("km"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                // Fuel cost
                VStack(alignment: .trailing, spacing: 2) {
                    if monthlyFuelCost > 0 {
                        Text("\(Int(monthlyFuelCost))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                        
                        Text(localizationManager.localizedString("currency"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(localizationManager.localizedString("dash"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Text(localizationManager.localizedString("currency"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
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
