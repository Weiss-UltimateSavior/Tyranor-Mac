import AppKit
import SwiftUI

private func adaptive(dark: NSColor, light: NSColor) -> Color {
    Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
    })
}

enum Theme {
    static let background = adaptive(
        dark: NSColor(red: 0.055, green: 0.055, blue: 0.067, alpha: 1),
        light: NSColor(red: 0.945, green: 0.949, blue: 0.961, alpha: 1)
    )
    static let sidebar = adaptive(
        dark: NSColor(red: 0.078, green: 0.078, blue: 0.094, alpha: 1),
        light: NSColor(red: 0.914, green: 0.918, blue: 0.933, alpha: 1)
    )
    static let panel = adaptive(
        dark: NSColor(red: 0.086, green: 0.086, blue: 0.102, alpha: 1),
        light: NSColor(red: 0.973, green: 0.976, blue: 0.984, alpha: 1)
    )
    static let card = adaptive(
        dark: NSColor(red: 0.125, green: 0.125, blue: 0.145, alpha: 1),
        light: NSColor(red: 0.878, green: 0.882, blue: 0.898, alpha: 1)
    )
    static let hover = adaptive(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(white: 0, alpha: 0.05)
    )
    static let separator = adaptive(
        dark: NSColor(white: 1, alpha: 0.07),
        light: NSColor(white: 0, alpha: 0.08)
    )
    static let buttonFill = adaptive(
        dark: NSColor(white: 1, alpha: 0.05),
        light: NSColor(white: 0, alpha: 0.04)
    )
    static let buttonFillHover = adaptive(
        dark: NSColor(white: 1, alpha: 0.10),
        light: NSColor(white: 0, alpha: 0.07)
    )
    static let accent = Color(red: 0.294, green: 0.463, blue: 0.949)
    static let favorite = Color(red: 0.937, green: 0.357, blue: 0.557)
    static let textPrimary = adaptive(
        dark: .white,
        light: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
    )
    static let textSecondary = adaptive(
        dark: NSColor(white: 1, alpha: 0.6),
        light: NSColor(white: 0.15, alpha: 0.65)
    )
    static let textTertiary = adaptive(
        dark: NSColor(white: 1, alpha: 0.35),
        light: NSColor(white: 0.15, alpha: 0.45)
    )
}

struct PrimaryActionButtonStyle: ButtonStyle {
    var color: Color = Theme.accent

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        PrimaryButton(configuration: configuration, color: color)
    }

    private struct PrimaryButton: View {
        let configuration: ButtonStyleConfiguration
        let color: Color
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    color.opacity(configuration.isPressed ? 0.72 : 1),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .shadow(color: color.opacity(isEnabled ? 0.35 : 0), radius: 8, y: 2)
                .opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1) : 0.45)
        }
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    var tint: Color? = nil

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        SecondaryButton(configuration: configuration, tint: tint)
    }

    private struct SecondaryButton: View {
        let configuration: ButtonStyleConfiguration
        let tint: Color?
        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(tint ?? Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    isHovering ? Theme.buttonFillHover : Theme.buttonFill,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Theme.separator, lineWidth: 1)
                )
                .onHover { isHovering = $0 }
                .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
        }
    }
}
