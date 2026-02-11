//
//  CustomerView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI


struct CustomerView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var animateContent = false
    @State private var showingSettings = false
    
    // Filtered customers based on search
    private var filteredCustomers: [Customer] {
        let customers: [Customer]
        if searchText.isEmpty {
            customers = viewModel.customers
        } else {
            customers = viewModel.customers.filter { customer in
                customer.name.localizedCaseInsensitiveContains(searchText) ||
                customer.city.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Seřadit podle abecedy podle názvu zákazníka
        return customers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Add new customer field
                NavigationLink(destination: AddCustomerSheet(viewModel: viewModel, selectedTab: $selectedTab)) {
                    HStack {
                        Text("Přidat nového zákazníka")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Vyhledat zákazníky", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Customer list
                if filteredCustomers.isEmpty {
                    EmptyState(
                        icon: "person.2",
                        title: searchText.isEmpty ? "Žádní zákazníci" : "Žádní zákazníci",
                        subtitle: searchText.isEmpty ? "Začněte přidáváním zákazníků" : "Zkuste jiné vyhledávání"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(DesignSystem.Animation.slow, value: animateContent)
                } else {
                    List {
                        ForEach(filteredCustomers) { customer in
                            CustomerRow(customer: customer, viewModel: viewModel, selectedTab: $selectedTab)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(Double(filteredCustomers.firstIndex(where: { $0.id == customer.id }) ?? 0) * 0.1), value: animateContent)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .padding(.top, 4)
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
                
                Spacer()
            }
            .navigationTitle("Zákazníci")
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
    
    // MARK: - Customer Row
    struct CustomerRow: View {
        let customer: Customer
        @ObservedObject var viewModel: MechanicViewModel
        @Binding var selectedTab: Int
        @State private var showingDeleteConfirmation = false
        @AppStorage("useTimePicker") private var useTimePicker = false
        
        var body: some View {
            NavigationLink(destination: EditCustomerSheet(customer: customer, viewModel: viewModel, selectedTab: $selectedTab)) {
                HStack(spacing: 16) {
                    // People icon (left side)
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 24, height: 24)
                    
                    // Customer info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(customer.name)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text(customer.city)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Statistics
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f km", customer.kilometers))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text(customer.drivingTime.formattedTime(useTimePicker: useTimePicker) + " h")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 60, alignment: .trailing)
                    
                    // Navigation arrow
                    //Image(systemName: "chevron.right")
                    //    .font(.caption)
                    //    .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .cancel) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Smazat", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            .confirmationDialog("Smazat zákazníka", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Zrušit", role: .cancel) {
                    showingDeleteConfirmation = false
                }
                Button("Smazat", role: .destructive) {
                    viewModel.deleteCustomer(customer)
                    showingDeleteConfirmation = false
                }
            } message: {
                Text("Opravdu chcete smazat zákazníka \(customer.name)?")
            }
        }
    }
    
    // MARK: - Add Customer Sheet
    struct AddCustomerSheet: View {
        @ObservedObject var viewModel: MechanicViewModel
        @Binding var selectedTab: Int
        @Environment(\.dismiss) private var dismiss
        @State private var customerName = ""
        @State private var city = ""
        @State private var kilometers = ""
        @State private var drivingTime = ""
        @State private var showingSuccessAlert = false
        @State private var showingValidationAlert = false
        @State private var validationErrors: [String] = []
        @State private var animateForm = false
        @State private var drivingTimePicker = Calendar.current.date(from: DateComponents(hour: 1, minute: 11)) ?? Date()
        @AppStorage("useTimePicker") private var useTimePicker = false
        @FocusState private var focusedField: Field?
        
        var body: some View {
            Form {
                Section("Informace o zákazníkovi") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Jméno zákazníka", text: $customerName)
                            .focused($focusedField, equals: .customerName)
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateForm)
                        
                        Text("Město")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Město", text: $city)
                            .focused($focusedField, equals: .city)
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateForm)
                        
                        Text("Město")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Jízda") {
                    HStack {
                        Text("Kilometry")
                        Spacer()
                        TextField("0", text: $kilometers)
                            .focused($focusedField, equals: .kilometers)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("Km")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateForm)
                    
                    HStack {
                        Text("Čas jízdy")
                        Spacer()
                        
                        if useTimePicker {
                            HalfHourTimePicker(selection: $drivingTimePicker)
                                .onChange(of: drivingTimePicker) { _, newValue in
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.hour, .minute], from: newValue)
                                    let hours = Double(components.hour ?? 0)
                                    let minutes = Double(components.minute ?? 0)
                                    let decimalHours = hours + (minutes / 60.0)
                                    drivingTime = String(format: "%.1f", decimalHours)
                                }
                        } else {
                            TextField("0.0", text: $drivingTime)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .drivingTime)
                                .onChange(of: drivingTime) { _, newValue in
                                    if let decimalHours = newValue.toDouble() {
                                        let hours = Int(decimalHours)
                                        let minutes = Int((decimalHours - Double(hours)) * 60)
                                        let roundedMinute = minutes < 15 ? 0 : 30
                                        let calendar = Calendar.current
                                        var components = DateComponents()
                                        components.hour = hours
                                        components.minute = roundedMinute
                                        if let date = calendar.date(from: components) {
                                            drivingTimePicker = date
                                        }
                                    }
                                }
                        }
                        
                        Text("h")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateForm)
                }
                
                Section {
                    Button(action: {
                        saveCustomer()
                    }) {
                        Text("Uložit změny")
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
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateForm)
                }
            }
            .onTapGesture {
                // Zavřít klávesnici při kliknutí mimo textové pole
                focusedField = nil
            }
            .navigationTitle("Nový zákazník")
            .navigationBarTitleDisplayMode(.inline)
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
                Text("Město")
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
        
        private func saveCustomer() {
            // Zavřít klávesnici
            focusedField = nil
            
            validationErrors = []
            
            // Validation
            if customerName.isEmpty {
                validationErrors.append("Vyplňte jméno zákazníka")
            }
            
            if city.isEmpty {
                validationErrors.append("Vyplňte město")
            }
            
            if kilometers.isEmpty {
                validationErrors.append("Vyplňte počet kilometrů")
            }
            
            if drivingTime.isEmpty {
                validationErrors.append("Vyplňte čas jízdy")
            }
            
            if let km = kilometers.toDouble(), km <= 0 {
                validationErrors.append("Počet kilometrů musí být větší než 0")
            }
            
            if let time = drivingTime.toDouble(), time <= 0 {
                validationErrors.append("Čas jízdy musí být větší než 0")
            }
            
            if !validationErrors.isEmpty {
                showingValidationAlert = true
                return
            }
            
            // Create and save customer
            let customer = Customer(
                name: customerName,
                city: city,
                kilometers: kilometers.toDouble() ?? 0,
                drivingTime: drivingTime.toDouble() ?? 0
            )
            
            viewModel.addCustomer(customer)
            showingSuccessAlert = true
        }
        
        private func clearForm() {
            customerName = ""
            city = ""
            kilometers = ""
            drivingTime = ""
        }
    }
    
    // MARK: - Edit Customer Sheet
    struct EditCustomerSheet: View {
        let customer: Customer
        @ObservedObject var viewModel: MechanicViewModel
        @Binding var selectedTab: Int
        @Environment(\.dismiss) private var dismiss
        @State private var customerName = ""
        @State private var city = ""
        @State private var kilometers = ""
        @State private var drivingTime = ""
        @State private var showingSuccessAlert = false
        @State private var showingValidationAlert = false
        @State private var validationErrors: [String] = []
        @State private var animateForm = false
        @State private var drivingTimePicker = Calendar.current.date(from: DateComponents(hour: 1, minute: 11)) ?? Date()
        @AppStorage("useTimePicker") private var useTimePicker = false
        @FocusState private var focusedField: Field?
        
        var body: some View {
            Form {
                Section("Informace o zákazníkovi") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Jméno zákazníka", text: $customerName)
                            .focused($focusedField, equals: .customerName)
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateForm)
                        
                        Text("Město")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Město", text: $city)
                            .focused($focusedField, equals: .city)
                            .opacity(animateForm ? 1.0 : 0.0)
                            .offset(y: animateForm ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateForm)
                        
                        Text("Město")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Jízda") {
                    HStack {
                        Text("Kilometry")
                        Spacer()
                        TextField("0", text: $kilometers)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .kilometers)
                        Text("Km")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateForm)
                    
                    HStack {
                        Text("Čas jízdy")
                        Spacer()
                        
                        if useTimePicker {
                            HalfHourTimePicker(selection: $drivingTimePicker)
                                .onChange(of: drivingTimePicker) { _, newValue in
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.hour, .minute], from: newValue)
                                    let hours = Double(components.hour ?? 0)
                                    let minutes = Double(components.minute ?? 0)
                                    let decimalHours = hours + (minutes / 60.0)
                                    drivingTime = String(format: "%.1f", decimalHours)
                                }
                        } else {
                            TextField("0.0", text: $drivingTime)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .drivingTime)
                                .onChange(of: drivingTime) { _, newValue in
                                    if let decimalHours = newValue.toDouble() {
                                        let hours = Int(decimalHours)
                                        let minutes = Int((decimalHours - Double(hours)) * 60)
                                        let roundedMinute = minutes < 15 ? 0 : 30
                                        let calendar = Calendar.current
                                        var components = DateComponents()
                                        components.hour = hours
                                        components.minute = roundedMinute
                                        if let date = calendar.date(from: components) {
                                            drivingTimePicker = date
                                        }
                                    }
                                }
                        }
                        
                        Text("h")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(animateForm ? 1.0 : 0.0)
                    .offset(y: animateForm ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateForm)
                }
                
                Section {
                    Button(action: {
                        updateCustomer()
                    }) {
                        Text("Uložit změny")
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
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateForm)
                }
            }
            .onTapGesture {
                // Zavřít klávesnici při kliknutí mimo textové pole
                focusedField = nil
            }
            .navigationTitle("Upravit zákazníka")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Úspěch", isPresented: $showingSuccessAlert) {
                Button(action: {
                    dismiss()
                }) {
                    Text("OK")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } message: {
                Text("Město")
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
                // Naplnit formulář aktuálními hodnotami
                customerName = customer.name
                city = customer.city
                kilometers = String(format: "%.0f", customer.kilometers)
                drivingTime = String(format: "%.1f", customer.drivingTime)
                
                // Aktualizovat time picker hodnoty
                updateTimePickerValues()
                
                withAnimation(.easeOut(duration: 0.8)) {
                    animateForm = true
                }
            }
        }
        
        private func updateTimePickerValues() {
            // Převést desetinné hodiny na čas pro time picker
            if let decimalHours = drivingTime.toDouble() {
                let hours = Int(decimalHours)
                let minutes = Int((decimalHours - Double(hours)) * 60)
                let calendar = Calendar.current
                var components = DateComponents()
                components.hour = hours
                components.minute = minutes
                if let date = calendar.date(from: components) {
                    drivingTimePicker = date
                }
            }
        }
        
        private func updateCustomer() {
            // Zavřít klávesnici
            focusedField = nil
            
            validationErrors = []
            
            // Validation
            if customerName.isEmpty {
                validationErrors.append("Vyplňte jméno zákazníka")
            }
            
            if city.isEmpty {
                validationErrors.append("Vyplňte město")
            }
            
            if kilometers.isEmpty {
                validationErrors.append("Vyplňte počet kilometrů")
            }
            
            if drivingTime.isEmpty {
                validationErrors.append("Vyplňte čas jízdy")
            }
            
            if let km = kilometers.toDouble(), km <= 0 {
                validationErrors.append("Počet kilometrů musí být větší než 0")
            }
            
            if let time = drivingTime.toDouble(), time <= 0 {
                validationErrors.append("Čas jízdy musí být větší než 0")
            }
            
            if !validationErrors.isEmpty {
                showingValidationAlert = true
                return
            }
            
            // Update customer
            var updatedCustomer = customer
            updatedCustomer.name = customerName
            updatedCustomer.city = city
            updatedCustomer.kilometers = kilometers.toDouble() ?? 0
            updatedCustomer.drivingTime = drivingTime.toDouble() ?? 0
            
            viewModel.updateCustomer(updatedCustomer)
            showingSuccessAlert = true
        }
    }
}
