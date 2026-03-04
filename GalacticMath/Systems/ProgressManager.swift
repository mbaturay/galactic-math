import Foundation

final class ProgressManager {
    static let shared = ProgressManager()

    private init() {}

    func generateReport(for profile: PlayerProfile) -> ProgressReport {
        var weakTopics: [MathTopic] = []
        var strongTopics: [MathTopic] = []

        for (key, stats) in profile.accuracyPerTopic {
            guard let topic = MathTopic(rawValue: key) else { continue }
            if stats.accuracy < 0.7 && stats.total >= 3 {
                weakTopics.append(topic)
            } else if stats.accuracy > 0.9 && stats.total >= 3 {
                strongTopics.append(topic)
            }
        }

        let overallAccuracy: Double
        if profile.totalAttempted > 0 {
            overallAccuracy = Double(profile.totalCorrect) / Double(profile.totalAttempted)
        } else {
            overallAccuracy = 0
        }

        return ProgressReport(
            profile: profile,
            weakTopics: weakTopics,
            strongTopics: strongTopics,
            overallAccuracy: overallAccuracy,
            totalProblemsAttempted: profile.totalAttempted,
            favoriteLevel: profile.currentLevel(for: profile.currentGrade)
        )
    }
}
