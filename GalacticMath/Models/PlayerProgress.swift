import Foundation

struct PlayerProfile: Codable {
    let slotIndex: Int
    var name: String
    var avatar: String
    var currentGrade: Grade
    var currentLevelPerGrade: [Int: Int]
    var highScorePerGrade: [Int: Int]
    var accuracyPerTopic: [String: TopicStats]
    var badgesEarned: [String: Date]
    var totalPlayTime: TimeInterval
    var lastPlayedDate: Date
    var createdDate: Date
    var consecutiveDays: Int
    var lastPlayedDay: String
    var totalIncredibleShots: Int
    var sessionIncredibleShots: Int
    var currentStreak: Int
    var longestStreak: Int
    var bestZone: String
    var hasSeenProximityTip: Bool
    var selectedShipIndex: Int

    init(slotIndex: Int, name: String, avatar: String, grade: Grade) {
        self.slotIndex = slotIndex
        self.name = name
        self.avatar = avatar
        self.currentGrade = grade
        self.currentLevelPerGrade = [:]
        self.highScorePerGrade = [:]
        self.accuracyPerTopic = [:]
        self.badgesEarned = [:]
        self.totalPlayTime = 0
        self.lastPlayedDate = Date()
        self.createdDate = Date()
        self.consecutiveDays = 1
        self.lastPlayedDay = PlayerProfile.todayString()
        self.totalIncredibleShots = 0
        self.sessionIncredibleShots = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.bestZone = ""
        self.hasSeenProximityTip = false
        self.selectedShipIndex = 0
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slotIndex = try container.decode(Int.self, forKey: .slotIndex)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decode(String.self, forKey: .avatar)
        currentGrade = try container.decodeIfPresent(Grade.self, forKey: .currentGrade) ?? .kindergarten
        currentLevelPerGrade = try container.decodeIfPresent([Int: Int].self, forKey: .currentLevelPerGrade) ?? [:]
        highScorePerGrade = try container.decodeIfPresent([Int: Int].self, forKey: .highScorePerGrade) ?? [:]
        accuracyPerTopic = try container.decodeIfPresent([String: TopicStats].self, forKey: .accuracyPerTopic) ?? [:]
        badgesEarned = try container.decodeIfPresent([String: Date].self, forKey: .badgesEarned) ?? [:]
        totalPlayTime = try container.decodeIfPresent(TimeInterval.self, forKey: .totalPlayTime) ?? 0
        lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate) ?? Date()
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate) ?? Date()
        consecutiveDays = try container.decodeIfPresent(Int.self, forKey: .consecutiveDays) ?? 1
        lastPlayedDay = try container.decodeIfPresent(String.self, forKey: .lastPlayedDay) ?? PlayerProfile.todayString()
        totalIncredibleShots = try container.decodeIfPresent(Int.self, forKey: .totalIncredibleShots) ?? 0
        sessionIncredibleShots = try container.decodeIfPresent(Int.self, forKey: .sessionIncredibleShots) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        bestZone = try container.decodeIfPresent(String.self, forKey: .bestZone) ?? ""
        hasSeenProximityTip = try container.decodeIfPresent(Bool.self, forKey: .hasSeenProximityTip) ?? false
        selectedShipIndex = try container.decodeIfPresent(Int.self, forKey: .selectedShipIndex) ?? 0
    }

    func currentLevel(for grade: Grade) -> Int {
        return currentLevelPerGrade[grade.rawValue] ?? 1
    }

    func highScore(for grade: Grade) -> Int {
        return highScorePerGrade[grade.rawValue] ?? 0
    }

    func hasBadge(_ badge: Badge) -> Bool {
        return badgesEarned[badge.rawValue] != nil
    }

    func isGraduated(grade: Grade) -> Bool {
        return currentLevel(for: grade) > 20 && hasBadge(Badge.graduationBadge(for: grade))
    }

    var totalBadgeCount: Int {
        return badgesEarned.count
    }

    var overallAccuracy: Double {
        let total = accuracyPerTopic.values.reduce(0) { $0 + $1.total }
        let correct = accuracyPerTopic.values.reduce(0) { $0 + $1.correct }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var totalAttempted: Int {
        return accuracyPerTopic.values.reduce(0) { $0 + $1.total }
    }

    var totalCorrect: Int {
        return accuracyPerTopic.values.reduce(0) { $0 + $1.correct }
    }

    var gradesCompleted: Int {
        return Grade.allCases.filter { isGraduated(grade: $0) }.count
    }

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct TopicStats: Codable {
    var correct: Int
    var total: Int

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    init() {
        self.correct = 0
        self.total = 0
    }
}

struct ProgressReport {
    let profile: PlayerProfile
    let weakTopics: [MathTopic]
    let strongTopics: [MathTopic]
    let overallAccuracy: Double
    let totalProblemsAttempted: Int
    let favoriteLevel: Int

    var summaryText: String {
        var text = "Progress Report for \(profile.name)\n"
        text += "Grade: \(profile.currentGrade.displayName)\n"
        text += "Level: \(profile.currentLevel(for: profile.currentGrade))\n"
        text += "High Score: \(profile.highScore(for: profile.currentGrade))\n"
        text += "Overall Accuracy: \(Int(overallAccuracy * 100))%\n"
        text += "Problems Attempted: \(totalProblemsAttempted)\n\n"

        if !strongTopics.isEmpty {
            text += "Strengths:\n"
            for topic in strongTopics {
                text += "  + \(topic.displayName)\n"
            }
            text += "\n"
        }

        if !weakTopics.isEmpty {
            text += "Areas to Practice:\n"
            for topic in weakTopics {
                text += "  - \(topic.displayName)\n"
            }
        }

        return text
    }
}
