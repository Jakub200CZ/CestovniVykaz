//
//  StatisticsView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

// MARK: - Helpers pro měsíční grafy
private let monthNamesShort = ["Led", "Úno", "Bře", "Dub", "Kvě", "Čvn", "Čvc", "Srp", "Zář", "Říj", "Lis", "Pro"]
private let monthNamesLong = ["leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec"]

private func monthLabelShort(_ date: Date) -> String {
    let calendar = Calendar.current
    let month = calendar.component(.month, from: date)
    let year = calendar.component(.year, from: date)
    return "\(monthNamesShort[month - 1]) \(String(year).suffix(2))"
}

private func monthLabelLong(_ date: Date) -> String {
    let calendar = Calendar.current
    let month = calendar.component(.month, from: date)
    let year = calendar.component(.year, from: date)
    return "\(monthNamesLong[month - 1]) \(year)"
}

// Pomocné tvary pro spojnicový graf
private struct SpojnicovyGrafVyplnBody: Shape {
    let points: [CGPoint]
    let bottomY: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first, let last = points.last else { return p }
        p.move(to: CGPoint(x: first.x, y: bottomY))
        for pt in points { p.addLine(to: pt) }
        p.addLine(to: CGPoint(x: last.x, y: bottomY))
        p.closeSubpath()
        return p
    }
}

private struct SpojnicovyGrafCaraBody: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: first)
        for i in 1..<points.count { p.addLine(to: points[i]) }
        return p
    }
}

// MARK: - Spojnicový graf se spodní výplní (posledních 6 měsíců)
struct ClickableMonthBarChart: View {
    let title: String
    let icon: String
    let color: Color
    let data: [(label: String, value: Double, monthDate: Date)]
    let valueFormat: (Double) -> String
    var displayTextForSelected: ((Int) -> String)?
    /// Vlastní text pro průměr (např. u paliva "X Kč, Y l"). Když nil, použije se valueFormat(průměr).
    var averageDisplayText: String?
    @Binding var selectedIndex: Int?
    var chartHeight: CGFloat = 120
    private let lineWidth: CGFloat = 2.5
    private let pointRadius: CGFloat = 6

    /// Když je nastaveno, použije se místo průměru ze všech bodů (např. průměr jen z dokončených měsíců).
    var customAverage: Double?
    /// Když je nastaveno, použije se pro text průměru (např. u paliva "X Kč, Y l" z dokončených měsíců).
    var customAverageLabel: String?
    /// Pro vybraný měsíc (index): false = měsíc není dokončen → zobrazí se červený vykřičník.
    var isMonthCompleted: ((Int) -> Bool)?

    /// Průměr hodnot v datech (nebo customAverage, pokud je nastaven)
    private var effectiveAverageValue: Double {
        if let custom = customAverage { return custom }
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }

    /// Text průměru pro zobrazení
    private var averageLabel: String {
        if let custom = customAverageLabel { return custom }
        return averageDisplayText ?? valueFormat(effectiveAverageValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            let maxVal = max(data.map(\.value).max() ?? 1, 1)
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let count = data.count
                let stepX = count > 1 ? w / CGFloat(count - 1) : w
                let paddingTop: CGFloat = 8
                let paddingBottom: CGFloat = 4
                let chartH = h - paddingTop - paddingBottom
                let points: [CGPoint] = (0..<count).map { i in
                    let item = data[i]
                    let x = CGFloat(i) * stepX
                    let ratio = maxVal > 0 ? (item.value / maxVal) : 0
                    let y = paddingTop + chartH * (1 - ratio)
                    return CGPoint(x: x, y: y)
                }
                let bottomY = paddingTop + chartH
                let avgRatio = maxVal > 0 ? (effectiveAverageValue / maxVal) : 0
                let averageY = paddingTop + chartH * (1 - avgRatio)

                ZStack(alignment: .topLeading) {
                    if count > 0 {
                        // 1) Výplň pod čárou (spodní výplň)
                        SpojnicovyGrafVyplnBody(points: points, bottomY: bottomY)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.35), color.opacity(0.08)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // 2) Horizontální čára průměru (čerchovaná)
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: averageY))
                            p.addLine(to: CGPoint(x: w, y: averageY))
                        }
                        .stroke(
                            color.opacity(0.8),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )

