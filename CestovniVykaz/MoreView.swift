//
//  MoreView.swift
//  CestovniVykaz
//
//  Záložka „Více“ – seznam Palivo, Zákazníci s navigací.
//

import SwiftUI

// MARK: - Položka menu More
struct MoreMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct MoreView: View {
    @ObservedObject var viewModel: MechanicViewModel
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var appeared = false

    private let menuItems: [MoreMenuItem] = [
        MoreMenuItem(
            title: "Palivo",
            subtitle: "Sledování tankování a spotřeby",
            icon: "fuelpump.fill",
            color: DesignSystem.Colors.accent
        ),
        MoreMenuItem(
            title: "Zákazníci",
            subtitle: "Správa zákazníků a adres",
            icon: "person.2.fill",
            color: DesignSystem.Colors.secondary
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        ForEach(Array(menuItems.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(destination: destinationView(for: item)) {
                                MoreRowView(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(
                                DesignSystem.Animation.spring.delay(Double(index) * 0.08),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationTitle("Více")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .onAppear {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private func destinationView(for item: MoreMenuItem) -> some View {
        switch item.title {
        case "Palivo":
            FuelOverviewView(viewModel: viewModel, selectedTab: $selectedTab)
        case "Zákazníci":
            CustomerView(viewModel: viewModel, selectedTab: $selectedTab)
        default:
            EmptyView()
        }
    }
}

// MARK: - Řádek položky menu
struct MoreRowView: View {
    let item: MoreMenuItem

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(item.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: item.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(item.color)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(item.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(item.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
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

#Preview {
    MoreView(viewModel: MechanicViewModel(), selectedTab: .constant(4))
}
