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
    @State private var selectedTab = 0
    @State private var animateTabTransition = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 0. Hlavní stránka
                HomeView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Přehled")
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
                        Text("Záznamy")
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
                        Text("Historie")
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
                        Text("Palivo")
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
                        Text("Zákazníci")
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
    @State private var selectedDate = Date()
    @State private var customerName = ""
    @State private var drivingHours = ""
    @State private var workingHours = ""
    @State private var kilometers = ""
    @State private var city = ""
    @State private var notes = ""
    @State private var showingSuccessAlert = false
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var showingCitySuggestions = false
    @State private var showingCustomerSuggestions = false
    @State private var isSelectingSuggestion = false
    @State private var selectedDayType: DayType = .work
    @State private var showingDatePicker = false
    @State private var animateForm = false
    @State private var showingSettings = false
    @State private var drivingTimePicker = Calendar.current.date(from: DateComponents(hour: 1, minute: 11)) ?? Date()
    @State private var workingTimePicker = Calendar.current.date(from: DateComponents(hour: 1, minute: 11)) ?? Date()
    @AppStorage("useTimePicker") private var useTimePicker = false
    @FocusState private var focusedField: Field?
    
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
    
    // Kontrola, zda je datum dostupné pro nový záznam - nyní vždy true (umožnit více výkazů za den)
    private func isAvailableForNewRecord(_ date: Date) -> Bool {
        return true
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
    
    private var filteredCustomers: [Customer] {
        if customerName.isEmpty {
            return []
        }
        let searchTerm = customerName.lowercased()
        let normalizedSearchTerm = removeDiacritics(searchTerm)
        let filtered = viewModel.customers.filter { customer in
            let normalizedCustomerName = removeDiacritics(customer.name.lowercased())
            return customer.name.lowercased().contains(searchTerm) || 
                   normalizedCustomerName.contains(normalizedSearchTerm)
        }
        return filtered
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
    
    private func selectCustomer(_ customer: Customer) {
        customerName = customer.name
        city = customer.city
        kilometers = String(customer.kilometers)
        drivingHours = String(customer.drivingTime)
        
        // Aktualizovat time picker pokud je zapnutý
        if useTimePicker {
            updateTimePickerValues()
        }
        
        // Zavřít klávesnici a našeptávání
        showingCustomerSuggestions = false
        isSelectingSuggestion = true
        focusedField = nil // Zavře klávesnici
    }
    
    private func findOrCreateCustomer() -> Customer? {
        // Najít existujícího zákazníka
        if let existingCustomer = viewModel.customers.first(where: { $0.name.lowercased() == customerName.lowercased() }) {
            // Vrátit existujícího zákazníka BEZ aktualizace jeho dat
            // Data zákazníka zůstávají stejná (základní profil)
            // Pouze se použijí pro vyplnění výkazu
            return existingCustomer
        }
        
        // Pokud zákazník neexistuje, vytvořit nového
        let newCustomer = Customer(
            name: customerName,
            city: city,
            kilometers: Double(kilometers) ?? 0.0,
            drivingTime: drivingHours.toDouble() ?? 0.0
        )
        viewModel.addCustomer(newCustomer)
        return newCustomer
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                Form {
                Section("Datum") {
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker("Datum", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .onTapGesture {
                                showingDatePicker = true
                            }
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateForm)
                        
                        if hasExistingRecord(for: selectedDate) {
                            Text("(Existující záznam)")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                    .onChange(of: selectedDate) { _, newDate in
                        // Vždy vytvořit nový záznam - ne načítat existující
                        isEditingExistingRecord = false
                        clearFormForNewRecord()
                        
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
                    .onChange(of: selectedDayType) { _, newType in
                        // Vymazat všechna pole při výběru dovolené nebo lékaře
                        if newType == .vacation || newType == .sick {
                            customerName = ""
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
                    Section("Zákazníci") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Zákazník")
                                Spacer()
                                TextField("Zadejte jméno zákazníka", text: $customerName)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .customerName)
                                    .onSubmit {
                                        // Enter na klávesnici - vybrat prvního zákazníka
                                        if !filteredCustomers.isEmpty {
                                            selectCustomer(filteredCustomers.first!)
                                        }
                                    }
                                    .onChange(of: customerName) { _, newValue in
                                        // Pouze pokud uživatel skutečně píše (ne automatické doplňování) a pole není disabled
                                        if !isSelectingSuggestion {
                                            showingCustomerSuggestions = !newValue.isEmpty && !filteredCustomers.isEmpty
                                        } else {
                                            showingCustomerSuggestions = false
                                        }
                                        // Resetovat flag s malým zpožděním
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            isSelectingSuggestion = false
                                        }
                                    }
                            }
                            
                            // Zobrazit návrhy zákazníků
                            if showingCustomerSuggestions && !filteredCustomers.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(filteredCustomers.prefix(5), id: \.id) { customer in
                                        Button(action: {
                                            selectCustomer(customer)
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(customer.name)
                                                        .foregroundStyle(.primary)
                                                        .font(.system(size: 16, weight: .medium))
                                                    Text("\(String(format: "%.0f", customer.kilometers)) km • \(customer.drivingTime.formattedTime(useTimePicker: useTimePicker))h")
                                                        .foregroundStyle(.secondary)
                                                        .font(.system(size: 14))
                                                }
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
                                .padding(.top, 8)
                            }
                        }
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateForm)
                    }
                    
                    Section("Časové údaje") {
                        TimeInputField(
                            title: "Doba jízdy",
                            textValue: $drivingHours,
                            timeValue: $drivingTimePicker,
                            useTimePicker: useTimePicker,
                            placeholder: "0.0h",
                            focusedField: $focusedField,
                            field: .drivingHours,
                            disabled: isEditingExistingRecord
                        )
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateForm)
                        
                        TimeInputField(
                            title: "Doba práce",
                            textValue: $workingHours,
                            timeValue: $workingTimePicker,
                            useTimePicker: useTimePicker,
                            placeholder: "0.0h",
                            focusedField: $focusedField,
                            field: .workingHours,
                            disabled: isEditingExistingRecord
                        )
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateForm)
                    }
                    
                    Section("Kilometry a místo") {
                        HStack {
                            Text("Ujeté kilometry")
                            Spacer()
                            TextField("0", text: $kilometers)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .kilometers)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Město")
                                Spacer()
                                TextField("Zadejte město", text: $city)
                                    .multilineTextAlignment(.trailing)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .city)
                                    .onChange(of: city) { _, newValue in
                                        // Show suggestions only when typing, not when selecting, and field is not disabled
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
                    
                    Section("Poznámky") {
                        TextField("Zadejte poznámky", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($focusedField, equals: .notes)
                    }
                }
                
                // Tlačítko pro uložení výkazu
                Section {
                    Button(action: {
                        saveWorkDay()
                    }) {
                        Text("Uložit výkaz")
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
                .padding(.top, 8)
                .onTapGesture {
                    // Zavřít klávesnici při kliknutí mimo textové pole
                    focusedField = nil
                }
            }
            .navigationTitle("Záznamy")
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
            .tint(.blue) // změní barvu i ikonky zpět

            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
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
                    Text("OK")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } message: {
                Text("Výkaz byl úspěšně uložen.")
            }
            .alert("Chyba validace", isPresented: $showingValidationAlert) {
                Button(action: { }) {
                    Text("OK")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .onAppear {
                // Vždy vytvořit nový záznam
                
                withAnimation(.easeOut(duration: 0.8)) {
                    animateForm = true
                }
            }
        }
    }
    
    private func saveWorkDay() {
        validationErrors = []
        
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
        
        // Najít nebo vytvořit zákazníka
        if !customerName.isEmpty {
            _ = findOrCreateCustomer()
        }
        
        // Vytvořit nový záznam
        let workDay = WorkDay(
            date: selectedDate,
            customerName: customerName,
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
    
    
    private func clearFormForNewRecord() {
        customerName = ""
        drivingHours = ""
        workingHours = ""
        kilometers = ""
        city = ""
        notes = ""
        selectedDayType = .work
        updateTimePickerValues()
    }
    
    private func updateTimePickerValues() {
        // Převést desetinné hodiny na čas pro time picker
        if let drivingDecimalHours = drivingHours.toDouble() {
            let hours = Int(drivingDecimalHours)
            let minutes = Int((drivingDecimalHours - Double(hours)) * 60)
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = hours
            components.minute = minutes
            if let date = calendar.date(from: components) {
                drivingTimePicker = date
            }
        }
        
        if let workingDecimalHours = workingHours.toDouble() {
            let hours = Int(workingDecimalHours)
            let minutes = Int((workingDecimalHours - Double(hours)) * 60)
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = hours
            components.minute = minutes
            if let date = calendar.date(from: components) {
                workingTimePicker = date
            }
        }
    }
    
    private func clearForm() {
        customerName = ""
        drivingHours = ""
        workingHours = ""
        kilometers = ""
        city = ""
        notes = ""
        selectedDate = Date()
        selectedDayType = .work
        updateTimePickerValues()
        // Navigate to home tab after clearing form
        selectedTab = 0
    }
}

#Preview {
    MechanicTabView()
} 