                        // 3) Spojnicová čára
                        SpojnicovyGrafCaraBody(points: points)
                            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                        // 4) Body + tlačítka
                        ForEach(Array(points.enumerated()), id: \.offset) { index, p in
                            let isSelected = selectedIndex == index
                            Button {
                                withAnimation(DesignSystem.Animation.spring) {
                                    selectedIndex = selectedIndex == index ? nil : index
                                }
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: pointRadius * 2, height: pointRadius * 2)
                                    .overlay(Circle().stroke(DesignSystem.Colors.cardBackground, lineWidth: 2))
                                    .overlay(
                                        Circle()
                                            .stroke(isSelected ? color : .clear, lineWidth: 2.5)
                                            .scaleEffect(1.6)
                                    )
                            }
                            .buttonStyle(.plain)
                            .position(x: p.x, y: p.y)
                        }

                        // 5) Text průměru vpravo u čáry
                        Text("Průměr: \(averageLabel)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(color.opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.cardBackground.opacity(0.95))
                            )
                            .position(x: max(60, w - 55), y: averageY)
                    }
                }
                .frame(width: w, height: h)
            }
            .frame(height: chartHeight)

            HStack(alignment: .center, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    Button {
                        withAnimation(DesignSystem.Animation.spring) {
                            selectedIndex = selectedIndex == index ? nil : index
                        }
                    } label: {
                        Text(item.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedIndex == index ? color : DesignSystem.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let idx = selectedIndex, idx >= 0, idx < data.count {
                let item = data[idx]
                let text = displayTextForSelected?(idx) ?? valueFormat(item.value)
                let completed = isMonthCompleted?(idx) ?? true
                HStack(spacing: 6) {
                    Text("\(monthLabelLong(item.monthDate)): \(text)")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                    if !completed {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .shadow(
            color: DesignSystem.Shadows.card,
            radius: DesignSystem.Shadows.cardRadius,
            x: DesignSystem.Shadows.cardOffset.width,
            y: DesignSystem.Shadows.cardOffset.height
        )
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @State private var selectedTimeRange: TimeRange = .allTime
    /// Sdílený výběr měsíce pro všechny tři grafy (index 0–5)
    @State private var selectedMonthIndex: Int?
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
        let baseReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty }
        switch selectedTimeRange {
        case .currentMonth:
            return baseReports.filter { calendar.isDate($0.month, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                return baseReports.filter { calendar.isDate($0.month, equalTo: lastMonth, toGranularity: .month) }
            }
            return []
        case .last3Months:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: start) ?? now
            return baseReports.filter { $0.month >= threeMonthsAgo && $0.month <= start }
        case .allTime:
            return baseReports
        }
    }

    var periodStats: (totalHours: Double, totalKilometers: Double, totalFuelCost: Double, totalLiters: Double) {
        let totalHours = filteredReports.reduce(0) { $0 + $1.totalHours }
        let totalKilometers = filteredReports.reduce(0) { $0 + $1.totalKilometers }
        let calendar = Calendar.current
        let now = Date()
        let filteredFuelEntries: [FuelEntry]
        switch selectedTimeRange {
        case .currentMonth:
            filteredFuelEntries = viewModel.fuelEntries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredFuelEntries = viewModel.fuelEntries.filter { calendar.isDate($0.date, equalTo: lastMonth, toGranularity: .month) }
            } else { filteredFuelEntries = [] }
        case .last3Months:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: start) ?? now
            filteredFuelEntries = viewModel.fuelEntries.filter { $0.date >= threeMonthsAgo && $0.date <= now }
        case .allTime:
            filteredFuelEntries = viewModel.fuelEntries
        }
        let totalFuelCost = filteredFuelEntries.reduce(0) { $0 + $1.price }
        let totalLiters = filteredFuelEntries.reduce(0) { $0 + $1.fuelAmount }
        return (totalHours, totalKilometers, totalFuelCost, totalLiters)
    }

    /// Celkem natankováno za celou dobu (litry)
    var totalLitersAllTime: Double {
        viewModel.fuelEntries.reduce(0) { $0 + $1.fuelAmount }
    }

    /// Posledních 6 měsíců (od nejstaršího)
    var last6MonthStarts: [Date] {
        let calendar = Calendar.current
        let now = Date()
        let startOfCurrent = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return (0..<6).reversed().compactMap { calendar.date(byAdding: .month, value: -$0, to: startOfCurrent) }
    }

    /// Počet pracovních dnů (Po–Pá) v daném měsíci
    private func workingDaysCount(in monthStart: Date) -> Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return 0 }
        let month = calendar.component(.month, from: monthStart)
        let year = calendar.component(.year, from: monthStart)
        return range.filter { day in
            var comp = DateComponents()
            comp.year = year
            comp.month = month
            comp.day = day
            guard let date = calendar.date(from: comp) else { return false }
            let weekday = calendar.component(.weekday, from: date)
            return weekday >= 2 && weekday <= 6 // Po = 2, Pá = 6
        }.count
    }

    /// Měsíc je dokončený stejně jako v Historie: počet záznamů (workDays.count) >= počet pracovních dnů (Po–Pá) v měsíci.
    private func isMonthCompleted(monthStart: Date) -> Bool {
        let calendar = Calendar.current
        let report = viewModel.monthlyReports.first { calendar.isDate($0.month, equalTo: monthStart, toGranularity: .month) }
        guard let report = report else { return false }
        let expectedWorkingDays = workingDaysCount(in: monthStart)
        return report.workDays.count >= expectedWorkingDays
    }

    /// Pro posledních 6 měsíců: true = měsíc dokončen (všechny pracovní dny vyplněny)
    var last6MonthsCompleted: [Bool] {
        last6MonthStarts.map { isMonthCompleted(monthStart: $0) }
    }

    /// Průměr hodin jen z dokončených měsíců; když žádný dokončený, nil = graf použije průměr ze všech
    var averageHoursCompletedOnly: (value: Double?, label: String?) {
        let hoursData = last6MonthsHoursData
        let completed = last6MonthsCompleted
        let sum = zip(hoursData, completed).filter(\.1).map(\.0.value).reduce(0, +)
        let count = completed.filter { $0 }.count
        guard count > 0 else { return (nil, nil) }
        let avg = sum / Double(count)
        return (avg, avg.formattedTime(useTimePicker: useTimePicker) + " h")
    }

    /// Průměr km jen z dokončených měsíců; když žádný dokončený, nil
    var averageKmCompletedOnly: (value: Double?, label: String?) {
        let kmData = last6MonthsKmData
        let completed = last6MonthsCompleted
        let sum = zip(kmData, completed).filter(\.1).map(\.0.value).reduce(0, +)
        let count = completed.filter { $0 }.count
        guard count > 0 else { return (nil, nil) }
        let avg = sum / Double(count)
        return (avg, formatKilometers(avg) + " km")
    }

    /// Průměr paliva jen z dokončených měsíců; když žádný dokončený, nil
    var averageFuelCompletedOnly: (value: Double?, label: String?) {
        let prices = last6MonthsFuelPrices
        let litersData = last6MonthsFuelLitersData.map(\.value)
        let completed = last6MonthsCompleted
        let count = completed.filter { $0 }.count
        guard count > 0 else { return (nil, nil) }
        let sumKc = zip(prices, completed).filter(\.1).map(\.0).reduce(0, +)
        let sumL = zip(litersData, completed).filter(\.1).map(\.0).reduce(0, +)
        let avgKc = sumKc / Double(count)
        let avgL = sumL / Double(count)
        return (avgL, "\(formatCurrency(avgKc)) Kč, \(String(format: "%.0f", avgL)) l")
    }

    /// Data pro graf hodin: [(zkrácený label, hodiny, datum měsíce)]
    var last6MonthsHoursData: [(label: String, value: Double, monthDate: Date)] {
        let calendar = Calendar.current
        return last6MonthStarts.map { monthStart in
            let report = viewModel.monthlyReports.first { calendar.isDate($0.month, equalTo: monthStart, toGranularity: .month) }
            let hours = report?.totalHours ?? 0
            return (monthLabelShort(monthStart), hours, monthStart)
        }
    }

    /// Data pro graf km
    var last6MonthsKmData: [(label: String, value: Double, monthDate: Date)] {
        let calendar = Calendar.current
        return last6MonthStarts.map { monthStart in
            let report = viewModel.monthlyReports.first { calendar.isDate($0.month, equalTo: monthStart, toGranularity: .month) }
            let km = report?.totalKilometers ?? 0
            return (monthLabelShort(monthStart), km, monthStart)
        }
    }

    /// Data pro graf paliva (výška sloupce = litry)
    var last6MonthsFuelLitersData: [(label: String, value: Double, monthDate: Date)] {
        let calendar = Calendar.current
        return last6MonthStarts.map { monthStart in
            let liters = viewModel.fuelEntries
                .filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.fuelAmount }
            return (monthLabelShort(monthStart), liters, monthStart)
        }
    }

    /// Ceny paliva po měsících (stejné pořadí jako last6MonthStarts) pro zobrazení „Kč, l“
    var last6MonthsFuelPrices: [Double] {
        let calendar = Calendar.current
        return last6MonthStarts.map { monthStart in
            viewModel.fuelEntries
                .filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.price }
        }
    }

    private func formatKilometers(_ kilometers: Double) -> String {
        if kilometers >= 1000 { return String(format: "%.1fK", kilometers / 1000) }
        return String(format: "%.0f", kilometers)
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1000 { return String(format: "%.1fK", amount / 1000) }
        return String(format: "%.0f", amount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Celková statistika za období
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Statistiky za \(selectedTimeRange.rawValue.lowercased())")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

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

                    // Celkem natankováno (všechna data)
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignSystem.Colors.accent)
                        Text("Celkem natankováno:")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text(String(format: "%.0f l", totalLitersAllTime))
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                .cardStyleSecondary()
                .padding(.horizontal)

                // Výběr období
                Picker("Časové období", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Grafy – posledních 6 měsíců
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Posledních 6 měsíců")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, 4)

                    ClickableMonthBarChart(
                        title: "Hodiny",
                        icon: "clock.fill",
                        color: DesignSystem.Colors.primary,
                        data: last6MonthsHoursData,
                        valueFormat: { $0.formattedTime(useTimePicker: useTimePicker) + " h" },
                        selectedIndex: $selectedMonthIndex,
                        customAverage: averageHoursCompletedOnly.value,
                        customAverageLabel: averageHoursCompletedOnly.label,
                        isMonthCompleted: { idx in idx >= 0 && idx < last6MonthsCompleted.count ? last6MonthsCompleted[idx] : true }
                    )
                    .padding(.horizontal)

                    ClickableMonthBarChart(
                        title: "Kilometry",
                        icon: "speedometer",
                        color: DesignSystem.Colors.secondary,
                        data: last6MonthsKmData,
                        valueFormat: { formatKilometers($0) + " km" },
                        selectedIndex: $selectedMonthIndex,
                        customAverage: averageKmCompletedOnly.value,
                        customAverageLabel: averageKmCompletedOnly.label,
                        isMonthCompleted: { idx in idx >= 0 && idx < last6MonthsCompleted.count ? last6MonthsCompleted[idx] : true }
                    )
                    .padding(.horizontal)

                    ClickableMonthBarChart(
                        title: "Palivo",
                        icon: "fuelpump.fill",
                        color: DesignSystem.Colors.accent,
                        data: last6MonthsFuelLitersData,
                        valueFormat: { String(format: "%.0f l", $0) },
                        displayTextForSelected: { idx in
                            let prices = last6MonthsFuelPrices
                            let liters = last6MonthsFuelLitersData.map(\.value)
                            guard idx >= 0, idx < prices.count, idx < liters.count else { return "" }
                            return "\(formatCurrency(prices[idx])) Kč, \(String(format: "%.0f", liters[idx])) l"
                        },
                        selectedIndex: $selectedMonthIndex,
                        customAverage: averageFuelCompletedOnly.value,
                        customAverageLabel: averageFuelCompletedOnly.label,
                        isMonthCompleted: { idx in idx >= 0 && idx < last6MonthsCompleted.count ? last6MonthsCompleted[idx] : true }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .navigationTitle("Statistiky")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Monthly Stat Row (pro případné použití jinde)
struct MonthlyStatRow: View {
    let report: MonthlyReport
    @ObservedObject var viewModel: MechanicViewModel
    @AppStorage("useTimePicker") private var useTimePicker = false

    private func formatDays(_ count: Int) -> String {
        switch count {
        case 1: return "1 den"
        case 2...4: return "\(count) dny"
        default: return "\(count) dnů"
        }
    }

    private func formatMonthYear(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        return "\(monthNamesLong[month - 1]) \(year)"
    }

    private var monthlyFuelCost: Double {
        let calendar = Calendar.current
        return viewModel.fuelEntries
            .filter { calendar.isDate($0.date, equalTo: report.month, toGranularity: .month) }
            .reduce(0) { $0 + $1.price }
    }

    private func formatKilometers(_ kilometers: Double) -> String {
        if kilometers >= 1000 { return String(format: "%.1fK", kilometers / 1000) }
        return String(format: "%.0f", kilometers)
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1000 { return String(format: "%.1fK", amount / 1000) }
        return String(format: "%.0f", amount)
    }

    var body: some View {
        HStack(spacing: 16) {
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
            HStack(spacing: 20) {
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
        .background(RoundedRectangle(cornerRadius: 10).fill(.regularMaterial))
    }
}
