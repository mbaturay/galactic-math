import SpriteKit

final class AdaptiveDifficulty {
    static let shared = AdaptiveDifficulty()

    private var recentAnswers: [Bool] = []
    private var recentTimes: [TimeInterval] = []
    private var speedMultiplier: CGFloat = 1.0
    private var previousSpeedMultiplier: CGFloat = 1.0

    // Rolling average of last 5 correct answer times
    private var correctTimes: [TimeInterval] = []
    private var totalCorrectCount: Int = 0
    private var consecutiveWrong: Int = 0

    // Cooldowns (CACurrentMediaTime)
    private var lastMessageTime: TimeInterval = 0        // Global: max 1 per 30s
    private var lastFasterMessageTime: TimeInterval = 0   // "Can you go faster?" cooldown: 60s
    private var lastEncourageTime: TimeInterval = 0       // Encouragement cooldown: 30s

    private init() {}

    func reset() {
        recentAnswers = []
        recentTimes = []
        correctTimes = []
        speedMultiplier = 1.0
        previousSpeedMultiplier = 1.0
        totalCorrectCount = 0
        consecutiveWrong = 0
        lastMessageTime = 0
        lastFasterMessageTime = 0
        lastEncourageTime = 0
    }

    // MARK: - Recording

    func recordAnswer(correct: Bool, time: TimeInterval) {
        recentAnswers.append(correct)
        recentTimes.append(time)
        if recentAnswers.count > 10 { recentAnswers.removeFirst() }
        if recentTimes.count > 10 { recentTimes.removeFirst() }

        if correct {
            totalCorrectCount += 1
            consecutiveWrong = 0
            correctTimes.append(time)
            if correctTimes.count > 5 { correctTimes.removeFirst() }
        } else {
            consecutiveWrong += 1
        }

        previousSpeedMultiplier = speedMultiplier
        adjustDifficulty()
    }

    // MARK: - Stats

    var accuracyRate: Double {
        guard recentAnswers.count >= 3 else { return 0.75 }
        let last5 = Array(recentAnswers.suffix(5))
        let correctCount = last5.filter { $0 }.count
        return Double(correctCount) / Double(last5.count)
    }

    var averageResponseTime: TimeInterval {
        guard !correctTimes.isEmpty else { return 3.0 }
        return correctTimes.reduce(0, +) / Double(correctTimes.count)
    }

    // MARK: - Difficulty Adjustment

    private func adjustDifficulty() {
        guard recentAnswers.count >= 5 else { return }

        if accuracyRate < 0.6 {
            speedMultiplier = max(0.6, speedMultiplier - 0.15)
        } else if accuracyRate > 0.9 {
            speedMultiplier = min(1.5, speedMultiplier + 0.1)
        }
    }

    func currentSpeed(for grade: Grade) -> CGFloat {
        let base = grade.enemySpeed
        let adjusted = base * speedMultiplier
        return min(max(adjusted, grade.minEnemySpeed), grade.maxEnemySpeed)
    }

    /// True when speed just increased (after recordAnswer)
    var didSpeedIncrease: Bool {
        return speedMultiplier > previousSpeedMultiplier
    }

    // MARK: - Message Logic

    /// Returns the appropriate message after a correct answer, or nil.
    /// Call this once per correct answer from GameScene.
    func messageAfterCorrectAnswer(timeTaken: TimeInterval, streak: Int, isBossRound: Bool) -> (text: String, color: SKColor)? {
        // Never during boss
        guard !isBossRound else { return nil }

        let now = CACurrentMediaTime()

        // Global cooldown: 1 message per 30 seconds
        guard now - lastMessageTime >= 30.0 else { return nil }

        // Priority 1: Streak milestones
        if streak == 5 {
            lastMessageTime = now
            return ("🔥 ON FIRE!", SKColor.orange)
        }
        if streak == 10 {
            lastMessageTime = now
            return ("⭐ UNSTOPPABLE!", SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0))
        }

        // Priority 2: Speed increase notification
        if didSpeedIncrease {
            lastMessageTime = now
            return ("Level Up! 🚀", SKColor.cyan)
        }

        // Priority 3: "Can you go faster?" — only when doing well but slow
        if totalCorrectCount >= 5
            && correctTimes.count >= 5
            && timeTaken > averageResponseTime * 2.0
            && accuracyRate > 0.8
            && now - lastFasterMessageTime >= 60.0
        {
            lastMessageTime = now
            lastFasterMessageTime = now
            return ("Can you go faster?", SKColor(white: 0.85, alpha: 1.0))
        }

        return nil
    }

    /// Returns encouragement after a wrong answer, or nil.
    func messageAfterWrongAnswer(isBossRound: Bool) -> (text: String, color: SKColor)? {
        guard !isBossRound else { return nil }

        let now = CACurrentMediaTime()

        // Global cooldown
        guard now - lastMessageTime >= 30.0 else { return nil }

        // 3 wrong in a row + own cooldown
        if consecutiveWrong >= 3 && now - lastEncourageTime >= 30.0 {
            lastMessageTime = now
            lastEncourageTime = now
            return ("Keep going! You've got this! ⭐", SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0))
        }

        // Speed decrease: show nothing (silently help)
        return nil
    }
}
