import SpriteKit

final class AdaptiveDifficulty {
    static let shared = AdaptiveDifficulty()

    private var recentAnswers: [Bool] = []
    private var recentTimes: [TimeInterval] = []
    private var speedMultiplier: CGFloat = 1.0

    private init() {}

    func reset() {
        recentAnswers = []
        recentTimes = []
        speedMultiplier = 1.0
    }

    func recordAnswer(correct: Bool, time: TimeInterval) {
        recentAnswers.append(correct)
        recentTimes.append(time)
        if recentAnswers.count > 10 {
            recentAnswers.removeFirst()
        }
        if recentTimes.count > 10 {
            recentTimes.removeFirst()
        }
        adjustDifficulty()
    }

    var accuracyRate: Double {
        guard recentAnswers.count >= 3 else { return 0.75 }
        let last5 = Array(recentAnswers.suffix(5))
        let correctCount = last5.filter { $0 }.count
        return Double(correctCount) / Double(last5.count)
    }

    var averageResponseTime: TimeInterval {
        guard !recentTimes.isEmpty else { return 3.0 }
        return recentTimes.reduce(0, +) / Double(recentTimes.count)
    }

    private func adjustDifficulty() {
        guard recentAnswers.count >= 5 else { return }

        if accuracyRate < 0.6 {
            speedMultiplier = max(0.6, speedMultiplier - 0.15)
        } else if accuracyRate > 0.9 {
            speedMultiplier = min(1.5, speedMultiplier + 0.1)
        }
    }

    func currentSpeed(for ageGroup: AgeGroup) -> CGFloat {
        let base = ageGroup.baseEnemySpeed
        let adjusted = base * speedMultiplier
        return min(max(adjusted, ageGroup.minEnemySpeed), ageGroup.maxEnemySpeed)
    }

    var isTooEasy: Bool {
        return recentAnswers.count >= 5 && accuracyRate > 0.9
    }

    var isTooHard: Bool {
        return recentAnswers.count >= 5 && accuracyRate < 0.6
    }

    var encouragementMessage: String? {
        if isTooHard {
            return "Keep going! You've got this!"
        } else if isTooEasy {
            return "Can you go faster?"
        }
        return nil
    }
}
