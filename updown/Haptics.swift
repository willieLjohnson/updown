//
//  Haptics.swift
//  updown
//
//  Created by Willie Liwa Johnson on 4/3/22.
//

import Foundation
import SpriteKit


enum HapticStrength {
    case selection
    case light
    case medium
    case heavy
    case error
    case success
    case warning
}

extension GameScene {
    func vibrate(_ strength: HapticStrength = .selection) {
        switch strength {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        default:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}
