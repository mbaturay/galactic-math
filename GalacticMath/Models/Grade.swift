import SpriteKit

enum Grade: Int, CaseIterable, Codable {
    case kindergarten = 0
    case grade1 = 1
    case grade2 = 2
    case grade3 = 3
    case grade4 = 4
    case grade5 = 5
    case grade6 = 6
    case grade7 = 7

    var displayName: String {
        switch self {
        case .kindergarten: return "Kindergarten"
        default: return "Grade \(self.rawValue)"
        }
    }

    var shortName: String {
        switch self {
        case .kindergarten: return "K"
        default: return "\(self.rawValue)"
        }
    }

    var emoji: String {
        switch self {
        case .kindergarten: return "\u{1F31F}"
        case .grade1:       return "\u{1F680}"
        case .grade2:       return "\u{2B50}"
        case .grade3:       return "\u{1FA90}"
        case .grade4:       return "\u{2604}\u{FE0F}"
        case .grade5:       return "\u{1F52C}"
        case .grade6:       return "\u{26A1}"
        case .grade7:       return "\u{1F451}"
        }
    }

    var primaryColor: SKColor {
        switch self {
        case .kindergarten: return SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        case .grade1:       return SKColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        case .grade2:       return SKColor(red: 1.0, green: 0.62, blue: 0.26, alpha: 1.0)
        case .grade3:       return SKColor(red: 0.28, green: 0.86, blue: 0.98, alpha: 1.0)
        case .grade4:       return SKColor(red: 0.11, green: 0.82, blue: 0.63, alpha: 1.0)
        case .grade5:       return SKColor(red: 0.64, green: 0.61, blue: 1.0, alpha: 1.0)
        case .grade6:       return SKColor(red: 0.99, green: 0.47, blue: 0.66, alpha: 1.0)
        case .grade7:       return SKColor(red: 0.42, green: 0.36, blue: 0.90, alpha: 1.0)
        }
    }

    var secondaryColor: SKColor {
        return primaryColor.withAlphaComponent(0.6)
    }

    var backgroundColor: SKColor {
        switch self {
        case .kindergarten: return SKColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0)
        case .grade1:       return SKColor(red: 0.06, green: 0.02, blue: 0.12, alpha: 1.0)
        case .grade2:       return SKColor(red: 0.05, green: 0.03, blue: 0.12, alpha: 1.0)
        case .grade3:       return SKColor(red: 0.02, green: 0.05, blue: 0.15, alpha: 1.0)
        case .grade4:       return SKColor(red: 0.02, green: 0.06, blue: 0.12, alpha: 1.0)
        case .grade5:       return SKColor(red: 0.04, green: 0.02, blue: 0.14, alpha: 1.0)
        case .grade6:       return SKColor(red: 0.06, green: 0.02, blue: 0.10, alpha: 1.0)
        case .grade7:       return SKColor(red: 0.03, green: 0.02, blue: 0.12, alpha: 1.0)
        }
    }

    var beamCount: Int {
        return self.rawValue < 2 ? 3 : 5
    }

    var lives: Int {
        return self.rawValue < 2 ? 5 : 3
    }

    var enemySpeed: CGFloat {
        let speeds: [CGFloat] = [55, 65, 75, 90, 105, 120, 135, 150]
        return speeds[self.rawValue]
    }

    var minEnemySpeed: CGFloat {
        return enemySpeed * 0.6
    }

    var maxEnemySpeed: CGFloat {
        return enemySpeed * 1.8
    }

    var maxLevel: Int {
        return 20
    }

    var beamColors: [SKColor] {
        if self.rawValue < 2 {
            return [
                SKColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0),
                SKColor(red: 0.27, green: 1.0, blue: 0.27, alpha: 1.0),
                SKColor(red: 0.27, green: 0.27, blue: 1.0, alpha: 1.0)
            ]
        } else {
            return [
                SKColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0),
                SKColor(red: 1.0, green: 0.53, blue: 0.27, alpha: 1.0),
                SKColor(red: 0.27, green: 1.0, blue: 0.27, alpha: 1.0),
                SKColor(red: 0.27, green: 1.0, blue: 1.0, alpha: 1.0),
                SKColor(red: 0.27, green: 0.27, blue: 1.0, alpha: 1.0)
            ]
        }
    }

    var difficultyMultiplier: Double {
        let multipliers = [1.0, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]
        return multipliers[self.rawValue]
    }
}
