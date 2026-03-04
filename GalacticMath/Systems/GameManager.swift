import Foundation

final class GameManager {
    static let shared = GameManager()
    static let maxSlots = 4
    static let avatarOptions = ["\u{1F680}", "\u{1F6F8}", "\u{2B50}", "\u{1F31F}", "\u{1F30D}"]

    var currentGrade: Grade = .kindergarten
    var currentLevelNumber: Int = 1
    var currentLevel: Int { return currentLevelNumber }
    var score: Int = 0
    var lives: Int = 5
    var correctStreak: Int = 0
    var totalCorrect: Int = 0
    var totalAttempted: Int = 0
    var problemsThisLevel: Int = 0
    var problemsPerLevel: Int = 15
    var currentSlotIndex: Int?

    var sessionIncredibleShots: Int = 0
    var consecutiveIncredibleShots: Int = 0
    var consecutiveWrongAnswers: Int = 0

    private let oldProfilesKey = "galacticmath_profiles"

    var slots: [Int: PlayerProfile] = [:]
    var currentProfile: PlayerProfile? {
        guard let idx = currentSlotIndex else { return nil }
        return slots[idx]
    }

    var currentGradeLevel: GradeLevel? {
        return Curriculum.level(for: currentGrade, levelNumber: currentLevelNumber)
    }

