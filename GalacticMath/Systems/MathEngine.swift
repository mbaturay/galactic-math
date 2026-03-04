import Foundation
import GameplayKit

final class MathEngine {
    static let shared = MathEngine()
    private let randomSource = GKRandomSource.sharedRandom()

    private init() {}

    func generateProblem(ageGroup: AgeGroup, level: Int) -> MathProblem {
        let topics = MathTopic.topics(for: ageGroup, level: level)
        let topic = topics.randomElement() ?? topics[0]
        return generateProblem(topic: topic, level: level, ageGroup: ageGroup)
    }

    func generateBossProblem(ageGroup: AgeGroup, level: Int) -> MathProblem {
        switch ageGroup {
        case .cadet:
            let a = Int.random(in: 5...10)
            let b = Int.random(in: 3...8)
            let correct = a + b
            return MathProblem(
                question: "\(a) + \(b) = ?",
                correctAnswer: correct,
                wrongAnswers: generateWrongAnswers(correct: correct, count: 4, minValue: 1),
                topic: .additionBasic,
                difficulty: level + 2
            )
        case .pilot:
            let a = Int.random(in: 6...12)
            let b = Int.random(in: 6...12)
            let correct = a * b
            return MathProblem(
                question: "\(a) x \(b) = ?",
                correctAnswer: correct,
                wrongAnswers: generateWrongAnswers(correct: correct, count: 4, minValue: 1),
                topic: .multiplicationBasic,
                difficulty: level + 2
            )
        case .ace:
            let x = Int.random(in: 2...8)
            let a = Int.random(in: 2...5)
            let b = Int.random(in: 1...15)
            let result = a * x + b
            let correct = x
            return MathProblem(
                question: "\(a)x + \(b) = \(result)  x = ?",
                correctAnswer: correct,
                wrongAnswers: generateWrongAnswers(correct: correct, count: 4, minValue: 1),
                topic: .algebraBasic,
                difficulty: level + 2
            )
        }
    }

    private func generateProblem(topic: MathTopic, level: Int, ageGroup: AgeGroup) -> MathProblem {
        let wrongCount = ageGroup == .cadet ? 2 : 4

        switch topic {
        case .counting:
            return generateCountingProblem(level: level, wrongCount: wrongCount)
        case .additionBasic:
            return generateBasicAddition(level: level, wrongCount: wrongCount)
        case .subtractionBasic:
            return generateBasicSubtraction(level: level, wrongCount: wrongCount)
        case .additionAdvanced:
            return generateAdvancedAddition(level: level, wrongCount: wrongCount)
        case .subtractionAdvanced:
            return generateAdvancedSubtraction(level: level, wrongCount: wrongCount)
        case .multiplicationBasic:
            return generateBasicMultiplication(level: level, wrongCount: wrongCount)
        case .divisionBasic:
            return generateBasicDivision(level: level, wrongCount: wrongCount)
        case .missingNumber:
            return generateMissingNumber(level: level, wrongCount: wrongCount)
        case .multiplicationAdvanced:
            return generateAdvancedMultiplication(level: level, wrongCount: wrongCount)
        case .divisionAdvanced:
            return generateAdvancedDivision(level: level, wrongCount: wrongCount)
        case .fractions:
            return generateFractions(level: level, wrongCount: wrongCount)
        case .decimals:
            return generateDecimals(level: level, wrongCount: wrongCount)
        case .percentages:
            return generatePercentages(level: level, wrongCount: wrongCount)
        case .patterns:
            return generatePatterns(level: level, wrongCount: wrongCount)
        case .algebraBasic:
            return generateAlgebra(level: level, wrongCount: wrongCount)
        }
    }

    // MARK: - Cadet Problems

    private func generateCountingProblem(level: Int, wrongCount: Int) -> MathProblem {
        let maxCount = level <= 1 ? 5 : 10
        let count = Int.random(in: 1...maxCount)
        let stars = String(repeating: "\u{2B50}", count: count)
        return MathProblem(
            question: "Count: \(stars)",
            correctAnswer: count,
            wrongAnswers: generateWrongAnswers(correct: count, count: wrongCount, minValue: 1),
            topic: .counting,
            difficulty: level
        )
    }

    private func generateBasicAddition(level: Int, wrongCount: Int) -> MathProblem {
        let maxVal = level <= 3 ? 5 : 10
        let a = Int.random(in: 1...maxVal)
        let b = Int.random(in: 1...maxVal)
        let correct = a + b
        return MathProblem(
            question: "\(a) + \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: .additionBasic,
            difficulty: level
        )
    }

