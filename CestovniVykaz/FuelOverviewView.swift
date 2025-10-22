//
//  FuelOverviewView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

struct FuelOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @State private var selectedDate = Date()
    @State private var animateContent = false
    @State private var showingSettings = false
    
    // Get last 3 fuel entries
    private var lastThreeEntries: [FuelEntry] {
        Array(viewModel.fuelEntries.prefix(3))
    }
    
    // Get fuel entries from last 3 months
    private var lastThreeMonthsEntries: [FuelEntry] {
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        return viewModel.fuelEntries.filter { entry in
            entry.date >= threeMonthsAgo
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                ScrollView {
                    VStack(spacing: 20) {
                    // Last 3 fuel entries
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Poslední tankování")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            NavigationLink(destination: FuelEntrySheet(viewModel: viewModel, selectedTab: $selectedTab)) {
                                Text("Nové tankování")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if lastThreeEntries.isEmpty {
                            EmptyState(
                                icon: "fuelpump",
                                title: "Žádné tankování",
                                subtitle: "Začněte přidávat tankování"
                            )
                        } else {
                            List {
                                ForEach(lastThreeEntries) { entry in
                                    FuelEntryCard(entry: entry, viewModel: viewModel)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                        .offset(y: animateContent ? 0 : 20)
                                        .animation(.easeOut(duration: 0.6).delay(Double(lastThreeEntries.firstIndex(where: { $0.id == entry.id }) ?? 0) * 0.1), value: animateContent)
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                }
                            }
                            .listStyle(PlainListStyle())
                            .scrollContentBackground(.hidden)
                            .frame(height: CGFloat(lastThreeEntries.count * 80 + 20))
                        }
                    }
                    .cardStyleSecondary()
                    .padding(.horizontal)
                    
                    // Calendar section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Kalendář tankování")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        
                        FuelCalendarView(
                            fuelEntries: lastThreeMonthsEntries,
                            selectedDate: $selectedDate
                        )
                        .cardStyleSecondary()
                        .padding(.horizontal)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                    }
                    
                    // Selected date details
                    if let selectedEntry = lastThreeMonthsEntries.first(where: { entry in
                        Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
                    }) {
                        FuelEntryDetailCard(entry: selectedEntry)
                            .padding(.horizontal)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
                    }
                    
                    Spacer(minLength: 20)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Palivo")
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
                    animateContent = true
                }
            }
        }
    }
}

// MARK: - Fuel Entry Card
struct FuelEntryCard: View {
    let entry: FuelEntry
    @ObservedObject var viewModel: MechanicViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.formatted(.dateTime.day().month()))
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(entry.date.formatted(.dateTime.year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)
            
            // Fuel details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: entry.fuelType.icon)
                        .foregroundStyle(.blue)
                        .font(.caption)
                    
                    Text(entry.fuelType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                Text(entry.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(String(format: "%.1f L", entry.fuelAmount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.2f Kč/L", entry.calculatedPricePerLiter))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f Kč", entry.price))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Smazat", systemImage: "trash")
            }
        }
        .alert("Smazat tankování", isPresented: $showingDeleteAlert) {
            Button("Zrušit", role: .cancel) { }
            Button("Smazat", role: .destructive) {
                viewModel.deleteFuelEntry(entry)
            }
        } message: {
            Text("Opravdu chcete smazat tankování z \(entry.date.formatted(.dateTime.day().month().year()))?")
        }
    }
}

// MARK: - Fuel Calendar View
struct FuelCalendarView: View {
    let fuelEntries: [FuelEntry]
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(fuelEntries: [FuelEntry], selectedDate: Binding<Date>) {
        self.fuelEntries = fuelEntries
        self._selectedDate = selectedDate
        self.dateFormatter.dateFormat = "MMMM yyyy"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.blue)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach([
                    "Po", "Út", "St", "Čt", "Pá", "So", "Ne"
                ], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasFuelEntry: hasFuelEntry(for: date),
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
    }
    
    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func hasFuelEntry(for date: Date) -> Bool {
        return fuelEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasFuelEntry: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .white : (isCurrentMonth ? .primary : .secondary))
                
                if hasFuelEntry {
                    Circle()
                        .fill(isSelected ? .white : .blue)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isSelected ? .blue : .clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fuel Entry Detail Card
struct FuelEntryDetailCard: View {
    let entry: FuelEntry
    
    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Tankování")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Datum" + ":")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.date.formatted(.dateTime.day().month().year().hour().minute()))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Místo" + ":")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.location)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Typ paliva" + ":")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.fuelType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    
                    HStack {
                        Text("Množství" + ":")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f L", entry.fuelAmount))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Celková cena" + ":")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f Kč", entry.price))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Cena za litr" + ":")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.2f Kč/L", entry.calculatedPricePerLiter))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    
                    if !entry.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Poznámky" + ":")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(entry.notes)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .cardStyleSecondary()
    }
}


