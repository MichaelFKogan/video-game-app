//
//  Extensions.swift
//  Video Game App
//
//  Created by Mike K on 8/15/25.
//

import SwiftUI

// Other existing extensions...

// MARK: - String to Color Helper
extension String {
    func toColor() -> Color {
        switch self {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "pink": return .pink
        case "purple": return .purple
        case "yellow": return .yellow
        case "orange": return .orange
            
        case "cyan": return .cyan
        case "mint": return .mint
        case "indigo": return .indigo
        case "teal": return .teal
        case "gray": return .gray
            
        default: return .blue
        }
    }
}