    private func generateBasicSubtraction(level: Int, wrongCount: Int) -> MathProblem {
        let maxVal = level <= 5 ? 5 : 10
        let a = Int.random(in: 2...maxVal)
        let b = Int.random(in: 1...a)
        let correct = a - b
        return MathProblem(
            question: "\(a) - \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: .subtractionBasic,
            difficulty: level
        )
    }

    // MARK: - Pilot Problems

    private func generateAdvancedAddition(level: Int, wrongCount: Int) -> MathProblem {
        let maxVal = level <= 1 ? 20 : 100
        let a = Int.random(in: 10...maxVal)
        let b = Int.random(in: 5...(maxVal / 2))
        let correct = a + b
        return MathProblem(
            question: "\(a) + \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .additionAdvanced,
            difficulty: level
        )
    }

    private func generateAdvancedSubtraction(level: Int, wrongCount: Int) -> MathProblem {
        let maxVal = level <= 1 ? 20 : 100
        let a = Int.random(in: 15...maxVal)
        let b = Int.random(in: 5...(a - 1))
        let correct = a - b
        return MathProblem(
            question: "\(a) - \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: .subtractionAdvanced,
            difficulty: level
        )
    }

    private func generateBasicMultiplication(level: Int, wrongCount: Int) -> MathProblem {
        let tables: [Int]
        switch level {
        case 3: tables = [2, 5, 10]
        case 4: tables = [3, 4]
        case 5: tables = [6, 7, 8, 9]
        default: tables = [2, 3, 4, 5, 6, 7, 8, 9, 10]
        }
        let a = tables.randomElement() ?? 2
        let b = Int.random(in: 1...12)
        let correct = a * b
        return MathProblem(
            question: "\(a) x \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .multiplicationBasic,
            difficulty: level
        )
    }

    private func generateBasicDivision(level: Int, wrongCount: Int) -> MathProblem {
        let divisor = Int.random(in: 2...10)
        let quotient = Int.random(in: 1...12)
        let dividend = divisor * quotient
        return MathProblem(
            question: "\(dividend) \u{00F7} \(divisor) = ?",
            correctAnswer: quotient,
            wrongAnswers: generateWrongAnswers(correct: quotient, count: wrongCount, minValue: 1),
            topic: .divisionBasic,
            difficulty: level
        )
    }

    private func generateMissingNumber(level: Int, wrongCount: Int) -> MathProblem {
        let a = Int.random(in: 2...9)
        let b = Int.random(in: 2...9)
        let product = a * b
        return MathProblem(
            question: "\(a) x ? = \(product)",
            correctAnswer: b,
            wrongAnswers: generateWrongAnswers(correct: b, count: wrongCount, minValue: 1),
            topic: .missingNumber,
            difficulty: level
        )
    }

    // MARK: - Ace Problems

    private func generateAdvancedMultiplication(level: Int, wrongCount: Int) -> MathProblem {
        let a = Int.random(in: 11...19)
        let b = Int.random(in: 11...19)
        let correct = a * b
        return MathProblem(
            question: "\(a) x \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 10),
            topic: .multiplicationAdvanced,
            difficulty: level
        )
    }

    private func generateAdvancedDivision(level: Int, wrongCount: Int) -> MathProblem {
        let divisor = Int.random(in: 6...15)
        let quotient = Int.random(in: 6...15)
        let dividend = divisor * quotient
        return MathProblem(
            question: "\(dividend) \u{00F7} \(divisor) = ?",
            correctAnswer: quotient,
            wrongAnswers: generateWrongAnswers(correct: quotient, count: wrongCount, minValue: 1),
            topic: .divisionAdvanced,
            difficulty: level
        )
    }

    private func generateFractions(level: Int, wrongCount: Int) -> MathProblem {
        if level <= 3 {
            let denom = [2, 3, 4, 5, 6].randomElement()!
            let num1 = Int.random(in: 1...(denom - 1))
            let num2 = Int.random(in: 1...(denom - 1))
            let sumNum = num1 + num2
            if sumNum <= denom {
                return MathProblem(
                    question: "\(num1)/\(denom) + \(num2)/\(denom) = ?/\(denom)",
                    correctAnswer: sumNum,
                    wrongAnswers: generateWrongAnswers(correct: sumNum, count: wrongCount, minValue: 1),
                    topic: .fractions,
                    difficulty: level
                )
            } else {
                let correct = sumNum
                return MathProblem(
                    question: "\(num1)/\(denom) + \(num2)/\(denom) = ?/\(denom)",
                    correctAnswer: correct,
                    wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                    topic: .fractions,
                    difficulty: level
                )
            }
        } else {
            let d1 = [2, 3, 4].randomElement()!
            let d2 = d1 * Int.random(in: 2...3)
            let n1 = Int.random(in: 1...(d1 - 1))
            let n2 = Int.random(in: 1...(d2 - 1))
            let commonDenom = d2
            let adjustedN1 = n1 * (d2 / d1)
            let sumNum = adjustedN1 + n2
            return MathProblem(
                question: "\(n1)/\(d1) + \(n2)/\(d2) = ?/\(commonDenom)",
                correctAnswer: sumNum,
                wrongAnswers: generateWrongAnswers(correct: sumNum, count: wrongCount, minValue: 1),
                topic: .fractions,
                difficulty: level
            )
        }
    }

