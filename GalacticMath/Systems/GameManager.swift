import Foundation

final class GameManager {
    static let shared = GameManager()
    static let maxSlots = 4
    static let avatarOptions = ["🚀", "🛸", "⭐", "🌟", "🌍"]

    var ageGroup: AgeGroup = .cadet
    var currentLevel: Int = 1
    var score: Int = 0
    var lives: Int = 5
    var correctStreak: Int = 0
    var totalCorrect: Int = 0
    var totalAttempted: Int = 0
    var problemsThisLevel: Int = 0
    var problemsPerLevel: Int = 15
    var currentSlotIndex: Int?

    private let oldProfilesKey = "galacticmath_profiles"

    var slots: [Int: PlayerProfile] = [:]
    var currentProfile: PlayerProfile? {
        guard let idx = currentSlotIndex else { return nil }
        return slots[idx]
    }

    private init() {
        migrateOldProfiles()
        loadAllSlots()
    }

    // MARK: - Slot Storage

    private static func slotKey(_ index: Int) -> String {
        "galacticmath_profile_slot_\(index)"
    }

    func loadAllSlots() {
        slots.removeAll()
        for i in 0..<GameManager.maxSlots {
            if let data = UserDefaults.standard.data(forKey: GameManager.slotKey(i)),
               let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
                slots[i] = profile
            }
        }
    }

    func saveSlot(_ index: Int) {
        guard let profile = slots[index] else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: GameManager.slotKey(index))
        }
    }

    func deleteSlot(_ index: Int) {
        slots.removeValue(forKey: index)
        UserDefaults.standard.removeObject(forKey: GameManager.slotKey(index))
        if currentSlotIndex == index {
            currentSlotIndex = nil
        }
    }

    // MARK: - Profile Management

    func createProfile(slotIndex: Int, name: String, avatar: String, ageGroup: AgeGroup) {
        let profile = PlayerProfile(slotIndex: slotIndex, name: name, avatar: avatar, ageGroup: ageGroup)
        slots[slotIndex] = profile
        saveSlot(slotIndex)
        selectSlot(slotIndex)
    }

    func selectSlot(_ index: Int) {
        guard slots[index] != nil else { return }
        currentSlotIndex = index
        ageGroup = slots[index]!.ageGroup
        slots[index]!.lastPlayedDate = Date()
        saveSlot(index)
    }

    func updateProfile(slotIndex: Int, name: String, avatar: String) {
        guard slots[slotIndex] != nil else { return }
        slots[slotIndex]!.name = name
        slots[slotIndex]!.avatar = avatar
        saveSlot(slotIndex)
    }

    func firstEmptySlot() -> Int? {
        for i in 0..<GameManager.maxSlots {
            if slots[i] == nil { return i }
        }
        return nil
    }

    // MARK: - Legacy Migration

    private struct LegacyPlayerProfile: Codable {
        var name: String
        var ageGroup: AgeGroup
        var avatarIndex: Int
        var currentLevel: Int
        var highScore: Int
        var totalCorrect: Int
        var totalAttempted: Int
        var topicAccuracy: [String: TopicStats]
        var totalPlayTime: TimeInterval
    }

    private func migrateOldProfiles() {
        guard let data = UserDefaults.standard.data(forKey: oldProfilesKey),
              let oldProfiles = try? JSONDecoder().decode([LegacyPlayerProfile].self, from: data) else {
            return
        }

        let avatars = GameManager.avatarOptions
        for (i, old) in oldProfiles.prefix(GameManager.maxSlots).enumerated() {
            // Skip if slot already has data
            if UserDefaults.standard.data(forKey: GameManager.slotKey(i)) != nil { continue }

            var profile = PlayerProfile(
                slotIndex: i,
                name: old.name,
                avatar: avatars[old.avatarIndex % avatars.count],
                ageGroup: old.ageGroup
            )
            profile.currentLevel = old.currentLevel
            profile.highScore = old.highScore
            profile.totalCorrect = old.totalCorrect
            profile.totalAttempted = old.totalAttempted
            profile.topicAccuracy = old.topicAccuracy
            profile.totalPlayTime = old.totalPlayTime

            if let encoded = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(encoded, forKey: GameManager.slotKey(i))
            }
        }

        UserDefaults.standard.removeObject(forKey: oldProfilesKey)
    }

    // MARK: - Game State

    func resetToMenu() {
        currentLevel = 1
        score = 0
        lives = ageGroup.lives
        correctStreak = 0
        totalCorrect = 0
        totalAttempted = 0
        problemsThisLevel = 0
        AdaptiveDifficulty.shared.reset()

        if let idx = currentSlotIndex, slots[idx] != nil {
            slots[idx]!.currentLevel = 1
            saveSlot(idx)
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

        if let idx = currentSlotIndex, slots[idx] != nil {
            slots[idx]!.totalCorrect += 1
            slots[idx]!.totalAttempted += 1
            if score > slots[idx]!.highScore {
                slots[idx]!.highScore = score
            }
            saveSlot(idx)
        }
    }

    func wrongAnswer() {
        totalAttempted += 1
        correctStreak = 0
        lives -= 1

        AdaptiveDifficulty.shared.recordAnswer(correct: false, time: 5.0)

        if let idx = currentSlotIndex, slots[idx] != nil {
            slots[idx]!.totalAttempted += 1
            saveSlot(idx)
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

    func recordTopicResult(topic: MathTopic, correct: Bool, time: TimeInterval) {
        guard let idx = currentSlotIndex, slots[idx] != nil else { return }
        let key = topic.rawValue
        var stats = slots[idx]!.topicAccuracy[key] ?? TopicStats()
        stats.total += 1
        if correct { stats.correct += 1 }
        stats.responseTimes.append(time)
        if stats.responseTimes.count > 50 {
            stats.responseTimes.removeFirst()
        }
        slots[idx]!.topicAccuracy[key] = stats
        saveSlot(idx)
    }
}
