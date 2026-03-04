import Foundation

enum Badge: String, CaseIterable, Codable {
    // Kindergarten
    case k_level5, k_level10, k_level15, k_level20, k_grad
    // Grade 1
    case g1_level5, g1_level10, g1_level15, g1_level20, g1_grad
    // Grade 2
    case g2_level5, g2_level10, g2_level15, g2_level20, g2_grad
    // Grade 3
    case g3_level5, g3_level10, g3_level15, g3_level20, g3_grad
    // Grade 4
    case g4_level5, g4_level10, g4_level15, g4_level20, g4_grad
    // Grade 5
    case g5_level5, g5_level10, g5_level15, g5_level20, g5_grad
    // Grade 6
    case g6_level5, g6_level10, g6_level15, g6_level20, g6_grad
    // Grade 7
    case g7_level5, g7_level10, g7_level15, g7_level20, g7_grad
    // Special
    case rainbowScholar
    case speedDemon
    case onFire
    case sharpshooter
    case perfectionist
    case nightOwl
    case earlyBird
    case comebackKid
    case weekWarrior

    var emoji: String {
        switch self {
        case .k_level5: return "\u{1F423}"
        case .k_level10: return "\u{1F425}"
        case .k_level15: return "\u{1F424}"
        case .k_level20: return "\u{1F414}"
        case .k_grad: return "\u{1F393}"
        case .g1_level5: return "\u{1F331}"
        case .g1_level10: return "\u{1F33F}"
        case .g1_level15: return "\u{1F333}"
        case .g1_level20: return "\u{1F332}"
        case .g1_grad: return "\u{1F393}"
        case .g2_level5: return "\u{2B50}"
        case .g2_level10: return "\u{1F31F}"
        case .g2_level15: return "\u{1F4AB}"
        case .g2_level20: return "\u{2728}"
        case .g2_grad: return "\u{1F393}"
        case .g3_level5: return "\u{1F680}"
        case .g3_level10: return "\u{1F6F8}"
        case .g3_level15: return "\u{1F319}"
        case .g3_level20: return "\u{1FA90}"
        case .g3_grad: return "\u{1F393}"
        case .g4_level5: return "\u{1F52D}"
        case .g4_level10: return "\u{1F30C}"
        case .g4_level15: return "\u{2604}\u{FE0F}"
        case .g4_level20: return "\u{1F320}"
        case .g4_grad: return "\u{1F393}"
        case .g5_level5: return "\u{1F9EA}"
        case .g5_level10: return "\u{2697}\u{FE0F}"
        case .g5_level15: return "\u{1F52C}"
        case .g5_level20: return "\u{1F9EC}"
        case .g5_grad: return "\u{1F393}"
        case .g6_level5: return "\u{26A1}"
        case .g6_level10: return "\u{1F50B}"
        case .g6_level15: return "\u{1F4A1}"
        case .g6_level20: return "\u{1F310}"
        case .g6_grad: return "\u{1F393}"
        case .g7_level5: return "\u{1F3C5}"
        case .g7_level10: return "\u{1F949}"
        case .g7_level15: return "\u{1F947}"
        case .g7_level20: return "\u{1F451}"
        case .g7_grad: return "\u{1F393}"
        case .rainbowScholar: return "\u{1F308}"
        case .speedDemon: return "\u{26A1}"
        case .onFire: return "\u{1F525}"
        case .sharpshooter: return "\u{1F3AF}"
        case .perfectionist: return "\u{1F4AF}"
        case .nightOwl: return "\u{1F319}"
        case .earlyBird: return "\u{1F305}"
        case .comebackKid: return "\u{1F4AA}"
        case .weekWarrior: return "\u{1F5D3}\u{FE0F}"
        }
    }

    var name: String {
        switch self {
        case .k_level5: return "Hatchling"
        case .k_level10: return "Chick"
        case .k_level15: return "Fledgling"
        case .k_level20: return "Flyer"
        case .k_grad: return "Kindergarten Graduate"
        case .g1_level5: return "Sprout"
        case .g1_level10: return "Sapling"
        case .g1_level15: return "Tree"
        case .g1_level20: return "Forest"
        case .g1_grad: return "Grade 1 Graduate"
        case .g2_level5: return "Starling"
        case .g2_level10: return "Shiner"
        case .g2_level15: return "Blazer"
        case .g2_level20: return "Sparkler"
        case .g2_grad: return "Grade 2 Graduate"
        case .g3_level5: return "Cadet"
        case .g3_level10: return "Pilot"
        case .g3_level15: return "Navigator"
        case .g3_level20: return "Explorer"
        case .g3_grad: return "Grade 3 Graduate"
        case .g4_level5: return "Watcher"
        case .g4_level10: return "Voyager"
        case .g4_level15: return "Comet"
        case .g4_level20: return "Stargazer"
        case .g4_grad: return "Grade 4 Graduate"
        case .g5_level5: return "Tinkerer"
        case .g5_level10: return "Mixer"
        case .g5_level15: return "Analyst"
        case .g5_level20: return "Scientist"
        case .g5_grad: return "Grade 5 Graduate"
        case .g6_level5: return "Spark"
        case .g6_level10: return "Charged"
        case .g6_level15: return "Bright"
        case .g6_level20: return "Connected"
        case .g6_grad: return "Grade 6 Graduate"
        case .g7_level5: return "Contender"
        case .g7_level10: return "Bronze"
        case .g7_level15: return "Champion"
        case .g7_level20: return "Legend"
        case .g7_grad: return "Grade 7 Graduate"
        case .rainbowScholar: return "Rainbow Scholar"
        case .speedDemon: return "Speed Demon"
        case .onFire: return "On Fire"
        case .sharpshooter: return "Sharpshooter"
        case .perfectionist: return "Perfectionist"
        case .nightOwl: return "Night Owl"
        case .earlyBird: return "Early Bird"
        case .comebackKid: return "Comeback Kid"
        case .weekWarrior: return "Week Warrior"
        }
    }