    private func generateDecimals(level: Int, wrongCount: Int) -> MathProblem {
        let a = Double.random(in: 1.0...9.9)
        let b = Double.random(in: 1.0...9.9)
        let aRounded = (a * 10).rounded() / 10
        let bRounded = (b * 10).rounded() / 10
        let sum = ((aRounded + bRounded) * 10).rounded() / 10
        let correct = Int(sum * 10)
        return MathProblem(
            question: "\(String(format: "%.1f", aRounded)) + \(String(format: "%.1f", bRounded)) = ? (x10)",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 10),
            topic: .decimals,
            difficulty: level
        )
    }

    private func generatePercentages(level: Int, wrongCount: Int) -> MathProblem {
        let percents = [10, 20, 25, 50, 75]
        let pct = percents.randomElement()!
        let bases = [20, 40, 50, 60, 80, 100, 200]
        let base = bases.randomElement()!
        let correct = (pct * base) / 100
        return MathProblem(
            question: "\(pct)% of \(base) = ?",
            correctAnswer: correct,
            wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .percentages,
            difficulty: level
        )
    }

    private func generatePatterns(level: Int, wrongCount: Int) -> MathProblem {
        let patternType = Int.random(in: 0...2)
        switch patternType {
        case 0:
            let start = Int.random(in: 1...5)
            let step = Int.random(in: 2...5)
            let seq = (0..<4).map { start + step * $0 }
            let correct = start + step * 4
            let question = seq.map { String($0) }.joined(separator: ", ") + ", ?"
            return MathProblem(
                question: question,
                correctAnswer: correct,
                wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .patterns,
                difficulty: level
            )
        case 1:
            let start = Int.random(in: 2...3)
            let seq = (0..<4).map { Int(pow(Double(start), Double($0 + 1))) }
            let correct = Int(pow(Double(start), 5.0))
            let question = seq.map { String($0) }.joined(separator: ", ") + ", ?"
            return MathProblem(
                question: question,
                correctAnswer: correct,
                wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .patterns,
                difficulty: level
            )
        default:
            let start = Int.random(in: 1...5)
            let step = Int.random(in: 3...7)
            let seq = (0..<4).map { start + step * $0 }
            let correct = start + step * 4
            let question = seq.map { String($0) }.joined(separator: ", ") + ", ?"
            return MathProblem(
                question: question,
                correctAnswer: correct,
                wrongAnswers: generateWrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .patterns,
                difficulty: level
            )
        }
    }

    private func generateAlgebra(level: Int, wrongCount: Int) -> MathProblem {
        let x = Int.random(in: 1...10)
        let a = Int.random(in: 2...5)
        let b = Int.random(in: 1...10)
        let result = a * x + b
        return MathProblem(
            question: "\(a)x + \(b) = \(result)  x = ?",
            correctAnswer: x,
            wrongAnswers: generateWrongAnswers(correct: x, count: wrongCount, minValue: 1),
            topic: .algebraBasic,
            difficulty: level
        )
    }

    // MARK: - Wrong Answer Generation

    func generateWrongAnswers(correct: Int, count: Int, minValue: Int = 0) -> [Int] {
        var wrongs = Set<Int>()
        let offsets = [-3, -2, -1, 1, 2, 3, -5, 5, -10, 10, 4, -4]
        for offset in offsets.shuffled() {
            let candidate = correct + offset
            if candidate >= minValue && candidate != correct && !wrongs.contains(candidate) {
                wrongs.insert(candidate)
                if wrongs.count >= count { break }
            }
        }
        while wrongs.count < count {
            let candidate = correct + Int.random(in: 1...20) * (Bool.random() ? 1 : -1)
            let adjusted = max(minValue, candidate)
            if adjusted != correct && !wrongs.contains(adjusted) {
                wrongs.insert(adjusted)
            }
        }
        return Array(wrongs.prefix(count))
    }
}
