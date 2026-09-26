//
//  CardSurface.swift
//  TVHomeRun
//
//  The one card background used across the app
//

import SwiftUI

extension View {
    /// Standard card fill. Focus lift, shadow and parallax come from
    /// `.buttonStyle(.card)`, so this deliberately adds no shadow of its own.
    func cardSurface(cornerRadius: CGFloat = 16) -> some View {
        background(.fill.tertiary, in: .rect(cornerRadius: cornerRadius, style: .continuous))
    }
}
