//
//  SettingsView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var viewModel: MechanicViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 20
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @AppStorage("useTimePicker") private var useTimePicker = false
    @State private var showingTimePicker = false
    @State private var showingTimePickerAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingGenerateDataAlert = false
    @State private var showingNotificationTimePicker = false
    
    private var notificationTime: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = notificationHour
        components.minute = notificationMinute
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Computed Properties
    private var notificationSection: some View {
        Section("Notifikace") {
            VStack(alignment: .leading, spacing: 12) {
                // Toggle pro zapnutí/vypnutí notifikací
                Button(action: {
                    notificationsEnabled.toggle()
                    if notificationsEnabled {
                        Task {
                            await notificationManager.requestPermission()
                            if notificationManager.isAuthorized {
                                notificationManager.scheduleDailyReminder(at: notificationHour, minute: notificationMinute)
                            }
                        }
                    } else {
                        notificationManager.cancelDailyReminder()
                    }
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Denní připomínka")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Připomene vám vyplnit výkaz")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                if !notificationManager.isAuthorized {
                    Button(action: {
                        Task {
                            await notificationManager.requestPermission()
                        }
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Povolit notifikace")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Klikněte pro povolení notifikací")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if notificationsEnabled {
                    Button(action: {
                        showingNotificationTimePicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Čas notifikace")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                
                                Text(String(format: "%02d:%02d", notificationHour, notificationMinute))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: showingNotificationTimePicker ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if showingNotificationTimePicker {
                        HalfHourTimePicker(selection: Binding(
                            get: {
                                let calendar = Calendar.current
                                let m = notificationMinute
                                let roundedMin = m < 15 ? 0 : 30
                                var comp = DateComponents()
                                comp.hour = notificationHour
                                comp.minute = roundedMin
                                return calendar.date(from: comp) ?? Date()
                            },
                            set: { newTime in
                                let calendar = Calendar.current
                                notificationHour = calendar.component(.hour, from: newTime)
                                notificationMinute = calendar.component(.minute, from: newTime)
                                notificationManager.scheduleDailyReminder(at: notificationHour, minute: notificationMinute)
                            }
                        ))
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var timeInputSection: some View {
        Section("Zadávání času") {
            // Kompaktní přepínání s tlačítky
            HStack(spacing: 8) {
                Button(action: {
                    if useTimePicker {
                        showingTimePickerAlert = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "textformat.123")
                            .font(.caption)
                        Text("OK")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(useTimePicker ? Color.clear : Color.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(useTimePicker ? Color.gray.opacity(0.3) : Color.blue, lineWidth: 1)
                            )
                    )
                    .foregroundStyle(useTimePicker ? .secondary : Color.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    if !useTimePicker {
                        showingTimePickerAlert = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("Čas")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(useTimePicker ? Color.blue : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(useTimePicker ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(useTimePicker ? Color.white : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // Aktuální popis režimu
            HStack(spacing: 8) {
                Image(systemName: useTimePicker ? "clock" : "textformat.123")
                    .foregroundStyle(useTimePicker ? .green : .blue)
                    .font(.caption)
                Text(useTimePicker ? "Přesné nastavení hodin a minut" : "6,5 = 6 hodin 30 minut")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                notificationSection
                timeInputSection
                
#if DEBUG && targetEnvironment(simulator)
                Section("Debug (pouze pro vývoj)") {
                    Button(action: {
                        showingGenerateDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vygenerovat testovací data")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Vytvoří 3 měsíce testovacích dat")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.generateCurrentMonthData()
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Přidat aktuální měsíc")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Vytvoří testovací data pro tento měsíc")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Smazat všechna data")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Odstraní všechny záznamy a nastavení")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
#endif
                
                Section("O aplikaci") {
                    // Vývojář
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vývojář")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Jakub Sedláček")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    
                    // Verze aplikace
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Verze aplikace")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Neznámá")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Nastavení")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Vygenerovat testovací data", isPresented: $showingGenerateDataAlert) {
                Button("Zrušit", role: .cancel) { }
                Button("Vygenerovat") {
                    viewModel.generateTestData()
                }
            } message: {
                Text("Tato akce vytvoří 3 měsíce testovacích data s 180-220 hodinami práce, 80% práce a 20% jízdy, průměrná rychlost 70km/h. Každý měsíc bude mít 1 den dovolené a 1 den lékaře.")
            }
            .alert("Smazat všechna data", isPresented: $showingClearDataAlert) {
                Button("Zrušit", role: .cancel) { }
                Button("Smazat", role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text("Tato akce odstraní všechny záznamy o práci, palivu a zákaznících. Tuto akci nelze vrátit zpět.")
            }
            
            // Alert pro změnu time picker nastavení
            .alert("Změna způsobu zadávání času", isPresented: $showingTimePickerAlert) {
                Button("Zrušit", role: .cancel) { }
                Button(useTimePicker ? "Přejít na textový režim" : "Přejít na časový výběr", role: .destructive) {
                    useTimePicker.toggle()
                }
            } message: {
                Text(useTimePicker ? 
                     "Opravdu chcete přejít na zadávání času jako desetinné číslo (např. 6,5)?\n\nVšechny existující časy se zobrazí v novém formátu." :
                     "Opravdu chcete přejít na časový výběr s hodinami a minutami?\n\nVšechny existující časy se zobrazí v novém formátu.")
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: MechanicViewModel())
}