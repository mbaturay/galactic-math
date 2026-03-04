import Foundation

final class GameManager {
    static let shared = GameManager()

    var ageGroup: AgeGroup = .cadet
    var currentLevel: Int = 1
    var score: Int = 0
    var lives: Int = 5
    var correctStreak: Int = 0
    var totalCorrect: Int = 0
    var totalAttempted: Int = 0
    var problemsThisLevel: Int = 0
    var problemsPerLevel: Int = 15
    var currentProfileIndex: Int = 0

    private let profilesKey = "galacticmath_profiles"
    private let highScoresKey = "galacticmath_highscores"

    var profiles: [PlayerProfile] = []
    var currentProfile: PlayerProfile? {
        guard currentProfileIndex < profiles.count else { return nil }
        return profiles[currentProfileIndex]
    }

    private init() {
        loadProfiles()
    }

    func resetToMenu() {
        currentLevel = 1
        score = 0
        lives = ageGroup.lives
        correctStreak = 0
        totalCorrect = 0
        totalAttempted = 0
        problemsThisLevel = 0
        AdaptiveDifficulty.shared.reset()

        // Reset persisted profile level
        if currentProfileIndex < profiles.count {
            profiles[currentProfileIndex].currentLevel = 1
            saveProfiles()
        }
    }

    func startNewGame(ageGroup: AgeGroup) {
        self.ageGroup = ageGroup
        self.currentLevel = 1
        self.score = 0
        self.lives = ageGroup.lives
        self.correctStreak = 0
        self.totalCorrect = 0
        self.totalAttempted = 0
        self.problemsThisLevel = 0
        AdaptiveDifficulty.shared.reset()
    }

    func correctAnswer(timeTaken: TimeInterval) {
        totalCorrect += 1
        totalAttempted += 1
        problemsThisLevel += 1
        correctStreak += 1

        // Score calculation
        var points = 100
        let speedBonus = max(0, Int(50.0 * (1.0 - min(timeTaken / 5.0, 1.0))))
        points += speedBonus

        if correctStreak >= 5 {
            points = Int(Double(points) * 2.0)
        } else if correctStreak >= 3 {
            points = Int(Double(points) * 1.5)
        }

        score += points

        AdaptiveDifficulty.shared.recordAnswer(correct: true, time: timeTaken)

        if var profile = currentProfile, currentProfileIndex < profiles.count {
            profile.totalCorrect += 1
            profile.totalAttempted += 1
            if score > profile.highScore {
                profile.highScore = score
            }
            profiles[currentProfileIndex] = profile
            saveProfiles()
        }
    }

    func wrongAnswer() {
        totalAttempted += 1
        correctStreak = 0
        lives -= 1

        AdaptiveDifficulty.shared.recordAnswer(correct: false, time: 5.0)

        if var profile = currentProfile, currentProfileIndex < profiles.count {
            profile.totalAttempted += 1
            profiles[currentProfileIndex] = profile
            saveProfiles()
        }
    }

    func isBossRound() -> Bool {
        return problemsThisLevel >= problemsPerLevel - 1
    }

    func isLevelComplete() -> Bool {
        return problemsThisLevel >= problemsPerLevel
    }

    func advanceLevel() {
        if currentLevel < ageGroup.maxLevel {
            currentLevel += 1
        }
        problemsThisLevel = 0
    }

    func isGameOver() -> Bool {
        return lives <= 0
    }

    var accuracy: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempted)
    }

    var starRating: Int {
        if accuracy > 0.9 { return 3 }
        if accuracy > 0.7 { return 2 }
        return 1
    }

    // MARK: - Profile Management

    func createProfile(name: String, ageGroup: AgeGroup, avatarIndex: Int) {
        let profile = PlayerProfile(name: name, ageGroup: ageGroup, avatarIndex: avatarIndex)
        profiles.append(profile)
        currentProfileIndex = profiles.count - 1
        saveProfiles()
    }

    func selectProfile(at index: Int) {
        guard index < profiles.count else { return }
        currentProfileIndex = index
        ageGroup = profiles[index].ageGroup
    }

    func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let loaded = try? JSONDecoder().decode([PlayerProfile].self, from: data) {
            profiles = loaded
        }
    }

    func recordTopicResult(topic: MathTopic, correct: Bool, time: TimeInterval) {
        guard currentProfileIndex < profiles.count else { return }
        let key = topic.rawValue
        var stats = profiles[currentProfileIndex].topicAccuracy[key] ?? TopicStats()
        stats.total += 1
        if correct { stats.correct += 1 }
        stats.responseTimes.append(time)
        if stats.responseTimes.count > 50 {
            stats.responseTimes.removeFirst()
        }
        profiles[currentProfileIndex].topicAccuracy[key] = stats
        saveProfiles()
    }
}
