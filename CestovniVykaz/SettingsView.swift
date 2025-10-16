//
//  SettingsView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 20
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @State private var showingTimePicker = false
    
    private var notificationTime: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = notificationHour
        components.minute = notificationMinute
        return calendar.date(from: components) ?? Date()
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                                    if notificationManager.isAuthorized {
                                        notificationManager.scheduleDailyReminder(at: notificationHour, minute: notificationMinute)
                                    }
                                }
                            }) {
                                Text("Povolit notifikace")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else if notificationsEnabled {
                            VStack(spacing: 8) {
                                Text("Notifikace povoleny")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    // Časový picker - skrytý/skrytý
                    if showingTimePicker {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Čas notifikace")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            
                            DatePicker("", selection: Binding(
                                get: { notificationTime },
                                set: { newTime in
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.hour, .minute], from: newTime)
                                    notificationHour = components.hour ?? 20
                                    notificationMinute = components.minute ?? 0
                                    
                                    // Aktualizovat notifikaci pokud je zapnutá
                                    if notificationsEnabled && notificationManager.isAuthorized {
                                        notificationManager.scheduleDailyReminder(at: notificationHour, minute: notificationMinute)
                                    }
                                }
                            ), displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Tlačítko pro otevření/zavření časového pickeru
                    Button(action: {
                        showingTimePicker.toggle()
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            
                            Text("Nastavit čas")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: showingTimePicker ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section("O aplikaci") {
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
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Nastavení")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
