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
    @State private var animateContent = false
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
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                
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
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                
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
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
            }
            .navigationTitle(localizationManager.localizedString("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
