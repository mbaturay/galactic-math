import Foundation

struct PlayerProfile: Codable {
    let slotIndex: Int
    var name: String
    var avatar: String
    var ageGroup: AgeGroup
    var currentLevel: Int
    var highScore: Int
    var totalCorrect: Int
    var totalAttempted: Int
    var topicAccuracy: [String: TopicStats]
    var totalPlayTime: TimeInterval
    var createdDate: Date
    var lastPlayedDate: Date
    var bestZone: String
    var hasSeenProximityTip: Bool

    init(slotIndex: Int, name: String, avatar: String, ageGroup: AgeGroup) {
        self.slotIndex = slotIndex
        self.name = name
        self.avatar = avatar
        self.ageGroup = ageGroup
        self.currentLevel = 1
        self.highScore = 0
        self.totalCorrect = 0
        self.totalAttempted = 0
        self.topicAccuracy = [:]
        self.totalPlayTime = 0
        self.createdDate = Date()
        self.lastPlayedDate = Date()
        self.bestZone = ""
        self.hasSeenProximityTip = false
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slotIndex = try container.decode(Int.self, forKey: .slotIndex)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decode(String.self, forKey: .avatar)
        ageGroup = try container.decode(AgeGroup.self, forKey: .ageGroup)
        currentLevel = try container.decode(Int.self, forKey: .currentLevel)
        highScore = try container.decode(Int.self, forKey: .highScore)
        totalCorrect = try container.decode(Int.self, forKey: .totalCorrect)
        totalAttempted = try container.decode(Int.self, forKey: .totalAttempted)
        topicAccuracy = try container.decode([String: TopicStats].self, forKey: .topicAccuracy)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastPlayedDate = try container.decode(Date.self, forKey: .lastPlayedDate)
        bestZone = try container.decodeIfPresent(String.self, forKey: .bestZone) ?? ""
        hasSeenProximityTip = try container.decodeIfPresent(Bool.self, forKey: .hasSeenProximityTip) ?? false
    }
}

struct TopicStats: Codable {
    var correct: Int
    var total: Int
    var responseTimes: [TimeInterval]

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var averageTime: TimeInterval {
        guard !responseTimes.isEmpty else { return 0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }

    init() {
        self.correct = 0
        self.total = 0
        self.responseTimes = []
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
        text += "Age Group: \(profile.ageGroup.displayName)\n"
        text += "Current Level: \(profile.currentLevel)\n"
        text += "High Score: \(profile.highScore)\n"
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
