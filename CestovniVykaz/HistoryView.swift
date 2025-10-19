//
//  HistoryView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

// MARK: - History View
struct HistoryView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @State private var animateList = false
    @State private var showingSettings = false
    
    var sortedReports: [MonthlyReport] {
        let baseReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty } // Filtrovat prázdné měsíce
        
        return baseReports
            .sorted { $0.month > $1.month }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                List {
                    ForEach(Array(sortedReports.enumerated()), id: \.element.id) { index, report in
                        NavigationLink(destination: MonthDetailView(viewModel: viewModel, month: report.month, selectedTab: $selectedTab)) {
                            MonthlyReportRow(report: report)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(animateList ? 1.0 : 0.0)
                        .offset(y: animateList ? 0 : 50)
                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateList)
                    }
                }
                .padding(.top, 10)
                
            }
            .navigationTitle("Historie")
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
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateList = true
                }
            }
        }
    }
}

struct MonthlyReportRow: View {
    let report: MonthlyReport
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    // Výpočet pracovních dnů v měsíci (pondělí-pátek)
    var workingDaysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: report.month) ?? 1..<29
        let month = calendar.component(.month, from: report.month)
        let year = calendar.component(.year, from: report.month)
        var count = 0
        for day in range {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            if let date = calendar.date(from: comps) {
                let weekday = calendar.component(.weekday, from: date)
                if weekday != 1 && weekday != 7 { // 1 = neděle, 7 = sobota
                    count += 1
                }
            }
        }
        return count
    }
    
    // Správné skloňování "dny" podle jazyka
    private func formatDays(_ count: Int, total: Int) -> String {
        let countText: String
        switch count {
        case 1:
            countText = "den"
        case 2...4:
            countText = "\(count) dny"
        default:
            countText = "\(count) dnů"
        }
        
        let totalText: String
        switch total {
        case 1:
            totalText = "den"
        case 2...4:
            totalText = "\(total) dny"
        default:
            totalText = "\(total) dnů"
        }
        
        return "\(countText)/\(totalText)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.month.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
            }
            
            HStack(spacing: 20) {
                StatItem(title: "Jízda", value: "\(report.totalDrivingHours.formattedTime(useTimePicker: useTimePicker)) h")
                StatItem(title: "Práce", value: "\(report.totalWorkingHours.formattedTime(useTimePicker: useTimePicker)) h")
                StatItem(title: "Km", value: String(format: "%.0f", report.totalKilometers))
                Spacer()
                Text(formatDays(report.workDays.count, total: workingDaysInMonth))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Dny podle typu
            if report.vacationDays > 0 || report.sickDays > 0 {
                HStack(spacing: 16) {
                    if report.workingDays > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("\(report.workingDays) \("Pracovní dny")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if report.vacationDays > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("\(report.vacationDays) \("Dovolená")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if report.sickDays > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("\(report.sickDays) \("Lékař / Nemoc")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct MonthDetailView: View, Identifiable {
    @ObservedObject var viewModel: MechanicViewModel
    let month: Date
    @Binding var selectedTab: Int
    var id: UUID { UUID() } // Unique ID for each view instance
    @Environment(\.dismiss) private var dismiss
    @State private var editingWorkDay: WorkDay? = nil
    @State private var animateContent = false
    @State private var showingShareSheet = false
    @State private var csvFileURL: URL?
    @State private var isExporting = false
    @State private var showingSettings = false
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    // Get current report data
    var report: MonthlyReport? {
        let calendar = Calendar.current
        
        // Použít stejnou logiku jako v sortedReports - najít report s workDays
        let filteredReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty }
        
        if let foundReport = filteredReports.first(where: { report in
            calendar.isDate(report.month, equalTo: month, toGranularity: .month)
        }) {
            return foundReport
        }
        
        return nil
    }
    
    var body: some View {
        List {
                if let report = report {
                    Section("Přehled měsíce") {
                        DetailRow(title: "Celkem hodin jízda", value: "\(report.totalDrivingHours.formattedTime(useTimePicker: useTimePicker)) h")
                        DetailRow(title: "Celkem hodin práce", value: "\(report.totalWorkingHours.formattedTime(useTimePicker: useTimePicker)) h")
                        DetailRow(title: "Celkem kilometrů", value: String(format: "%.0f km", report.totalKilometers))
                        DetailRow(title: "Celkem hodin", value: "\(report.totalHours.formattedTime(useTimePicker: useTimePicker)) h")
                        DetailRow(title: "Počet záznamů", value: "\(report.workDays.count)")
                        
                        // Dny podle typu
                        if report.workingDays > 0 {
                            DetailRow(title: "Pracovních dnů", value: "\(report.workingDays)")
                        }
                        if report.vacationDays > 0 {
                            DetailRow(title: "Dovolená", value: "\(report.vacationDays) \("Dny")")
                        }
                        if report.sickDays > 0 {
                            DetailRow(title: "Lékař/Nemoc", value: "\(report.sickDays) dny")
                        }
                    }
                    
                    
                    // Kalendářní náhled - zobrazit vždy
                    Section {
                        MonthCalendarView(report: report)
                            .padding(.vertical, 8)
                    }
                    
                    if !report.workDays.isEmpty {
                        Section("Pracovní dny (\(report.workDays.count))") {
                            ForEach(report.workDays.sorted { $0.date < $1.date }, id: \.id) { workDay in
                                WorkDayDetailRow(workDay: workDay, onEdit: {
                                    editingWorkDay = workDay
                                })
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteWorkDay(workDay, from: report)
                                    } label: {
                                        Label("Smazat", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } else {
                        Section("Pracovní dny") {
                            Text("Žádné záznamy pro tento měsíc")
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                    
                    // CSV Export sekce
                    if !report.workDays.isEmpty {
                        Section {
                            Button(action: {
                                exportToCSV()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Exportovat data")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Uložit jako CSV soubor")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if isExporting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isExporting)
                        }
                    }
                } else {
                    Section {
                        Text("Měsíc nenalezen")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle(month.formatted(.dateTime.month(.wide).year()))
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
            .sheet(isPresented: $showingShareSheet) {
                if let csvFileURL = csvFileURL {
                    ShareSheet(activityItems: [csvFileURL])
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(item: $editingWorkDay) { workDay in
                if let report = report {
                    EditWorkDaySheet(viewModel: viewModel, workDay: workDay, report: report, onDismiss: {
                        editingWorkDay = nil
                    })
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
    }
    
    // MARK: - CSV Export Functions
    private func exportToCSV() {
        guard let report = report, !isExporting else { return }
        
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let csvContent = generateCSVContent(from: report)
            let fileName = "CestovniVykaz_\(month.formatted(.dateTime.year().month()))"
            
            // Použít Documents složku místo temporary directory pro lepší kompatibilitu
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent("\(fileName).csv")
            
            do {
                try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async {
                    csvFileURL = fileURL
                    showingShareSheet = true
                    isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    print("Chyba při vytváření CSV: \(error)")
                }
            }
        }
    }
    
    private func generateCSVContent(from report: MonthlyReport) -> String {
        var csvContent = "Datum,Jízda (h),Práce (h),Kilometry,Město\n"
        
        let sortedWorkDays = report.workDays.sorted { $0.date < $1.date }
        
        for workDay in sortedWorkDays {
            let dateString = workDay.date.formatted(.dateTime.day().month().year())
            let drivingHours = workDay.drivingHours.formattedTime(useTimePicker: useTimePicker)
            let workingHours = workDay.workingHours.formattedTime(useTimePicker: useTimePicker)
            let kilometers = String(format: "%.0f", workDay.kilometers)
            let city = workDay.city.isEmpty ? "" : workDay.city
            
            csvContent += "\(dateString),\(drivingHours),\(workingHours),\(kilometers),\(city)\n"
        }
        
        return csvContent
    }
    
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct WorkDayDetailRow: View {
    let workDay: WorkDay
    var onEdit: (() -> Void)? = nil
    @AppStorage("useTimePicker") private var useTimePicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(workDay.date.formatted(.dateTime.day().month()))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(workDay.date.formatted(.dateTime.year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Day type indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(dayTypeColor)
                        .frame(width: 10, height: 10)
                    Text(workDay.dayType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(dayTypeColor)
                }
                
                // Status and edit
                HStack(spacing: 8) {
                    if workDay.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    
                    if let onEdit = onEdit {
                        Button(action: { onEdit() }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Content
            if workDay.dayType == .vacation || workDay.dayType == .sick {
                // Pro dovolenou a lékaře
                VStack(alignment: .leading, spacing: 6) {
                    Text(workDay.dayType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(dayTypeColor)
                    
                    if !workDay.notes.isEmpty {
                        Text(workDay.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            } else {
                // Pro pracovní dny - kompaktní layout
                VStack(spacing: 8) {
                    // Všechny stats v jednom řádku - zarovnané do středu
                    HStack {
                        Spacer()
                        
                        CompactStatItem(
                            icon: "car.fill",
                            value: workDay.drivingHours.formattedTime(useTimePicker: useTimePicker),
                            unit: "h",
                            color: .blue
                        )
                        
                        CompactStatItem(
                            icon: "wrench.fill",
                            value: workDay.workingHours.formattedTime(useTimePicker: useTimePicker),
                            unit: "h",
                            color: .green
                        )
                        
                        CompactStatItem(
                            icon: "road.lanes",
                            value: String(format: "%.0f", workDay.kilometers),
                            unit: "km",
                            color: .orange
                        )
                        
                        Spacer()
                    }
                    
                    // Location and notes níže - zarovnané k levému rohu
                    if !workDay.city.isEmpty || !workDay.notes.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if !workDay.city.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                        Text(workDay.city)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                if !workDay.notes.isEmpty {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "note.text")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                        Text(workDay.notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(dayTypeColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var dayTypeColor: Color {
        switch workDay.dayType {
        case .work:
            return .green
        case .vacation:
            return .blue
        case .sick:
            return .red
        }
    }
}

struct CompactStatItem: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// Editační sheet pro úpravu pracovního dne
struct EditWorkDaySheet: View {
    @ObservedObject var viewModel: MechanicViewModel
    @State var workDay: WorkDay
    let report: MonthlyReport
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var validationErrors: [String] = []
    @State private var drivingHoursText: String = ""
    @State private var workingHoursText: String = ""
    @State private var kilometersText: String = ""
    @State private var drivingTimePicker = Calendar.current.date(from: DateComponents(hour: 1, minute: 11)) ?? Date()
    @State private var workingTimePicker = Calendar.current.date(from: DateComponents(hour: 1, minute: 11)) ?? Date()
    @AppStorage("useTimePicker") private var useTimePicker = false
    @FocusState private var focusedField: Field?
    
    init(viewModel: MechanicViewModel, workDay: WorkDay, report: MonthlyReport, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.workDay = workDay
        self.report = report
        self.onDismiss = onDismiss
        self._drivingHoursText = State(initialValue: String(format: "%.1f", workDay.drivingHours))
        self._workingHoursText = State(initialValue: String(format: "%.1f", workDay.workingHours))
        self._kilometersText = State(initialValue: String(format: "%.0f", workDay.kilometers))
        
        // Inicializovat time picker hodnoty
        let calendar = Calendar.current
        
        // Driving time picker
        let drivingHours = Int(workDay.drivingHours)
        let drivingMinutes = Int((workDay.drivingHours - Double(drivingHours)) * 60)
        var drivingComponents = DateComponents()
        drivingComponents.hour = drivingHours
        drivingComponents.minute = drivingMinutes
        self._drivingTimePicker = State(initialValue: calendar.date(from: drivingComponents) ?? Date())
        
        // Working time picker
        let workingHours = Int(workDay.workingHours)
        let workingMinutes = Int((workDay.workingHours - Double(workingHours)) * 60)
        var workingComponents = DateComponents()
        workingComponents.hour = workingHours
        workingComponents.minute = workingMinutes
        self._workingTimePicker = State(initialValue: calendar.date(from: workingComponents) ?? Date())
    }
    
    var body: some View {
        Form {
                VStack(alignment: .leading, spacing: 4) {
                    DatePicker("Datum", selection: $workDay.date, displayedComponents: .date)
                    
                    if !isWorkDay(workDay.date) || isHoliday(workDay.date) {
                        Text("(víkend/svátek)")
                            .foregroundStyle(.red)
                            .font(.caption)
                    } else if hasExistingRecord(for: workDay.date, excluding: workDay) {
                        Text("(již má záznam)")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                TimeInputField(
                    title: "Ujeté hodiny",
                    textValue: $drivingHoursText,
                    timeValue: $drivingTimePicker,
                    useTimePicker: useTimePicker,
                    placeholder: "0.0h",
                    focusedField: $focusedField,
                    field: .drivingHours
                )
                TimeInputField(
                    title: "Odpracované hodiny",
                    textValue: $workingHoursText,
                    timeValue: $workingTimePicker,
                    useTimePicker: useTimePicker,
                    placeholder: "0.0h",
                    focusedField: $focusedField,
                    field: .workingHours
                )
                HStack {
                    Text("Kilometrů")
                    Spacer()
                    TextField("0", text: $kilometersText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Město")
                    Spacer()
                    TextField("Zadejte město", text: $workDay.city)
                        .multilineTextAlignment(.trailing)
                }
                Section("Poznámka") {
                    TextField("Poznámka", text: $workDay.notes)
                }
                if !validationErrors.isEmpty {
                    Section {
                        ForEach(validationErrors, id: \.self) { err in
                            Text(err).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Upravit záznam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if validate() {
                            // Update workDay with parsed values
                            workDay.drivingHours = drivingHoursText.toDouble() ?? 0.0
                            workDay.workingHours = workingHoursText.toDouble() ?? 0.0
                            workDay.kilometers = kilometersText.toDouble() ?? 0.0
                            viewModel.updateWorkDay(workDay, in: report)
                            dismiss()
                            onDismiss()
                        }
                    }) {
                        Text("Uložit")
                            .frame(alignment: .trailing)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
    }
    
    private func validate() -> Bool {
        var errors: [String] = []
        if workDay.city.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Město je povinné")
        }
        let drivingHours = drivingHoursText.toDouble() ?? 0.0
        let workingHours = workingHoursText.toDouble() ?? 0.0
        let kilometers = kilometersText.toDouble() ?? 0.0
        
        if drivingHours <= 0 && workingHours <= 0 {
            errors.append("Musíte zadat dobu jízdy nebo práce")
        }
        if kilometers < 0 {
            errors.append("Kilometry nemohou být záporné")
        }
        
        // Validation - check if selected date is a work day
        if !isWorkDay(workDay.date) || isHoliday(workDay.date) {
            errors.append("Nelze vytvořit záznam pro víkend nebo svátek")
        }
        
        // Validation - check if record already exists for this date (excluding current)
        if hasExistingRecord(for: workDay.date, excluding: workDay) {
            errors.append("Již máte záznam pro tento den")
        }
        
        validationErrors = errors
        return errors.isEmpty
    }
    
    // Kontrola, zda již existuje záznam pro dané datum (kromě aktuálního)
    private func hasExistingRecord(for date: Date, excluding currentWorkDay: WorkDay) -> Bool {
        let calendar = Calendar.current
        return viewModel.monthlyReports.contains { report in
            report.workDays.contains { workDay in
                calendar.isDate(workDay.date, inSameDayAs: date) && workDay.id != currentWorkDay.id
            }
        }
    }
    
    // Kontrola, zda je datum dostupné pro úpravu
    private func isAvailableForEdit(_ date: Date) -> Bool {
        return isWorkDay(date) && !isHoliday(date) && !hasExistingRecord(for: date, excluding: workDay)
    }
    
    // Kontrola, zda je datum pracovní den (pondělí-pátek)
    private func isWorkDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekday != 1 && weekday != 7 // 1 = neděle, 7 = sobota
    }
    
    // České svátky (2024-2025)
    private let holidays: [Date] = {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let holidayStrings = [
            "2024-01-01", // Nový rok
            "2024-05-01", // Svátek práce
            "2024-05-08", // Den vítězství
            "2024-07-05", // Den slovanských věrozvěstů
            "2024-07-06", // Den upálení mistra Jana Husa
            "2024-10-28", // Den vzniku samostatného československého státu
            "2024-11-17", // Den boje za svobodu a demokracii
            "2024-12-24", // Štědrý den
            "2024-12-25", // 1. svátek vánoční
            "2024-12-26", // 2. svátek vánoční
            "2025-01-01", // Nový rok
            "2025-05-01", // Svátek práce
            "2025-05-08", // Den vítězství
            "2025-07-05", // Den slovanských věrozvěstů
            "2025-07-06", // Den upálení mistra Jana Husa
            "2025-10-28", // Den vzniku samostatného československého státu
            "2025-11-17", // Den boje za svobodu a demokracii
            "2025-12-24", // Štědrý den
            "2025-12-25", // 1. svátek vánoční
            "2025-12-26"  // 2. svátek vánoční
        ]
        
        return holidayStrings.compactMap { formatter.date(from: $0) }
    }()
    
    // Kontrola, zda je datum svátek
    private func isHoliday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return holidays.contains { holiday in
            calendar.isDate(date, inSameDayAs: holiday)
        }
    }
}

// Kalendářní náhled pro měsíc
struct MonthCalendarView: View {
    let report: MonthlyReport?
    
    private let calendar = Calendar.current
    
    private var weekDays: [String] {
        [
            "Po", "Út", "St", "Čt", "Pá", "So", "Ne"
        ]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Kalendář měsíce")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Názvy dnů v týdnu
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Dny v měsíci
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isWorkDay: isWorkDay(date),
                            hasRecord: hasRecord(for: date),
                            isCurrentMonth: isCurrentMonth(date),
                            dayType: getDayType(for: date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
            
            // Legenda - zobrazit vždy
            VStack(spacing: 8) {
                Text("Legenda")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 12, height: 12)
                            Text("Pracovní čas")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 12, height: 12)
                            Text("Dovolená")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            Text("Lékař/Nemoc")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 12, height: 12)
                            Text("Pracovní den")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Kontrola, zda je datum pracovní den
    private func isWorkDay(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday != 1 && weekday != 7 // 1 = neděle, 7 = sobota
    }
    
    // Kontrola, zda má datum záznam
    private func hasRecord(for date: Date) -> Bool {
        guard let report = report else { return false }
        return report.workDays.contains { workDay in
            calendar.isDate(workDay.date, inSameDayAs: date)
        }
    }
    
    // Kontrola, zda je datum v aktuálním měsíci
    private func isCurrentMonth(_ date: Date) -> Bool {
        guard let report = report else { return false }
        return calendar.isDate(date, equalTo: report.month, toGranularity: .month)
    }
    
    // Získání typu dne
    private func getDayType(for date: Date) -> DayType? {
        guard let report = report else { return nil }
        if let workDay = report.workDays.first(where: { workDay in
            calendar.isDate(workDay.date, inSameDayAs: date)
        }) {
            return workDay.dayType
        }
        return nil
    }
    
    // Generování dnů v měsíci
    private var daysInMonth: [Date?] {
        guard let report = report else { return [] }
        let range = calendar.range(of: .day, in: .month, for: report.month) ?? 1..<29
        let firstDayOfMonth = report.month
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Převod na pondělí = 1, neděle = 7
        let adjustedFirstWeekday = firstWeekday == 1 ? 7 : firstWeekday - 1
        
        var days: [Date?] = []
        
        // Prázdné dny před začátkem měsíce
        for _ in 1..<adjustedFirstWeekday {
            days.append(nil)
        }
        
        // Dny v měsíci
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: report.month) {
                days.append(date)
            }
        }
        
        return days
    }
}

// Prázdný kalendář pro měsíc bez záznamů
struct EmptyMonthCalendarView: View {
    let month: Date
    
    private let calendar = Calendar.current
    private let weekDays = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Kalendář měsíce")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Názvy dnů v týdnu
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Dny v měsíci
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        EmptyDayCell(
                            date: date,
                            isWorkDay: isWorkDay(date),
                            isCurrentMonth: isCurrentMonth(date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
            
            // Legenda - zobrazit vždy
            VStack(spacing: 8) {
                Text("Legenda")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 12, height: 12)
                            Text("Pracovní čas")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 12, height: 12)
                            Text("Dovolená")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            Text("Lékař/Nemoc")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 12, height: 12)
                            Text("Pracovní den")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Kontrola, zda je datum pracovní den
    private func isWorkDay(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday != 1 && weekday != 7 // 1 = neděle, 7 = sobota
    }
    
    // Kontrola, zda je datum v aktuálním měsíci
    private func isCurrentMonth(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: month, toGranularity: .month)
    }
    
    // Generování dnů v měsíci
    private var daysInMonth: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<29
        let firstDayOfMonth = month
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Převod na pondělí = 1, neděle = 7
        let adjustedFirstWeekday = firstWeekday == 1 ? 7 : firstWeekday - 1
        
        var days: [Date?] = []
        
        // Prázdné dny před začátkem měsíce
        for _ in 1..<adjustedFirstWeekday {
            days.append(nil)
        }
        
        // Dny v měsíci
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: month) {
                days.append(date)
            }
        }
        
        return days
    }
}

// Prázdná buňka pro den v kalendáři
struct EmptyDayCell: View {
    let date: Date
    let isWorkDay: Bool
    let isCurrentMonth: Bool
    
    var body: some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .font(.caption)
            .fontWeight(.regular)
            .frame(width: 30, height: 30)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .clipShape(Circle())
    }
    
    private var backgroundColor: Color {
        if !isCurrentMonth {
            return Color.clear
        } else if isWorkDay {
            return Color(.systemGray5)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isWorkDay {
            return .primary
        } else {
            return .secondary
        }
    }
}

// Buňka pro den v kalendáři
struct DayCell: View {
    let date: Date
    let isWorkDay: Bool
    let hasRecord: Bool
    let isCurrentMonth: Bool
    let dayType: DayType?
    
    var body: some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .font(.caption)
            .fontWeight(hasRecord ? .bold : .regular)
            .frame(width: 30, height: 30)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .clipShape(Circle())
    }
    
    private var backgroundColor: Color {
        if !isCurrentMonth {
            return Color.clear
        } else if let dayType = dayType {
            switch dayType {
            case .work:
                return .green
            case .vacation:
                return .blue
            case .sick:
                return .red
            }
        } else if isWorkDay {
            return Color(.systemGray5)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if dayType != nil {
            return .white
        } else if isWorkDay {
            return .primary
        } else {
            return .secondary
        }
    }
}

// MARK: - ShareSheet Component
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