// MARK: - Fuel Entry Sheet
struct FuelEntrySheet: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var fuelAmount = ""
    @State private var price = ""
    @State private var pricePerLiter = ""
    @State private var selectedFuelType: FuelType = .diesel
    @State private var location = ""
    @State private var notes = ""
    @State private var showingSuccessAlert = false
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var showingLocationSuggestions = false
    @State private var isSelectingSuggestion = false
    @State private var animateForm = false
    
    // Common fuel stations for autocomplete
    private let commonStations: [String] = [
        "Shell", "Orlen", "Čepro", "MOL", "ONO"
    ]
    
    private var filteredStations: [String] {
        if location.isEmpty {
            return []
        }
        return commonStations.filter { station in
            station.lowercased().contains(location.lowercased())
        }
    }
    
    var body: some View {
        Form {
                Section("Datum a čas") {
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker("Datum", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateForm)
                        
                        Text("Aktuální datum a čas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Druh paliva") {
                    Picker("Druh paliva", selection: $selectedFuelType) {
                        ForEach(FuelType.allCases, id: \.self) { fuelType in
                            HStack {
                                Image(systemName: fuelType.icon)
                                    .foregroundStyle(.blue)
                                Text(fuelType.displayName)
                            }
                            .tag(fuelType)
                        }
                    }
                    .pickerStyle(.menu)
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateForm)
                }
                
                Section("Množství a cena") {
                    HStack {
                        Text("Množství")
                        Spacer()
                        TextField("0.0", text: $fuelAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("litrů")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateForm)
                    
                    HStack {
                        Text("Cena za litr")
                        Spacer()
                        TextField("0.0", text: $pricePerLiter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("Kč/l")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateForm)
                    
                    HStack {
                        Text("Celková cena")
                        Spacer()
                        TextField("0.0", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("Kč")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateForm)
                    
                    // Auto-calculation between price per liter and total price
                    if !fuelAmount.isEmpty && !pricePerLiter.isEmpty,
                       let amount = fuelAmount.toDouble(), let pricePerL = pricePerLiter.toDouble(),
                       amount > 0 {
                        HStack {
                            Text("Vypočtená celková cena" + ":")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f Kč", amount * pricePerL))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 8)
                        .onAppear {
                            price = String(format: "%.0f", amount * pricePerL)
                        }
                    } else if !fuelAmount.isEmpty && !price.isEmpty,
                              let amount = fuelAmount.toDouble(), let totalPrice = price.toDouble(),
                              amount > 0 {
                        HStack {
                            Text("Vypočtená cena za litr" + ":")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.2f Kč/L", totalPrice / amount))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 8)
                        .onAppear {
                            pricePerLiter = String(format: "%.2f", totalPrice / amount)
                        }
                    }
                }
                
                Section("Místo tankování") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Čerpací stanice")
                            Spacer()
                            TextField("Zadejte stanici", text: $location)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .autocapitalization(.none)
                                .onChange(of: location) { _, newValue in
                                    // Show suggestions only when typing, not when selecting
                                    if !isSelectingSuggestion && !newValue.isEmpty && !filteredStations.isEmpty {
                                        showingLocationSuggestions = true
                                    } else if newValue.isEmpty {
                                        showingLocationSuggestions = false
                                    }
                                    isSelectingSuggestion = false
                                }
                                .onTapGesture {
                                    if !location.isEmpty && !filteredStations.isEmpty {
                                        showingLocationSuggestions = true
                                    }
                                }
                        }
                        
                        if !filteredStations.isEmpty && showingLocationSuggestions {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(filteredStations.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        isSelectingSuggestion = true
                                        location = suggestion
                                        showingLocationSuggestions = false
                                    }) {
                                        HStack {
                                            Image(systemName: "fuelpump.fill")
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
                        if showingLocationSuggestions {
                            showingLocationSuggestions = false
                        }
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(1.0), value: animateForm)
                }
                
                Section("Poznámka") {
                    TextField("Zadejte poznámku...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .opacity(animateForm ? 1.0 : 0.0)
                        .offset(y: animateForm ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(1.2), value: animateForm)
                }
                
                Section {
                    Button(action: {
                        saveFuelEntry()
                    }) {
                        Text("Uložit tankování")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: animateForm)
                }
            }
            .onTapGesture {
                // Zavřít klávesnici při kliknutí mimo textové pole
                hideKeyboard()
            }
            .navigationTitle("Nové tankování")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Úspěch", isPresented: $showingSuccessAlert) {
                Button(action: {
                    clearForm()
                    dismiss()
                }) {
                    Text("OK")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } message: {
                Text("Tankování uloženo")
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
                withAnimation(.easeOut(duration: 0.8)) {
                    animateForm = true
                }
            }
    }
    
    private func saveFuelEntry() {
        validationErrors = []
        
        // Validation
        if fuelAmount.isEmpty {
            validationErrors.append("Vyplňte množství paliva")
        }
        
        if price.isEmpty {
            validationErrors.append("Vyplňte cenu")
        }
        
        if location.isEmpty {
            validationErrors.append("Vyplňte místo tankování")
        }
        
        if let amount = fuelAmount.toDouble(), amount <= 0 {
            validationErrors.append("Množství paliva musí být větší než 0")
        }
        
        if let totalPrice = price.toDouble(), totalPrice <= 0 {
            validationErrors.append("Cena musí být větší než 0")
        }
        
        if !validationErrors.isEmpty {
            showingValidationAlert = true
            return
        }
        
        // Create and save fuel entry
        let fuelEntry = FuelEntry(
            date: selectedDate,
            fuelAmount: fuelAmount.toDouble() ?? 0,
            price: price.toDouble() ?? 0,
            fuelType: selectedFuelType,
            location: location,
            notes: notes
        )
        
        viewModel.addFuelEntry(fuelEntry)
        showingSuccessAlert = true
    }
    
    private func clearForm() {
        fuelAmount = ""
        price = ""
        pricePerLiter = ""
        location = ""
        notes = ""
        selectedDate = Date()
        selectedFuelType = .diesel
    }
}

#Preview {
    FuelOverviewView(viewModel: MechanicViewModel(), selectedTab: .constant(0))
}