    private init() {
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

    func createProfile(slotIndex: Int, name: String, avatar: String, grade: Grade) {
        let profile = PlayerProfile(slotIndex: slotIndex, name: name, avatar: avatar, grade: grade)
        slots[slotIndex] = profile
        saveSlot(slotIndex)
        selectSlot(slotIndex)
    }

    func selectSlot(_ index: Int) {
        guard slots[index] != nil else { return }
        currentSlotIndex = index
        currentGrade = slots[index]!.currentGrade
        currentLevelNumber = slots[index]!.currentLevel(for: currentGrade)
        slots[index]!.lastPlayedDate = Date()
        updateConsecutiveDays(slotIndex: index)
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

    private func updateConsecutiveDays(slotIndex: Int) {
        guard slots[slotIndex] != nil else { return }
        let today = PlayerProfile.todayString()
        let lastDay = slots[slotIndex]!.lastPlayedDay

        if today != lastDay {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let lastDate = formatter.date(from: lastDay),
               let todayDate = formatter.date(from: today) {
                let diff = Calendar.current.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
                if diff == 1 {
                    slots[slotIndex]!.consecutiveDays += 1
                } else if diff > 1 {
                    slots[slotIndex]!.consecutiveDays = 1
                }
            }
            slots[slotIndex]!.lastPlayedDay = today
        }
    }

    // MARK: - Game State

    func resetToMenu() {
        score = 0
        lives = currentGrade.lives
        correctStreak = 0
        totalCorrect = 0
        totalAttempted = 0
        problemsThisLevel = 0
        sessionIncredibleShots = 0
        consecutiveIncredibleShots = 0
        consecutiveWrongAnswers = 0
        AdaptiveDifficulty.shared.reset()
    }

    func startNewGame(grade: Grade, levelNumber: Int = 0) {
        self.currentGrade = grade
        self.currentLevelNumber = levelNumber > 0 ? levelNumber : (currentProfile?.currentLevel(for: grade) ?? 1)
        self.score = 0
        self.lives = grade.lives
        self.correctStreak = 0
        self.totalCorrect = 0
        self.totalAttempted = 0
        self.problemsThisLevel = 0
        self.sessionIncredibleShots = 0
        self.consecutiveIncredibleShots = 0
        self.consecutiveWrongAnswers = 0
        AdaptiveDifficulty.shared.reset()

        if let idx = currentSlotIndex, slots[idx] != nil {
            slots[idx]!.currentGrade = grade
            slots[idx]!.sessionIncredibleShots = 0
            saveSlot(idx)
        }
    }

    func correctAnswer(timeTaken: TimeInterval, points: Int) {
        totalCorrect += 1
        totalAttempted += 1
        problemsThisLevel += 1
        correctStreak += 1
        consecutiveWrongAnswers = 0

        score += points

        AdaptiveDifficulty.shared.recordAnswer(correct: true, time: timeTaken)

        if let idx = currentSlotIndex, slots[idx] != nil {
            // Update streak tracking
            slots[idx]!.currentStreak = correctStreak
            if correctStreak > slots[idx]!.longestStreak {
                slots[idx]!.longestStreak = correctStreak
            }

            // Update high score for grade
            let gradeKey = currentGrade.rawValue
            let currentHigh = slots[idx]!.highScorePerGrade[gradeKey] ?? 0
            if score > currentHigh {
                slots[idx]!.highScorePerGrade[gradeKey] = score
            }
            saveSlot(idx)
        }
    }

    var difficultyMultiplier: Double {
        return currentGrade.difficultyMultiplier
    }

    func updateBestZone(_ zone: String) {
        guard let idx = currentSlotIndex, slots[idx] != nil else { return }
        let ranks = ["CLOSE", "GOOD", "AMAZING", "INCREDIBLE"]
        let currentRank = ranks.firstIndex(of: slots[idx]!.bestZone) ?? -1
        let newRank = ranks.firstIndex(of: zone) ?? -1
        if newRank > currentRank {
            slots[idx]!.bestZone = zone
            saveSlot(idx)
        }
    }

    func markProximityTipSeen() {
        guard let idx = currentSlotIndex, slots[idx] != nil else { return }
        slots[idx]!.hasSeenProximityTip = true
        saveSlot(idx)
    }

    func wrongAnswer() {
        totalAttempted += 1
        correctStreak = 0
        consecutiveWrongAnswers += 1
        consecutiveIncredibleShots = 0
        lives -= 1

        AdaptiveDifficulty.shared.recordAnswer(correct: false, time: 5.0)

        if let idx = currentSlotIndex, slots[idx] != nil {
            slots[idx]!.currentStreak = 0
            saveSlot(idx)
        }
    }

    func isBossRound() -> Bool {
        return problemsThisLevel >= problemsPerLevel - 1
    }

    func isLevelComplete() -> Bool {
        return problemsThisLevel >= problemsPerLevel
    }

    func advanceLevel() -> [Badge] {
        var earnedBadges: [Badge] = []

        if let idx = currentSlotIndex, slots[idx] != nil {
            let completedLevel = currentLevelNumber

            // Check badges
            earnedBadges = BadgeManager.shared.checkBadges(
                profile: &slots[idx]!,
                grade: currentGrade,
                levelCompleted: completedLevel,
                accuracy: accuracy,
                sessionIncredibleShots: sessionIncredibleShots,
                currentStreak: correctStreak
            )

            // Advance level within grade
            if currentLevelNumber < currentGrade.maxLevel {
                currentLevelNumber += 1
            }

            // Save level progress
            slots[idx]!.currentLevelPerGrade[currentGrade.rawValue] = currentLevelNumber
            saveSlot(idx)
        } else {
            if currentLevelNumber < currentGrade.maxLevel {
                currentLevelNumber += 1
            }
        }

        problemsThisLevel = 0
        return earnedBadges
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
        var stats = slots[idx]!.accuracyPerTopic[key] ?? TopicStats()
        stats.total += 1
        if correct { stats.correct += 1 }
        slots[idx]!.accuracyPerTopic[key] = stats
        saveSlot(idx)
    }

    // MARK: - Incredible Shot Tracking

    func recordIncredibleShot() {
        sessionIncredibleShots += 1
        consecutiveIncredibleShots += 1

        if let idx = currentSlotIndex, slots[idx] != nil {
            slots[idx]!.sessionIncredibleShots = sessionIncredibleShots
            slots[idx]!.totalIncredibleShots += 1

            // Check sharpshooter: 5 incredible in a row
            if consecutiveIncredibleShots >= 5 && !slots[idx]!.hasBadge(.sharpshooter) {
                slots[idx]!.badgesEarned[Badge.sharpshooter.rawValue] = Date()
            }
            saveSlot(idx)
        }
    }

    func resetIncredibleStreak() {
        consecutiveIncredibleShots = 0
    }

    // MARK: - Comeback Detection

    func checkComeback() -> Badge? {
        guard consecutiveWrongAnswers >= 3 else { return nil }
        guard let idx = currentSlotIndex, slots[idx] != nil else { return nil }
        return BadgeManager.shared.checkRealtimeBadge(
            profile: &slots[idx]!,
            event: .comebackAnswer
        )
    }
}
