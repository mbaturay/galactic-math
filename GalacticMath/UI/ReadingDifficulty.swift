import SpriteKit

enum ReadingDifficulty: Int, CaseIterable {
    case easy = 0
    case normal = 1
    case hard = 2

    var readTime: TimeInterval {
        switch self {
        case .easy:   return 8.0
        case .normal: return 5.0
        case .hard:   return 3.0
        }
    }

    var label: String {
        switch self {
        case .easy:   return "EASY"
        case .normal: return "NORMAL"
        case .hard:   return "HARD"
        }
    }

    var color: SKColor {
        switch self {
        case .easy:   return SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        case .normal: return SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        case .hard:   return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }

    static var current: ReadingDifficulty = .normal
}
