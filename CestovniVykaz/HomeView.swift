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
    @State private var isContentLoaded = false
    @State private var animateStats = false
    @State private var showingSettings = false
    
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
                            .scaleEffect(isContentLoaded ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: isContentLoaded)
                            
                            // Dekorativní tečky kolem loga
                            ForEach(0..<8, id: \.self) { index in
                                Circle()
                                    .fill(.blue.opacity(0.3))
                                    .frame(width: 3, height: 3)
                                    .offset(
                                        x: cos(Double(index) * .pi / 4) * 45,
                                        y: sin(Double(index) * .pi / 4) * 45
                                    )
                                    .opacity(isContentLoaded ? 1.0 : 0.0)
                                    .animation(
                                        .easeOut(duration: 0.5)
                                        .delay(0.5 + Double(index) * 0.05),
                                        value: isContentLoaded
                                    )
                            }
                        }
                        .scaleEffect(isContentLoaded ? 1.0 : 0.3)
                        .opacity(isContentLoaded ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isContentLoaded)
                        
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
                                .opacity(isContentLoaded ? 1.0 : 0.0)
                                .offset(y: isContentLoaded ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.2), value: isContentLoaded)
                            
                            Text(localizationManager.localizedString("appDescription"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .opacity(isContentLoaded ? 1.0 : 0.0)
                                .offset(y: isContentLoaded ? 0 : 20)
                                .animation(.easeOut(duration: 0.8).delay(0.4), value: isContentLoaded)
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
                        
                        HStack(spacing: 8) {
                            HomeStatCard(
                                title: localizationManager.localizedString("totalHours"),
                                value: String(format: "%.1f", currentMonthData.totalHours),
                                icon: "clock.fill",
                                color: .blue
                            )
                            .opacity(animateStats ? 1.0 : 0.0)
                            .offset(x: animateStats ? 0 : -30)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: animateStats)
                            
                            HomeStatCard(
                                title: localizationManager.localizedString("kilometers"),
                                value: String(format: "%.0f", currentMonthData.totalKilometers),
                                icon: "speedometer",
                                color: .green
                            )
                            .opacity(animateStats ? 1.0 : 0.0)
                            .offset(x: animateStats ? 0 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateStats)
                            
                            HomeStatCard(
                                title: localizationManager.localizedString("fuelCosts"),
                                value: String(format: "%.0f Kč", viewModel.monthlyFuelCost),
                                icon: "fuelpump.fill",
                                color: .orange
                            )
                            .opacity(animateStats ? 1.0 : 0.0)
                            .offset(x: animateStats ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(1.0), value: animateStats)
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
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        Text(localizationManager.localizedString("quickActions"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 12) {
                            QuickActionButton(
                                title: localizationManager.localizedString("addRecord"),
                                subtitle: localizationManager.localizedString("addRecordForDay"),
                                icon: "plus.circle.fill",
                                color: .blue
                            ) {
                                selectedTab = 1
                            }
                            
                            QuickActionButton(
                                title: localizationManager.localizedString("history"),
                                subtitle: localizationManager.localizedString("viewPreviousMonths"),
                                icon: "clock.fill",
                                color: .green
                            ) {
                                selectedTab = 2
                            }
                            
                            QuickActionButton(
                                title: localizationManager.localizedString("fuel"),
                                subtitle: localizationManager.localizedString("fuelTracking"),
                                icon: "fuelpump.fill",
                                color: .purple
                            ) {
                                selectedTab = 3
                            }
                            
                            NavigationLink(destination: StatisticsView(viewModel: viewModel, selectedTab: $selectedTab)) {
                                QuickActionButtonContent(
                                    title: localizationManager.localizedString("statistics"),
                                    subtitle: localizationManager.localizedString("hoursKilometersOverview"),
                                    icon: "chart.bar.fill",
                                    color: .orange
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
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
                SettingsView()
            }
            .onAppear {
                withAnimation {
                    isContentLoaded = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        animateStats = true
                    }
                }
            }
        }
    }
}

struct HomeStatCard: View {
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

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButtonContent: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    HomeView(viewModel: MechanicViewModel(), selectedTab: .constant(0))
} 
