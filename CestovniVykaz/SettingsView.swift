//
//  SettingsView.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(localizationManager.localizedString("notifications")) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Toggle pro zapnutí/vypnutí notifikací
                        Button(action: {
                            notificationsEnabled.toggle()
                            if notificationsEnabled {
                                Task {
                                    await notificationManager.requestPermission()
                                    if notificationManager.isAuthorized {
                                        notificationManager.scheduleDailyReminder()
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
                                    Text(localizationManager.localizedString("dailyReminder"))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(localizationManager.localizedString("notificationDescription"))
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
                                        notificationManager.scheduleDailyReminder()
                                    }
                                }
                            }) {
                                Text(localizationManager.localizedString("enableNotifications"))
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
                                Text(localizationManager.localizedString("notificationsEnabled"))
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                
                                Button(action: {
                                    notificationManager.scheduleTestNotification()
                                }) {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                            .foregroundStyle(.white)
                                        Text(localizationManager.localizedString("testNotification"))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                Section(localizationManager.localizedString("language")) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Button(action: {
                            localizationManager.setLanguage(language)
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                    .frame(width: 30)
                                
                                Text(language.displayName)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if localizationManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section(localizationManager.localizedString("appInfo")) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizationManager.localizedString("version"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text(localizationManager.localizedString("version"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString("settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
