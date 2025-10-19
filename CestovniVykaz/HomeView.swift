//
//  HomeView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    // Computed properties pro aktuální měsíc - stejná logika jako ve StatisticsView
    private var currentMonthReports: [MonthlyReport] {
        let calendar = Calendar.current
        let now = Date()
        
        let baseReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty } // Filtrovat prázdné měsíce
        
        return baseReports.filter { report in
            calendar.isDate(report.month, equalTo: now, toGranularity: .month)
        }
    }
    
    private var currentMonthData: (currentReport: MonthlyReport?, totalDrivingHours: Double, totalWorkingHours: Double, totalKilometers: Double, totalHours: Double, totalWorkDays: Int) {
        let currentReport = currentMonthReports.first
        
        let totalDrivingHours = currentReport?.workDays.reduce(0) { $0 + $1.drivingHours } ?? 0
        let totalWorkingHours = currentReport?.workDays.reduce(0) { $0 + $1.workingHours } ?? 0
        let totalKilometers = currentReport?.workDays.reduce(0) { $0 + $1.kilometers } ?? 0
        let totalHours = totalDrivingHours + totalWorkingHours
        let totalWorkDays = currentReport?.workDays.count ?? 0
        
        return (currentReport, totalDrivingHours, totalWorkingHours, totalKilometers, totalHours, totalWorkDays)
    }
    
    private var currentMonth: Date {
        Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 20) {
                        // Moderní logo s vícevrstvým designem a animacemi
                        ZStack {
                            // Vnější kruh s gradientem a stínem
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            .blue.opacity(0.15),
                                            .blue.opacity(0.05),
                                            .clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 1)
                            
                            // Střední kruh s gradientem
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .blue.opacity(0.2),
                                            .blue.opacity(0.1),
                                            .blue.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 85, height: 85)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                            
                            // Vnitřní kruh s hlavním gradientem
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .blue.opacity(0.25),
                                            .blue.opacity(0.15),
                                            .blue.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            // Hlavní ikona - moderní auto s gradientem
                            Image(systemName: "car.2.fill")

                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            .white,
                                            .blue.opacity(0.9),
                                            .blue.opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            // Animovaný indikátor pohybu
                            ZStack {
                                // Pozadí pro indikátor
                                Circle()
                                    .fill(.white)
                                    .frame(width: 24, height: 24)
                                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                
                                // Ikona rychloměru
                                Image(systemName: "speedometer")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .green.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .offset(x: 28, y: -28)
                            
                            // Dekorativní tečky kolem loga
                            ForEach(0..<8, id: \.self) { index in
                                Circle()
                                    .fill(.blue.opacity(0.3))
                                    .frame(width: 3, height: 3)
                                    .offset(
                                        x: cos(Double(index) * .pi / 4) * 45,
                                        y: sin(Double(index) * .pi / 4) * 45
                                    )
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(localizationManager.localizedString("home"))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .primary.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(localizationManager.localizedString("appDescription"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Current Month Overview
                    VStack(spacing: 20) {
                        HStack {
                            Text(localizationManager.localizedString("currentMonth"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            StatCard(
                                title: localizationManager.localizedString("totalHours"),
                                value: currentMonthData.totalHours.formattedTime(useTimePicker: useTimePicker),
                                icon: "clock.fill",
                                color: DesignSystem.Colors.primary
                            )
                            
                            StatCard(
                                title: localizationManager.localizedString("kilometers"),
                                value: String(format: "%.0f", currentMonthData.totalKilometers),
                                icon: "speedometer",
                                color: DesignSystem.Colors.secondary
                            )
                            
                            StatCard(
                                title: localizationManager.localizedString("fuelCosts"),
                                value: String(format: "%.0f Kč", viewModel.monthlyFuelCost),
                                icon: "fuelpump.fill",
                                color: DesignSystem.Colors.accent
                            )
                        }
                        

                            
                            if let currentReport = currentMonthData.currentReport {
                                HStack {
                                    Text("\(currentReport.workDays.count) \(localizationManager.localizedString("recordsCount"))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    .cardStyleSecondary()
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Text(localizationManager.localizedString("quickActions"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ActionButton(
                                title: localizationManager.localizedString("addRecord"),
                                subtitle: localizationManager.localizedString("addRecordForDay"),
                                icon: "plus.circle.fill",
                                color: DesignSystem.Colors.primary
                            ) {
                                selectedTab = 1
                            }
                            
                            ActionButton(
                                title: localizationManager.localizedString("history"),
                                subtitle: localizationManager.localizedString("viewPreviousMonths"),
                                icon: "clock.fill",
                                color: DesignSystem.Colors.secondary
                            ) {
                                selectedTab = 2
                            }
                            
                            ActionButton(
                                title: localizationManager.localizedString("fuel"),
                                subtitle: localizationManager.localizedString("fuelTracking"),
                                icon: "fuelpump.fill",
                                color: DesignSystem.Colors.accent
                            ) {
                                selectedTab = 3
                            }
                            
                            NavigationLink(destination: StatisticsView(viewModel: viewModel, selectedTab: $selectedTab)) {
                                ActionButtonContent(
                                    title: localizationManager.localizedString("statistics"),
                                    subtitle: localizationManager.localizedString("hoursKilometersOverview"),
                                    icon: "chart.bar.fill",
                                    color: DesignSystem.Colors.purple
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                        }
                    }
                    .cardStyleSecondary()
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarHidden(false)
            .navigationTitle(localizationManager.localizedString("overview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
    }
}


#Preview {
    HomeView(viewModel: MechanicViewModel(), selectedTab: .constant(0))
} 
