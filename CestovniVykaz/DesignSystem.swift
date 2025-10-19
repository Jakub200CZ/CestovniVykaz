//
//  DesignSystem.swift
//  CestovniVykaz
//
//  Created by Jakub Sedláček on 27.07.2025.
//

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let primary = Color.blue
        static let primaryLight = Color.blue.opacity(0.1)
        static let primaryMedium = Color.blue.opacity(0.2)
        static let primaryDark = Color.blue.opacity(0.8)
        
        // Secondary colors
        static let secondary = Color.green
        static let secondaryLight = Color.green.opacity(0.1)
        static let secondaryMedium = Color.green.opacity(0.2)
        
        // Accent colors
        static let accent = Color.orange
        static let accentLight = Color.orange.opacity(0.1)
        static let accentMedium = Color.orange.opacity(0.2)
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        static let purple = Color.purple
        
        // Neutral colors
        static let background = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let surface = Color(.tertiarySystemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)
        
        // Card colors
        static let cardBackground = Color(.systemBackground)
        static let cardBorder = Color(.separator)
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        
        // Body text
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body.weight(.regular)
        static let bodyMedium = Font.body.weight(.medium)
        static let callout = Font.callout.weight(.regular)
        static let subheadline = Font.subheadline.weight(.medium)
        static let footnote = Font.footnote.weight(.regular)
        static let caption = Font.caption.weight(.regular)
        static let caption2 = Font.caption2.weight(.regular)
        
        // Special
        static let statValue = Font.system(size: 18, weight: .bold, design: .rounded)
        static let statLabel = Font.system(size: 11, weight: .medium)
        static let button = Font.subheadline.weight(.semibold)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // Component specific
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let itemSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 12
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        
        // Component specific
        static let card: CGFloat = 12
        static let button: CGFloat = 8
        static let input: CGFloat = 8
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.05)
        static let button = Color.black.opacity(0.1)
        static let modal = Color.black.opacity(0.2)
        
        static let cardRadius: CGFloat = 8
        static let cardOffset = CGSize(width: 0, height: 4)
        static let buttonRadius: CGFloat = 4
        static let buttonOffset = CGSize(width: 0, height: 2)
    }
    
    // MARK: - Animation (Optimized for performance)
    struct Animation {
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeOut(duration: 0.4)
        
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }
}

// MARK: - Design System Extensions
extension View {
    
    // MARK: - Card Styles
    func cardStyle() -> some View {
        self
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
    
    func cardStyleSecondary() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
            .shadow(
                color: DesignSystem.Shadows.card,
                radius: DesignSystem.Shadows.cardRadius,
                x: DesignSystem.Shadows.cardOffset.width,
                y: DesignSystem.Shadows.cardOffset.height
            )
    }
    
    // MARK: - Button Styles
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.button)
            .foregroundStyle(.white)
            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
            .shadow(
                color: DesignSystem.Shadows.button,
                radius: DesignSystem.Shadows.buttonRadius,
                x: DesignSystem.Shadows.buttonOffset.width,
                y: DesignSystem.Shadows.buttonOffset.height
            )
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.button)
            .foregroundStyle(DesignSystem.Colors.primary)
            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.primaryLight)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
    }
    
    func ghostButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.button)
            .foregroundStyle(DesignSystem.Colors.primary)
            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
            )
    }
    
    // MARK: - Input Styles
    func inputStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .stroke(DesignSystem.Colors.cardBorder, lineWidth: 1)
            )
    }
    
    // MARK: - Animation Helpers (Simplified for performance)
    func fadeInAnimation(delay: Double = 0) -> some View {
        self.opacity(0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                    // Animation handled by opacity modifier
                }
            }
    }
}

// MARK: - Reusable Components
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(DesignSystem.Typography.statValue)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(DesignSystem.Typography.statLabel)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ActionButtonContent: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
}

