import Foundation

enum MathTopic: String, CaseIterable, Codable {
    // Cadet (4-7)
    case counting
    case additionBasic
    case subtractionBasic

    // Pilot (7-10)
    case additionAdvanced
    case subtractionAdvanced
    case multiplicationBasic
    case divisionBasic
    case missingNumber

    // Ace (10-13)
    case multiplicationAdvanced
    case divisionAdvanced
    case fractions
    case decimals
    case percentages
    case patterns
    case algebraBasic

    var displayName: String {
        switch self {
        case .counting: return "Counting"
        case .additionBasic: return "Addition"
        case .subtractionBasic: return "Subtraction"
        case .additionAdvanced: return "Addition"
        case .subtractionAdvanced: return "Subtraction"
        case .multiplicationBasic: return "Multiplication"
        case .divisionBasic: return "Division"
        case .missingNumber: return "Missing Number"
        case .multiplicationAdvanced: return "Multiplication"
        case .divisionAdvanced: return "Division"
        case .fractions: return "Fractions"
        case .decimals: return "Decimals"
        case .percentages: return "Percentages"
        case .patterns: return "Patterns"
        case .algebraBasic: return "Algebra"
        }
    }

    static func topics(for ageGroup: AgeGroup, level: Int) -> [MathTopic] {
        switch ageGroup {
        case .cadet:
            switch level {
            case 1, 2: return [.counting]
            case 3, 4: return [.additionBasic]
            case 5, 6: return [.subtractionBasic]
            default: return [.additionBasic, .subtractionBasic]
            }
        case .pilot:
            switch level {
            case 1: return [.additionAdvanced, .subtractionAdvanced]
            case 2: return [.additionAdvanced, .subtractionAdvanced]
            case 3, 4, 5, 6: return [.multiplicationBasic]
            case 7: return [.divisionBasic]
            case 8: return [.missingNumber]
            default: return [.multiplicationBasic, .divisionBasic]
            }
        case .ace:
            switch level {
            case 1: return [.multiplicationAdvanced]
            case 2: return [.divisionAdvanced]
            case 3, 4: return [.fractions]
            case 5: return [.decimals]
            case 6: return [.percentages]
            case 7: return [.patterns]
            case 8: return [.algebraBasic]
            default: return [.multiplicationAdvanced, .divisionAdvanced]
            }
        }
    }
}
