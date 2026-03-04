import Foundation

struct GradeLevel {
    let grade: Grade
    let levelNumber: Int
    let topic: MathTopic
    let difficultyWithinTopic: Int

    var displayName: String {
        return "Level \(levelNumber) \u{00B7} \(topic.displayName)"
    }

    var isBadgeLevel: Bool {
        return levelNumber % 5 == 0
    }

    var isGraduationLevel: Bool {
        return levelNumber == 20
    }
}

struct Curriculum {
    static func levels(for grade: Grade) -> [GradeLevel] {
        let topics = topicsForGrade(grade)
        var result: [GradeLevel] = []
        for (topicIndex, topic) in topics.enumerated() {
            for diff in 1...4 {
                let levelNum = topicIndex * 4 + diff
                result.append(GradeLevel(
                    grade: grade,
                    levelNumber: levelNum,
                    topic: topic,
                    difficultyWithinTopic: diff
                ))
            }
        }
        return result
    }

    static func level(for grade: Grade, levelNumber: Int) -> GradeLevel? {
        let all = levels(for: grade)
        return all.first { $0.levelNumber == levelNumber }
    }

    private static func topicsForGrade(_ grade: Grade) -> [MathTopic] {
        switch grade {
        case .kindergarten:
            return [.counting1to10, .counting11to20, .comparingNumbers, .additionWithin5, .subtractionWithin5]
        case .grade1:
            return [.additionWithin10, .subtractionWithin10, .additionWithin20, .subtractionWithin20, .placeValue]
        case .grade2:
            return [.additionWithin100, .subtractionWithin100, .skipCounting, .introMultiplication, .timeAndMeasurement]
        case .grade3:
            return [.multiplicationBasic, .multiplicationMedium, .multiplicationAdvanced, .divisionBasic, .fractionsIntro]
        case .grade4:
            return [.multiDigitMultiplication, .longDivision, .equivalentFractions, .addSubtractFractions, .decimalsIntro]
        case .grade5:
            return [.multiplyFractions, .divideFractions, .decimalOperations, .volumeBasics, .coordinatePlane]
        case .grade6:
            return [.ratiosAndRates, .percentages, .negativeNumbers, .oneStepEquations, .complexArea]
        case .grade7:
            return [.twoStepEquations, .proportionalRelationships, .probability, .geometry, .mixedChallenge]
        }
    }

    static func topicList(for grade: Grade) -> [MathTopic] {
        return topicsForGrade(grade)
    }
}
