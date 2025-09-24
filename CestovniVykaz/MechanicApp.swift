//
//  MechanicApp.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

// MARK: - Global Keyboard Dismissal
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Main Navigation View
struct MechanicTabView: View {
    @StateObject private var viewModel = MechanicViewModel()
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var animateTabTransition = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 0. Hlavní stránka
                HomeView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text(LocalizationManager.shared.localizedString("overview"))
                    }
                    .tag(0)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                
                // 1. Záznam výkazů
                WorkDayEntryView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                        Text(LocalizationManager.shared.localizedString("records"))
                    }
                    .tag(1)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                
                // 2. Historie výkazů
                HistoryView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text(LocalizationManager.shared.localizedString("history"))
                    }
                    .tag(2)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                
                // 3. Tankování
                FuelOverviewView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "fuelpump.fill")
                        Text(localizationManager.localizedString("fuel"))
                    }
                    .tag(3)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                
                // 4. Zákazníci
                CustomerView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text(localizationManager.localizedString("customers"))
                    }
                    .tag(4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
            .accentColor(.blue)
            .preferredColorScheme(.none) // Automaticky podle systému
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
    }
}

// MARK: - Work Day Entry View
struct WorkDayEntryView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var selectedDate = Date()
    @State private var drivingHours = ""
    @State private var workingHours = ""
    @State private var kilometers = ""
    @State private var city = ""
    @State private var notes = ""
    @State private var showingSuccessAlert = false
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var showingCitySuggestions = false
    @State private var isSelectingSuggestion = false
    @State private var isEditingExistingRecord = false
    @State private var selectedDayType: DayType = .work
    @State private var showingDatePicker = false
    @State private var animateForm = false
    @State private var showingSettings = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case drivingHours
        case workingHours
        case kilometers
        case city
        case notes
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
    
    // Kontrola, zda je datum vybratelné
    private func isSelectable(_ date: Date) -> Bool {
        return isWorkDay(date) && !isHoliday(date)
    }
    
    // Kontrola, zda již existuje záznam pro dané datum
    private func hasExistingRecord(for date: Date) -> Bool {
        let calendar = Calendar.current
        
        // Použít stejnou logiku jako ve StatisticsView - filtrovat prázdné měsíce
        let baseReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty }
        
        return baseReports.contains { report in
            report.workDays.contains { workDay in
                calendar.isDate(workDay.date, inSameDayAs: date)
            }
        }
    }
    
    // Kontrola, zda je datum dostupné pro nový záznam
    private func isAvailableForNewRecord(_ date: Date) -> Bool {
        return isSelectable(date) && !hasExistingRecord(for: date)
    }
    
    // Common cities for autocomplete (unikátní)
    private let commonCities: [String] = [
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
    
    private var filteredCities: [String] {
        if city.isEmpty {
            return []
        }
        let searchTerm = city.lowercased()
        let normalizedSearchTerm = removeDiacritics(searchTerm)
        let filtered = commonCities.filter { cityName in
            let normalizedCityName = removeDiacritics(cityName.lowercased())
            return cityName.lowercased().contains(searchTerm) || 
                   normalizedCityName.contains(normalizedSearchTerm)
        }
        return Array(Set(filtered)).sorted()
    }
    
    private func removeDiacritics(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "č", with: "c")
            .replacingOccurrences(of: "ď", with: "d")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "ě", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ň", with: "n")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ř", with: "r")
            .replacingOccurrences(of: "š", with: "s")
            .replacingOccurrences(of: "ť", with: "t")
            .replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ů", with: "u")
            .replacingOccurrences(of: "ý", with: "y")
            .replacingOccurrences(of: "ž", with: "z")
            .replacingOccurrences(of: "Á", with: "A")
            .replacingOccurrences(of: "Č", with: "C")
            .replacingOccurrences(of: "Ď", with: "D")
            .replacingOccurrences(of: "É", with: "E")
            .replacingOccurrences(of: "Ě", with: "E")
            .replacingOccurrences(of: "Í", with: "I")
            .replacingOccurrences(of: "Ň", with: "N")
            .replacingOccurrences(of: "Ó", with: "O")
            .replacingOccurrences(of: "Ř", with: "R")
            .replacingOccurrences(of: "Š", with: "S")
            .replacingOccurrences(of: "Ť", with: "T")
            .replacingOccurrences(of: "Ú", with: "U")
            .replacingOccurrences(of: "Ů", with: "U")
            .replacingOccurrences(of: "Ý", with: "Y")
            .replacingOccurrences(of: "Ž", with: "Z")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                Form {
                // Informační text pro existující záznam
                if isEditingExistingRecord {
                    Section {
                        VStack {
                            Text(localizationManager.localizedString("existingRecord"))
                                .font(.headline)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                            
                            Text(localizationManager.localizedString("recordLoaded"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                
                Section(localizationManager.localizedString("date")) {
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker(localizationManager.localizedString("date"), selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .onTapGesture {
                                showingDatePicker = true
                            }
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateForm)
                        
                        if !isSelectable(selectedDate) {
                            Text("(\(localizationManager.localizedString("weekendHoliday")))")
                                .foregroundStyle(.red)
                                .font(.caption)
                        } else if hasExistingRecord(for: selectedDate) {
                            if isEditingExistingRecord {
                                Text("(\(localizationManager.localizedString("recordLoaded")))")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                            } else {
                                Text("(\(localizationManager.localizedString("alreadyHasRecord")))")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                    .onChange(of: selectedDate) { _, newDate in
                        print("DEBUG: Změna data na \(newDate.formatted(.dateTime.day().month().year()))")
                        print("DEBUG: hasExistingRecord = \(hasExistingRecord(for: newDate))")
                        
                        // Zkontrolovat, zda existuje záznam pro vybrané datum
                        if hasExistingRecord(for: newDate) {
                            // Načíst existující záznam
                            loadExistingRecord(for: newDate)
                            isEditingExistingRecord = true
                            print("DEBUG: Načítám existující záznam pro \(newDate.formatted(.dateTime.day().month().year()))")
                        } else {
                            // Nový záznam
                            clearFormForNewRecord()
                            isEditingExistingRecord = false
                            print("DEBUG: Vytvářím nový záznam pro \(newDate.formatted(.dateTime.day().month().year()))")
                        }
                        
                        // Zavřít DatePicker po výběru
                        showingDatePicker = false
                    }
                }
                
                Section("Typ dne") {
                    Picker("Typ dne", selection: $selectedDayType) {
                        ForEach(DayType.allCases, id: \.self) { dayType in
                            Text(dayType.displayName).tag(dayType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isEditingExistingRecord)
                    .onChange(of: selectedDayType) { _, newType in
                        // Vymazat všechna pole při výběru dovolené nebo lékaře
                        if newType == .vacation || newType == .sick {
                            drivingHours = ""
                            workingHours = ""
                            kilometers = ""
                            city = ""
                            notes = ""
                        }
                    }
                }
                
                // Zobrazit pouze pokud není dovolená nebo lékař
                if selectedDayType == .work {
                    Section("Časové údaje") {
                        HStack {
                            Text(localizationManager.localizedString("drivingTime"))
                            Spacer()
                            TextField("0.0h", text: $drivingHours)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isEditingExistingRecord)
                                .focused($focusedField, equals: .drivingHours)
                        }
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateForm)
                        
                        HStack {
                            Text(localizationManager.localizedString("workingTime"))
                            Spacer()
                            TextField("0.0h", text: $workingHours)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isEditingExistingRecord)
                                .focused($focusedField, equals: .workingHours)
                        }
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateForm)
                    }
                    
                    Section("Kilometry a místo") {
                        HStack {
                            Text(localizationManager.localizedString("kilometersDriven"))
                            Spacer()
                            TextField("0", text: $kilometers)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .disabled(isEditingExistingRecord)
                                .focused($focusedField, equals: .kilometers)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(localizationManager.localizedString("city"))
                                Spacer()
                                TextField(localizationManager.localizedString("enterCity"), text: $city)
                                    .multilineTextAlignment(.trailing)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .autocapitalization(.none)
                                    .disabled(isEditingExistingRecord)
                                    .focused($focusedField, equals: .city)
                                    .onChange(of: city) { _, newValue in
                                        // Show suggestions only when typing, not when selecting
                                        if !isSelectingSuggestion && !newValue.isEmpty && !filteredCities.isEmpty {
                                            showingCitySuggestions = true
                                        } else if newValue.isEmpty {
                                            showingCitySuggestions = false
                                        }
                                        isSelectingSuggestion = false
                                    }
                                    .onTapGesture {
                                        if !city.isEmpty && !filteredCities.isEmpty {
                                            showingCitySuggestions = true
                                        }
                                    }
                            }
                            
                            if !filteredCities.isEmpty && showingCitySuggestions {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(filteredCities.prefix(5), id: \.self) { suggestion in
                                        Button(action: {
                                            isSelectingSuggestion = true
                                            city = suggestion
                                            showingCitySuggestions = false
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption)
                                                Text(suggestion)
                                                    .foregroundStyle(.primary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .onTapGesture {
                            // Hide suggestions when tapping outside
                            if showingCitySuggestions {
                                showingCitySuggestions = false
                            }
                        }
                    }
                    
                    Section(localizationManager.localizedString("notes")) {
                        TextField(localizationManager.localizedString("enterNotes"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .disabled(isEditingExistingRecord)
                            .focused($focusedField, equals: .notes)
                    }
                }
                
                // Tlačítko se nezobrazuje při editaci existujícího záznamu
                if !isEditingExistingRecord {
                    Section {
                        Button(action: {
                            saveWorkDay()
                        }) {
                            Text(localizationManager.localizedString("saveRecord"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                }
                .padding(.top, 16)
            }
            .navigationTitle(localizationManager.localizedString("records"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        selectedTab = 0 // Go to home tab
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                }
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
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }
            )
            .alert("Úspěch", isPresented: $showingSuccessAlert) {
                Button(action: {
                    clearForm()
                }) {
                    Text(localizationManager.localizedString("ok"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } message: {
                Text(isEditingExistingRecord ? "Výkaz byl úspěšně aktualizován." : "Výkaz byl úspěšně uložen.")
            }
            .alert("Chyba validace", isPresented: $showingValidationAlert) {
                Button(action: { }) {
                    Text(localizationManager.localizedString("ok"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateForm = true
                }
            }
        }
    }
    
    private func saveWorkDay() {
        validationErrors = []
        
        // Validation - check if selected date is a work day
        if !isSelectable(selectedDate) {
            validationErrors.append("Nelze vytvořit záznam pro víkend nebo svátek")
        }
        
        // Validation - check if record already exists for this date (only for new records)
        if hasExistingRecord(for: selectedDate) && !isEditingExistingRecord {
            validationErrors.append("Již máte záznam pro tento den")
        }
        
        // Validation - all fields except notes are required only for work days
        if selectedDayType == .work {
            if drivingHours.isEmpty {
                validationErrors.append("Vyplňte dobu jízdy")
            }
            
            if workingHours.isEmpty {
                validationErrors.append("Vyplňte dobu práce")
            }
            
            if kilometers.isEmpty {
                validationErrors.append("Vyplňte ujeté kilometry")
            }
            
            if city.isEmpty {
                validationErrors.append("Vyplňte město")
            }
        }
        
        if !validationErrors.isEmpty {
            showingValidationAlert = true
            return
        }
        
        if isEditingExistingRecord {
            // Aktualizovat existující záznam
            let calendar = Calendar.current
            if let report = viewModel.monthlyReports.first(where: { report in
                calendar.isDate(report.month, equalTo: selectedDate, toGranularity: .month)
            }) {
                if let existingWorkDay = report.workDays.first(where: { workDay in
                    calendar.isDate(workDay.date, inSameDayAs: selectedDate)
                }) {
                    var updatedWorkDay = existingWorkDay
                    updatedWorkDay.drivingHours = drivingHours.toDouble() ?? 0.0
                    updatedWorkDay.workingHours = workingHours.toDouble() ?? 0.0
                    updatedWorkDay.kilometers = kilometers.toDouble() ?? 0.0
                    updatedWorkDay.city = city
                    updatedWorkDay.notes = notes
                    updatedWorkDay.dayType = selectedDayType
                    
                    viewModel.updateWorkDay(updatedWorkDay, in: report)
                    showingSuccessAlert = true
                }
            }
        } else {
            // Vytvořit nový záznam
            let workDay = WorkDay(
                date: selectedDate,
                drivingHours: drivingHours.toDouble() ?? 0.0,
                workingHours: workingHours.toDouble() ?? 0.0,
                kilometers: kilometers.toDouble() ?? 0.0,
                city: city,
                notes: notes,
                isCompleted: true,
                dayType: selectedDayType
            )
            
            viewModel.addWorkDay(workDay)
            showingSuccessAlert = true
        }
    }
    
    private func loadExistingRecord(for date: Date) {
        let calendar = Calendar.current
        
        // Použít stejnou logiku jako ve StatisticsView - filtrovat prázdné měsíce
        let baseReports = viewModel.monthlyReports.filter { !$0.workDays.isEmpty }
        
        if let report = baseReports.first(where: { report in
            calendar.isDate(report.month, equalTo: date, toGranularity: .month)
        }) {
            if let workDay = report.workDays.first(where: { workDay in
                calendar.isDate(workDay.date, inSameDayAs: date)
            }) {
                // Načíst data do formuláře
                drivingHours = String(format: "%.1f", workDay.drivingHours)
                workingHours = String(format: "%.1f", workDay.workingHours)
                kilometers = String(format: "%.0f", workDay.kilometers)
                city = workDay.city
                notes = workDay.notes
                selectedDayType = workDay.dayType
                
                print("DEBUG: Načten existující záznam pro \(date.formatted(.dateTime.day().month().year()))")
                print("DEBUG: Data - jízda: \(drivingHours)h, práce: \(workingHours)h, km: \(kilometers), město: \(city)")
                print("DEBUG: Report nalezen: \(report.month.formatted(.dateTime.month().year())) s \(report.workDays.count) workDays")
            } else {
                print("DEBUG: WorkDay nebyl nalezen v reportu")
            }
        } else {
            print("DEBUG: Report nebyl nalezen pro měsíc \(date.formatted(.dateTime.month().year()))")
            print("DEBUG: Celkem reportů: \(viewModel.monthlyReports.count)")
            print("DEBUG: Filtrovaných reportů: \(baseReports.count)")
        }
    }
    
    private func clearFormForNewRecord() {
        drivingHours = ""
        workingHours = ""
        kilometers = ""
        city = ""
        notes = ""
        selectedDayType = .work
    }
    
    private func clearForm() {
        drivingHours = ""
        workingHours = ""
        kilometers = ""
        city = ""
        notes = ""
        selectedDate = Date()
        isEditingExistingRecord = false
        selectedDayType = .work
        // Navigate to home tab after clearing form
        selectedTab = 0
    }
}

#Preview {
    MechanicTabView()
} 