    var badgeDescription: String {
        switch self {
        case .rainbowScholar: return "Graduate all 8 grades!"
        case .speedDemon:     return "10 INCREDIBLE shots in one session"
        case .onFire:         return "20 correct answers in a row"
        case .sharpshooter:   return "5 INCREDIBLE shots in a row"
        case .perfectionist:  return "Complete a grade with 100% accuracy"
        case .nightOwl:       return "Play between 9pm and midnight"
        case .earlyBird:      return "Play before 7am"
        case .comebackKid:    return "Answer correctly after 3 wrong in a row"
        case .weekWarrior:    return "Play 7 days in a row"
        default:              return "Keep playing to unlock!"
        }
    }

    var isSpecial: Bool {
        switch self {
        case .rainbowScholar, .speedDemon, .onFire, .sharpshooter,
             .perfectionist, .nightOwl, .earlyBird, .comebackKid, .weekWarrior:
            return true
        default:
            return false
        }
    }

    static func milestoneBadge(grade: Grade, level: Int) -> Badge? {
        switch (grade, level) {
        case (.kindergarten, 5): return .k_level5
        case (.kindergarten, 10): return .k_level10
        case (.kindergarten, 15): return .k_level15
        case (.kindergarten, 20): return .k_level20
        case (.grade1, 5): return .g1_level5
        case (.grade1, 10): return .g1_level10
        case (.grade1, 15): return .g1_level15
        case (.grade1, 20): return .g1_level20
        case (.grade2, 5): return .g2_level5
        case (.grade2, 10): return .g2_level10
        case (.grade2, 15): return .g2_level15
        case (.grade2, 20): return .g2_level20
        case (.grade3, 5): return .g3_level5
        case (.grade3, 10): return .g3_level10
        case (.grade3, 15): return .g3_level15
        case (.grade3, 20): return .g3_level20
        case (.grade4, 5): return .g4_level5
        case (.grade4, 10): return .g4_level10
        case (.grade4, 15): return .g4_level15
        case (.grade4, 20): return .g4_level20
        case (.grade5, 5): return .g5_level5
        case (.grade5, 10): return .g5_level10
        case (.grade5, 15): return .g5_level15
        case (.grade5, 20): return .g5_level20
        case (.grade6, 5): return .g6_level5
        case (.grade6, 10): return .g6_level10
        case (.grade6, 15): return .g6_level15
        case (.grade6, 20): return .g6_level20
        case (.grade7, 5): return .g7_level5
        case (.grade7, 10): return .g7_level10
        case (.grade7, 15): return .g7_level15
        case (.grade7, 20): return .g7_level20
        default: return nil
        }
    }

    static func graduationBadge(for grade: Grade) -> Badge {
        switch grade {
        case .kindergarten: return .k_grad
        case .grade1: return .g1_grad
        case .grade2: return .g2_grad
        case .grade3: return .g3_grad
        case .grade4: return .g4_grad
        case .grade5: return .g5_grad
        case .grade6: return .g6_grad
        case .grade7: return .g7_grad
        }
    }

    static func badgesForGrade(_ grade: Grade) -> [Badge] {
        switch grade {
        case .kindergarten: return [.k_level5, .k_level10, .k_level15, .k_level20, .k_grad]
        case .grade1: return [.g1_level5, .g1_level10, .g1_level15, .g1_level20, .g1_grad]
        case .grade2: return [.g2_level5, .g2_level10, .g2_level15, .g2_level20, .g2_grad]
        case .grade3: return [.g3_level5, .g3_level10, .g3_level15, .g3_level20, .g3_grad]
        case .grade4: return [.g4_level5, .g4_level10, .g4_level15, .g4_level20, .g4_grad]
        case .grade5: return [.g5_level5, .g5_level10, .g5_level15, .g5_level20, .g5_grad]
        case .grade6: return [.g6_level5, .g6_level10, .g6_level15, .g6_level20, .g6_grad]
        case .grade7: return [.g7_level5, .g7_level10, .g7_level15, .g7_level20, .g7_grad]
        }
    }

    static var specialBadges: [Badge] {
        return [.rainbowScholar, .speedDemon, .onFire, .sharpshooter,
                .perfectionist, .nightOwl, .earlyBird, .comebackKid, .weekWarrior]
    }
}

enum GameEvent {
    case incredibleShot
    case correctStreak(Int)
    case comebackAnswer
}
