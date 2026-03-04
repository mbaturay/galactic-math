import Foundation

final class BadgeManager {
    static let shared = BadgeManager()
    private init() {}

    func checkBadges(
        profile: inout PlayerProfile,
        grade: Grade,
        levelCompleted: Int,
        accuracy: Double,
        sessionIncredibleShots: Int,
        currentStreak: Int
    ) -> [Badge] {
        var newBadges: [Badge] = []

        // Milestone badges at levels 5, 10, 15, 20
        if let badge = Badge.milestoneBadge(grade: grade, level: levelCompleted),
           !profile.hasBadge(badge) {
            profile.badgesEarned[badge.rawValue] = Date()
            newBadges.append(badge)
        }

        // Graduation badge at level 20
        if levelCompleted == 20 {
            let gradBadge = Badge.graduationBadge(for: grade)
            if !profile.hasBadge(gradBadge) {
                profile.badgesEarned[gradBadge.rawValue] = Date()
                newBadges.append(gradBadge)
            }
        }

        // Rainbow Scholar: graduated all 8 grades
        if Grade.allCases.allSatisfy({ profile.isGraduated(grade: $0) }),
           !profile.hasBadge(.rainbowScholar) {
            profile.badgesEarned[Badge.rainbowScholar.rawValue] = Date()
            newBadges.append(.rainbowScholar)
        }

        // Perfectionist: 100% accuracy in completed grade
        if accuracy >= 1.0 && !profile.hasBadge(.perfectionist) {
            profile.badgesEarned[Badge.perfectionist.rawValue] = Date()
            newBadges.append(.perfectionist)
        }

        // Game Master: graduate a grade with 100% accuracy across all its topics
        if levelCompleted == 20 && !profile.hasBadge(.gameMaster) {
            let topics = Curriculum.topicList(for: grade)
            let allPerfect = topics.allSatisfy { topic in
                let stats = profile.accuracyPerTopic[topic.rawValue]
                return stats != nil && stats!.total > 0 && stats!.accuracy >= 1.0
            }
            if allPerfect {
                profile.badgesEarned[Badge.gameMaster.rawValue] = Date()
                newBadges.append(.gameMaster)
            }
        }

        // Speed Demon: 10 incredible shots in session
        if sessionIncredibleShots >= 10 && !profile.hasBadge(.speedDemon) {
            profile.badgesEarned[Badge.speedDemon.rawValue] = Date()
            newBadges.append(.speedDemon)
        }

        // On Fire: 20 correct in a row
        if currentStreak >= 20 && !profile.hasBadge(.onFire) {
            profile.badgesEarned[Badge.onFire.rawValue] = Date()
            newBadges.append(.onFire)
        }

        // Week Warrior: 7 consecutive days
        if profile.consecutiveDays >= 7 && !profile.hasBadge(.weekWarrior) {
            profile.badgesEarned[Badge.weekWarrior.rawValue] = Date()
            newBadges.append(.weekWarrior)
        }

        // Time-based badges
        let hour = Calendar.current.component(.hour, from: Date())
        if (hour >= 21 || hour < 0) && !profile.hasBadge(.nightOwl) {
            profile.badgesEarned[Badge.nightOwl.rawValue] = Date()
            newBadges.append(.nightOwl)
        }
        if hour < 7 && !profile.hasBadge(.earlyBird) {
            profile.badgesEarned[Badge.earlyBird.rawValue] = Date()
            newBadges.append(.earlyBird)
        }

        return newBadges
    }

    func checkRealtimeBadge(
        profile: inout PlayerProfile,
        event: GameEvent
    ) -> Badge? {
        switch event {
        case .incredibleShot:
            profile.sessionIncredibleShots += 1
            profile.totalIncredibleShots += 1
            if profile.sessionIncredibleShots >= 10 && !profile.hasBadge(.speedDemon) {
                profile.badgesEarned[Badge.speedDemon.rawValue] = Date()
                return .speedDemon
            }

        case .correctStreak(let count):
            if count >= 20 && !profile.hasBadge(.onFire) {
                profile.badgesEarned[Badge.onFire.rawValue] = Date()
                return .onFire
            }

        case .comebackAnswer:
            if !profile.hasBadge(.comebackKid) {
                profile.badgesEarned[Badge.comebackKid.rawValue] = Date()
                return .comebackKid
            }
        }
        return nil
    }
}
