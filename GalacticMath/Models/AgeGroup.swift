import SpriteKit

enum AgeGroup: String, CaseIterable, Codable {
    case cadet
    case pilot
    case ace

    var beamCount: Int {
        switch self {
        case .cadet: return 3
        case .pilot: return 5
        case .ace:   return 5
        }
    }

    var lives: Int {
        switch self {
        case .cadet: return 5
        case .pilot: return 3
        case .ace:   return 3
        }
    }

    var baseEnemySpeed: CGFloat {
        switch self {
        case .cadet: return 42.0
        case .pilot: return 70.0
        case .ace:   return 98.0
        }
    }

    var minEnemySpeed: CGFloat {
        switch self {
        case .cadet: return 28.0
        case .pilot: return 49.0
        case .ace:   return 70.0
        }
    }

    var maxEnemySpeed: CGFloat {
        switch self {
        case .cadet: return 70.0
        case .pilot: return 126.0
        case .ace:   return 175.0
        }
    }

    var displayName: String {
        switch self {
        case .cadet: return "Space Cadet (4-7)"
        case .pilot: return "Star Pilot (7-10)"
        case .ace:   return "Ace Commander (10-13)"
        }
    }

    var shortName: String {
        switch self {
        case .cadet: return "Space Cadet"
        case .pilot: return "Star Pilot"
        case .ace:   return "Ace Commander"
        }
    }

    var maxLevel: Int {
        switch self {
        case .cadet: return 6
        case .pilot: return 8
        case .ace:   return 8
        }
    }

    var primaryColor: SKColor {
        switch self {
        case .cadet: return SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        case .pilot: return SKColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
        case .ace:   return SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        }
    }

    var secondaryColor: SKColor {
        switch self {
        case .cadet: return SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        case .pilot: return SKColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        case .ace:   return SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        }
    }

    var backgroundColor: SKColor {
        switch self {
        case .cadet: return SKColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0)
        case .pilot: return SKColor(red: 0.02, green: 0.05, blue: 0.15, alpha: 1.0)
        case .ace:   return SKColor(red: 0.08, green: 0.02, blue: 0.12, alpha: 1.0)
        }
    }

    var beamColors: [SKColor] {
        switch self {
        case .cadet:
            return [
                SKColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0),   // Red
                SKColor(red: 0.27, green: 1.0, blue: 0.27, alpha: 1.0),   // Green
                SKColor(red: 0.27, green: 0.27, blue: 1.0, alpha: 1.0)    // Blue
            ]
        case .pilot, .ace:
            return [
                SKColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0),   // Red
                SKColor(red: 1.0, green: 0.53, blue: 0.27, alpha: 1.0),   // Orange
                SKColor(red: 0.27, green: 1.0, blue: 0.27, alpha: 1.0),   // Green
                SKColor(red: 0.27, green: 1.0, blue: 1.0, alpha: 1.0),    // Cyan
                SKColor(red: 0.27, green: 0.27, blue: 1.0, alpha: 1.0)    // Blue
            ]
        }
    }
}
