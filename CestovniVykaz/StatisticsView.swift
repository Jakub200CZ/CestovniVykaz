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
    @State private var animateContent = false
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Stats based on selected time range
                    VStack(spacing: 20) {
                        Text("\(localizationManager.localizedString("periodStats")) \(selectedTimeRange.rawValue.lowercased())")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateContent)
                        
                        HStack(spacing: 8) {
                            OverallStatCard(
                                title: "Celkem hodin",
                                value: String(format: "%.1f", periodStats.totalHours),
                                icon: "clock.fill",
                                color: .blue
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : -30)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                            
                            OverallStatCard(
                                title: "Celkem km",
                                value: String(format: "%.0f", periodStats.totalKilometers),
                                icon: "speedometer",
                                color: .green
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                            
                            OverallStatCard(
                                title: "Výdaje za palivo",
                                value: String(format: "%.0f Kč", periodStats.totalFuelCost),
                                icon: "fuelpump.fill",
                                color: .orange
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
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
                            VStack(spacing: 8) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.secondary)
                                
                                Text(localizationManager.localizedString("noDataForPeriod"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                            .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(filteredReports.sorted { $0.month > $1.month }, id: \.month) { report in
                                    MonthlyStatRow(report: report, viewModel: viewModel)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistiky")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // NavigationStack will handle going back
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
}

struct OverallStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct MonthlyStatRow: View {
    let report: MonthlyReport
    @ObservedObject var viewModel: MechanicViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    
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
                    Text("\(report.totalHours, specifier: "%.1f")")
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