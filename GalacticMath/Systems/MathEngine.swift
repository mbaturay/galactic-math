import Foundation
import GameplayKit

final class MathEngine {
    static let shared = MathEngine()
    private init() {}

    func generateProblem(grade: Grade, level: GradeLevel) -> MathProblem {
        let wrongCount = grade.beamCount == 3 ? 2 : 4
        return validatedProblem(topic: level.topic, difficulty: level.difficultyWithinTopic, wrongCount: wrongCount)
    }

    func generateBossProblem(grade: Grade, level: Int) -> MathProblem {
        guard let gradeLevel = Curriculum.level(for: grade, levelNumber: level) else {
            return validatedProblem(topic: .additionWithin10, difficulty: 4, wrongCount: 4)
        }
        let wrongCount = grade.beamCount == 3 ? 2 : 4
        return validatedProblem(topic: gradeLevel.topic, difficulty: 4, wrongCount: wrongCount)
    }

    /// Generate a problem and sanity-check it. Regenerate up to 3 times if invalid.
    private func validatedProblem(topic: MathTopic, difficulty: Int, wrongCount: Int) -> MathProblem {
        for attempt in 0..<3 {
            let problem = generateForTopic(topic, difficulty: difficulty, wrongCount: wrongCount)
            if validateProblem(problem) {
                return problem
            }
            print("[MathEngine] WARNING: Problem failed validation (attempt \(attempt + 1)): "
                  + "q=\"\(problem.question)\" answer=\(problem.correctAnswer) topic=\(topic)")
        }
        // Final fallback — return whatever we get
        let problem = generateForTopic(topic, difficulty: difficulty, wrongCount: wrongCount)
        if !validateProblem(problem) {
            print("[MathEngine] WARNING: Problem still invalid after retries: "
                  + "q=\"\(problem.question)\" answer=\(problem.correctAnswer)")
        }
        return problem
    }

    /// Check that the problem is self-consistent:
    /// - correctAnswer is not in wrongAnswers
    /// - wrongAnswers are all distinct
    /// - question string is non-empty
    /// - correctAnswer is a reasonable integer (not absurdly large)
    private func validateProblem(_ problem: MathProblem) -> Bool {
        guard !problem.question.isEmpty else { return false }
        guard !problem.wrongAnswers.contains(problem.correctAnswer) else { return false }
        guard Set(problem.wrongAnswers).count == problem.wrongAnswers.count else { return false }
        guard abs(problem.correctAnswer) < 10000 else { return false }
        return true
    }

    private func generateForTopic(_ topic: MathTopic, difficulty: Int, wrongCount: Int) -> MathProblem {
        switch topic {
        // Kindergarten
        case .counting1to10:        return genCounting(max: 10, difficulty: difficulty, wrongCount: wrongCount)
        case .counting11to20:       return genCounting(max: 20, difficulty: difficulty, wrongCount: wrongCount)
        case .comparingNumbers:     return genComparing(difficulty: difficulty, wrongCount: wrongCount)
        case .additionWithin5:      return genAddition(max: 5, difficulty: difficulty, wrongCount: wrongCount)
        case .subtractionWithin5:   return genSubtraction(max: 5, difficulty: difficulty, wrongCount: wrongCount)
        // Grade 1
        case .additionWithin10:     return genAddition(max: 10, difficulty: difficulty, wrongCount: wrongCount)
        case .subtractionWithin10:  return genSubtraction(max: 10, difficulty: difficulty, wrongCount: wrongCount)
        case .additionWithin20:     return genAddition(max: 20, difficulty: difficulty, wrongCount: wrongCount)
        case .subtractionWithin20:  return genSubtraction(max: 20, difficulty: difficulty, wrongCount: wrongCount)
        case .placeValue:           return genPlaceValue(difficulty: difficulty, wrongCount: wrongCount)
        // Grade 2
        case .additionWithin100:    return genAddition(max: 100, difficulty: difficulty, wrongCount: wrongCount)
        case .subtractionWithin100: return genSubtraction(max: 100, difficulty: difficulty, wrongCount: wrongCount)
        case .skipCounting:         return genSkipCounting(difficulty: difficulty, wrongCount: wrongCount)
        case .introMultiplication:  return genIntroMult(difficulty: difficulty, wrongCount: wrongCount)
        case .timeAndMeasurement:   return genTime(difficulty: difficulty, wrongCount: wrongCount)
        // Grade 3
        case .multiplicationBasic:  return genMultBasic(difficulty: difficulty, wrongCount: wrongCount)
        case .multiplicationMedium: return genMultMedium(difficulty: difficulty, wrongCount: wrongCount)
        case .multiplicationAdvanced: return genMultAdvanced(difficulty: difficulty, wrongCount: wrongCount)
        case .divisionBasic:        return genDivision(difficulty: difficulty, wrongCount: wrongCount)
        case .fractionsIntro:       return genFractionsIntro(difficulty: difficulty, wrongCount: wrongCount)
        // Grade 4
        case .multiDigitMultiplication: return genMultiDigitMult(difficulty: difficulty, wrongCount: wrongCount)
        case .longDivision:         return genLongDivision(difficulty: difficulty, wrongCount: wrongCount)
        case .equivalentFractions:  return genEquivalentFractions(difficulty: difficulty, wrongCount: wrongCount)
        case .addSubtractFractions: return genAddSubFractions(difficulty: difficulty, wrongCount: wrongCount)
        case .decimalsIntro:        return genDecimalsIntro(difficulty: difficulty, wrongCount: wrongCount)
        // Grade 5
        case .multiplyFractions:    return genMultFractions(difficulty: difficulty, wrongCount: wrongCount)
        case .divideFractions:      return genDivFractions(difficulty: difficulty, wrongCount: wrongCount)
        case .decimalOperations:    return genDecimalOps(difficulty: difficulty, wrongCount: wrongCount)
        case .volumeBasics:         return genVolume(difficulty: difficulty, wrongCount: wrongCount)
        case .coordinatePlane:      return genCoordinates(difficulty: difficulty, wrongCount: wrongCount)
        // Grade 6
        case .ratiosAndRates:       return genRatios(difficulty: difficulty, wrongCount: wrongCount)
        case .percentages:          return genPercentages(difficulty: difficulty, wrongCount: wrongCount)
        case .negativeNumbers:      return genNegatives(difficulty: difficulty, wrongCount: wrongCount)
        case .oneStepEquations:     return genOneStepEq(difficulty: difficulty, wrongCount: wrongCount)
        case .complexArea:          return genArea(difficulty: difficulty, wrongCount: wrongCount)
        // Grade 7
        case .twoStepEquations:     return genTwoStepEq(difficulty: difficulty, wrongCount: wrongCount)
        case .proportionalRelationships: return genProportions(difficulty: difficulty, wrongCount: wrongCount)
        case .probability:          return genProbability(difficulty: difficulty, wrongCount: wrongCount)
        case .geometry:             return genGeometry(difficulty: difficulty, wrongCount: wrongCount)
        case .mixedChallenge:       return genMixed(difficulty: difficulty, wrongCount: wrongCount)
        }
    }

    // MARK: - Counting

    private static let countingAnimals = ["\u{1F431}", "\u{1F436}", "\u{1F438}", "\u{1F43C}", "\u{1F428}", "\u{1F98A}", "\u{1F430}", "\u{1F43B}", "\u{1F42F}", "\u{1F981}"]

    private func genCounting(max: Int, difficulty: Int, wrongCount: Int) -> MathProblem {
        let lower = max <= 10 ? 1 : 11
        let upper: Int
        switch difficulty {
        case 1: upper = lower + 2
        case 2: upper = lower + 4
        case 3: upper = lower + 6
        default: upper = max
        }
        let count = Int.random(in: lower...min(upper, max))
        let animal = MathEngine.countingAnimals.randomElement()!
        let emojis = Array(repeating: animal, count: count).joined(separator: " ")
        return MathProblem(
            question: "Count: \(emojis)",
            correctAnswer: count,
            wrongAnswers: wrongAnswers(correct: count, count: wrongCount, minValue: 1),
            topic: max <= 10 ? .counting1to10 : .counting11to20,
            difficulty: difficulty,
            countingEmoji: animal
        )
    }

    // MARK: - Comparing

    private func genComparing(difficulty: Int, wrongCount: Int) -> MathProblem {
        let maxVal = difficulty <= 2 ? 10 : 20
        let a = Int.random(in: 1...maxVal)
        var b = Int.random(in: 1...maxVal)
        while b == a { b = Int.random(in: 1...maxVal) }
        let correct = max(a, b)
        return MathProblem(
            question: "Which is bigger: \(a) or \(b)?",
            correctAnswer: correct,
            wrongAnswers: [min(a, b)] + wrongAnswers(correct: correct, count: wrongCount - 1, minValue: 1),
            topic: .comparingNumbers,
            difficulty: difficulty
        )
    }

    // MARK: - Addition / Subtraction

    private func genAddition(max: Int, difficulty: Int, wrongCount: Int) -> MathProblem {
        let upperA: Int
        switch difficulty {
        case 1: upperA = max / 3
        case 2: upperA = max / 2
        case 3: upperA = max * 2 / 3
        default: upperA = max
        }
        let a = Int.random(in: 1...Swift.max(upperA, 2))
        let bMax = Swift.min(max - a, a + 5)
        let b = Int.random(in: 1...Swift.max(bMax, 1))
        let correct = a + b
        let topic: MathTopic
        if max <= 5 { topic = .additionWithin5 }
        else if max <= 10 { topic = .additionWithin10 }
        else if max <= 20 { topic = .additionWithin20 }
        else { topic = .additionWithin100 }

        return MathProblem(
            question: "\(a) + \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: topic,
            difficulty: difficulty
        )
    }

    private func genSubtraction(max: Int, difficulty: Int, wrongCount: Int) -> MathProblem {
        let upperA: Int
        switch difficulty {
        case 1: upperA = max / 3
        case 2: upperA = max / 2
        case 3: upperA = max * 2 / 3
        default: upperA = max
        }
        let a = Int.random(in: 2...Swift.max(upperA, 3))
        let b = Int.random(in: 1...a)
        let correct = a - b
        let topic: MathTopic
        if max <= 5 { topic = .subtractionWithin5 }
        else if max <= 10 { topic = .subtractionWithin10 }
        else if max <= 20 { topic = .subtractionWithin20 }
        else { topic = .subtractionWithin100 }

        return MathProblem(
            question: "\(a) - \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: topic,
            difficulty: difficulty
        )
    }

    // MARK: - Place Value

    private func genPlaceValue(difficulty: Int, wrongCount: Int) -> MathProblem {
        let number: Int
        switch difficulty {
        case 1: number = Int.random(in: 10...49)
        case 2: number = Int.random(in: 10...99)
        case 3: number = Int.random(in: 100...499)
        default: number = Int.random(in: 100...999)
        }

        let askTens = difficulty <= 2 || Bool.random()
        if askTens {
            let correct = (number / 10) % 10
            return MathProblem(
                question: "Tens digit of \(number)?",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
                topic: .placeValue,
                difficulty: difficulty
            )
        } else {
            let correct = (number / 100) % 10
            return MathProblem(
                question: "Hundreds digit of \(number)?",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
                topic: .placeValue,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Skip Counting

    private func genSkipCounting(difficulty: Int, wrongCount: Int) -> MathProblem {
        let step: Int
        switch difficulty {
        case 1: step = 2
        case 2: step = 5
        case 3: step = 10
        default: step = [2, 3, 5, 10].randomElement()!
        }
        let start = step * Int.random(in: 1...4)
        let seq = (0..<4).map { start + step * $0 }
        let correct = start + step * 4
        let question = seq.map { String($0) }.joined(separator: ", ") + ", ?"
        return MathProblem(
            question: question,
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .skipCounting,
            difficulty: difficulty
        )
    }

    // MARK: - Intro Multiplication

    private func genIntroMult(difficulty: Int, wrongCount: Int) -> MathProblem {
        let groups: Int
        switch difficulty {
        case 1: groups = 2
        case 2: groups = Int.random(in: 2...3)
        case 3: groups = Int.random(in: 2...4)
        default: groups = Int.random(in: 2...5)
        }
        let perGroup = Int.random(in: 2...5)
        let correct = groups * perGroup
        return MathProblem(
            question: "\(groups) groups of \(perGroup) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .introMultiplication,
            difficulty: difficulty
        )
    }

    // MARK: - Time

    private func genTime(difficulty: Int, wrongCount: Int) -> MathProblem {
        let hour = Int.random(in: 1...12)
        let minutes: Int
        switch difficulty {
        case 1: minutes = 0
        case 2: minutes = [0, 30].randomElement()!
        case 3: minutes = [0, 15, 30, 45].randomElement()!
        default: minutes = Int.random(in: 0...11) * 5
        }
        let addMin = [15, 30, 45, 60].randomElement()!
        let totalMin = hour * 60 + minutes + addMin
        let newHour = (totalMin / 60) % 12
        let newMin = totalMin % 60
        let displayHour = newHour == 0 ? 12 : newHour
        let correct = displayHour * 100 + newMin
        let timeStr = String(format: "%d:%02d", hour, minutes)
        return MathProblem(
            question: "\(addMin)min after \(timeStr)? (HMM)",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 100),
            topic: .timeAndMeasurement,
            difficulty: difficulty
        )
    }

    // MARK: - Multiplication (Grade 3)

    private func genMultBasic(difficulty: Int, wrongCount: Int) -> MathProblem {
        let tables: [Int]
        switch difficulty {
        case 1: tables = [2]
        case 2: tables = [5]
        case 3: tables = [10]
        default: tables = [2, 5, 10]
        }
        let a = tables.randomElement()!
        let b = Int.random(in: 1...12)
        let correct = a * b
        return MathProblem(
            question: "\(a) x \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .multiplicationBasic,
            difficulty: difficulty
        )
    }

    private func genMultMedium(difficulty: Int, wrongCount: Int) -> MathProblem {
        let tables: [Int]
        switch difficulty {
        case 1: tables = [3]
        case 2: tables = [4]
        case 3: tables = [3, 4]
        default: tables = [3, 4]
        }
        let a = tables.randomElement()!
        let b = Int.random(in: 1...12)
        let correct = a * b
        return MathProblem(
            question: "\(a) x \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .multiplicationMedium,
            difficulty: difficulty
        )
    }

    private func genMultAdvanced(difficulty: Int, wrongCount: Int) -> MathProblem {
        let tables: [Int]
        switch difficulty {
        case 1: tables = [6]
        case 2: tables = [7]
        case 3: tables = [8, 9]
        default: tables = [6, 7, 8, 9]
        }
        let a = tables.randomElement()!
        let b = Int.random(in: 2...12)
        let correct = a * b
        return MathProblem(
            question: "\(a) x \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .multiplicationAdvanced,
            difficulty: difficulty
        )
    }

    // MARK: - Division (Grade 3)

    private func genDivision(difficulty: Int, wrongCount: Int) -> MathProblem {
        let divisor: Int
        switch difficulty {
        case 1: divisor = [2, 5].randomElement()!
        case 2: divisor = [2, 3, 4, 5].randomElement()!
        case 3: divisor = Int.random(in: 2...8)
        default: divisor = Int.random(in: 2...12)
        }
        let quotient = Int.random(in: 1...12)
        let dividend = divisor * quotient
        return MathProblem(
            question: "\(dividend) \u{00F7} \(divisor) = ?",
            correctAnswer: quotient,
            wrongAnswers: wrongAnswers(correct: quotient, count: wrongCount, minValue: 1),
            topic: .divisionBasic,
            difficulty: difficulty
        )
    }

    // MARK: - Fractions Intro (Grade 3)

    private func genFractionsIntro(difficulty: Int, wrongCount: Int) -> MathProblem {
        let denom = [2, 3, 4].randomElement()!
        let num1 = Int.random(in: 1...(denom - 1))
        let num2 = difficulty <= 2 ? 1 : Int.random(in: 1...(denom - 1))
        let correct = num1 + num2
        return MathProblem(
            question: "\(num1)/\(denom) + \(num2)/\(denom) = ?/\(denom)",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .fractionsIntro,
            difficulty: difficulty
        )
    }

    // MARK: - Multi-digit Multiplication (Grade 4)

    private func genMultiDigitMult(difficulty: Int, wrongCount: Int) -> MathProblem {
        let a: Int; let b: Int
        switch difficulty {
        case 1: a = Int.random(in: 10...19); b = Int.random(in: 2...5)
        case 2: a = Int.random(in: 10...30); b = Int.random(in: 2...9)
        case 3: a = Int.random(in: 10...50); b = Int.random(in: 5...12)
        default: a = Int.random(in: 11...99); b = Int.random(in: 2...12)
        }
        let correct = a * b
        return MathProblem(
            question: "\(a) x \(b) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 10),
            topic: .multiDigitMultiplication,
            difficulty: difficulty
        )
    }

    // MARK: - Long Division (Grade 4)

    private func genLongDivision(difficulty: Int, wrongCount: Int) -> MathProblem {
        let divisor: Int; let quotient: Int
        switch difficulty {
        case 1: divisor = Int.random(in: 2...5); quotient = Int.random(in: 10...20)
        case 2: divisor = Int.random(in: 3...8); quotient = Int.random(in: 10...30)
        case 3: divisor = Int.random(in: 4...12); quotient = Int.random(in: 10...40)
        default: divisor = Int.random(in: 5...15); quotient = Int.random(in: 10...50)
        }
        let dividend = divisor * quotient
        return MathProblem(
            question: "\(dividend) \u{00F7} \(divisor) = ?",
            correctAnswer: quotient,
            wrongAnswers: wrongAnswers(correct: quotient, count: wrongCount, minValue: 1),
            topic: .longDivision,
            difficulty: difficulty
        )
    }

    // MARK: - Equivalent Fractions (Grade 4)

    private func genEquivalentFractions(difficulty: Int, wrongCount: Int) -> MathProblem {
        let num = Int.random(in: 1...3)
        let denom = Int.random(in: 2...5)
        let multiplier = Int.random(in: 2...4)
        let newDenom = denom * multiplier
        let correct = num * multiplier
        return MathProblem(
            question: "\(num)/\(denom) = ?/\(newDenom)",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .equivalentFractions,
            difficulty: difficulty
        )
    }

    // MARK: - Add/Subtract Fractions (Grade 4)

    private func genAddSubFractions(difficulty: Int, wrongCount: Int) -> MathProblem {
        let denom = [3, 4, 5, 6].randomElement()!
        let num1 = Int.random(in: 1...(denom - 1))
        let num2 = Int.random(in: 1...(denom - 1))
        let isAdd = difficulty <= 2 || Bool.random()
        if isAdd {
            let correct = num1 + num2
            return MathProblem(
                question: "\(num1)/\(denom) + \(num2)/\(denom) = ?/\(denom)",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .addSubtractFractions,
                difficulty: difficulty
            )
        } else {
            let bigger = max(num1, num2)
            let smaller = min(num1, num2)
            let correct = bigger - smaller
            return MathProblem(
                question: "\(bigger)/\(denom) - \(smaller)/\(denom) = ?/\(denom)",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
                topic: .addSubtractFractions,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Decimals Intro (Grade 4)

    private func genDecimalsIntro(difficulty: Int, wrongCount: Int) -> MathProblem {
        let a = Double.random(in: 1.0...5.0)
        let b = Double.random(in: 1.0...5.0)
        let aR = (a * 10).rounded() / 10
        let bR = (b * 10).rounded() / 10
        let sum = ((aR + bR) * 10).rounded() / 10
        let correct = Int(sum * 10)
        return MathProblem(
            question: "\(String(format: "%.1f", aR)) + \(String(format: "%.1f", bR)) = ? (x10)",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 10),
            topic: .decimalsIntro,
            difficulty: difficulty
        )
    }

    // MARK: - Multiply Fractions (Grade 5)
    // Constructive: pick answer k, pick d1/d2, derive n1/n2 so (n1*n2)/(d1*d2) = k

    private func genMultFractions(difficulty: Int, wrongCount: Int) -> MathProblem {
        let k = Int.random(in: 1...(difficulty <= 2 ? 4 : 6))
        let d1 = Int.random(in: 2...(difficulty <= 2 ? 3 : 5))
        let d2 = Int.random(in: 2...(difficulty <= 2 ? 3 : 5))
        let target = k * d1 * d2  // n1 * n2 must equal this

        // Find factor pairs of target, pick one with reasonable values
        var pairs: [(Int, Int)] = []
        for f in 1...target where target % f == 0 {
            let other = target / f
            if f <= 12 && other <= 12 { pairs.append((f, other)) }
        }
        let (n1, n2) = pairs.randomElement() ?? (target, 1)

        return MathProblem(
            question: "\(n1)/\(d1) x \(n2)/\(d2) = ?",
            correctAnswer: k,
            wrongAnswers: wrongAnswers(correct: k, count: wrongCount, minValue: 1),
            topic: .multiplyFractions,
            difficulty: difficulty
        )
    }

    // MARK: - Divide Fractions (Grade 5)
    // Constructive: pick answer k, pick b and c, derive a/d so (a/b) ÷ (c/d) = k

    private func genDivFractions(difficulty: Int, wrongCount: Int) -> MathProblem {
        let k = Int.random(in: 1...(difficulty <= 2 ? 3 : 5))
        let b = Int.random(in: 2...(difficulty <= 2 ? 3 : 5))
        let c = Int.random(in: 1...(difficulty <= 2 ? 3 : 4))
        let target = k * b * c  // a * d must equal this (since a*d / b*c = k)

        var pairs: [(Int, Int)] = []
        for f in 1...target where target % f == 0 {
            let other = target / f
            if f <= 12 && other <= 12 { pairs.append((f, other)) }
        }
        let (a, d) = pairs.randomElement() ?? (target, 1)

        return MathProblem(
            question: "\(a)/\(b) \u{00F7} \(c)/\(d) = ?",
            correctAnswer: k,
            wrongAnswers: wrongAnswers(correct: k, count: wrongCount, minValue: 1),
            topic: .divideFractions,
            difficulty: difficulty
        )
    }

    // MARK: - Decimal Operations (Grade 5)

    private func genDecimalOps(difficulty: Int, wrongCount: Int) -> MathProblem {
        let a = Double.random(in: 1.0...9.9)
        let b = Double.random(in: 1.0...9.9)
        let aR = (a * 10).rounded() / 10
        let bR = (b * 10).rounded() / 10
        let isAdd = difficulty <= 2 || Bool.random()
        let result: Double
        let op: String
        if isAdd {
            result = aR + bR
            op = "+"
        } else {
            let bigger = max(aR, bR)
            let smaller = min(aR, bR)
            result = bigger - smaller
            let correct = Int((result * 10).rounded())
            return MathProblem(
                question: "\(String(format: "%.1f", bigger)) - \(String(format: "%.1f", smaller)) = ? (x10)",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
                topic: .decimalOperations,
                difficulty: difficulty
            )
        }
        let correct = Int((result * 10).rounded())
        return MathProblem(
            question: "\(String(format: "%.1f", aR)) \(op) \(String(format: "%.1f", bR)) = ? (x10)",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: .decimalOperations,
            difficulty: difficulty
        )
    }

    // MARK: - Volume (Grade 5)

    private func genVolume(difficulty: Int, wrongCount: Int) -> MathProblem {
        let l = Int.random(in: 2...6)
        let w = Int.random(in: 2...6)
        let h = Int.random(in: 2...6)
        let correct = l * w * h
        return MathProblem(
            question: "Vol: \(l)x\(w)x\(h) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .volumeBasics,
            difficulty: difficulty
        )
    }

    // MARK: - Coordinate Plane (Grade 5)

    private func genCoordinates(difficulty: Int, wrongCount: Int) -> MathProblem {
        let x1 = Int.random(in: 1...5)
        let y1 = Int.random(in: 1...5)
        let x2 = Int.random(in: 1...5)
        let y2 = Int.random(in: 1...5)
        let correct = abs(x2 - x1) + abs(y2 - y1)
        return MathProblem(
            question: "Distance (\(x1),\(y1)) to (\(x2),\(y2))?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 0),
            topic: .coordinatePlane,
            difficulty: difficulty
        )
    }

    // MARK: - Ratios (Grade 6)

    private func genRatios(difficulty: Int, wrongCount: Int) -> MathProblem {
        let a = Int.random(in: 2...5)
        var b = Int.random(in: 2...5)
        while b == a { b = Int.random(in: 2...5) }
        let maxMult = difficulty <= 2 ? 4 : 6
        let multiplier = Int.random(in: 2...maxMult)
        let newA = a * multiplier
        let correct = b * multiplier
        return MathProblem(
            question: "\(a):\(b) = \(newA):?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .ratiosAndRates,
            difficulty: difficulty
        )
    }

    // MARK: - Percentages (Grade 6)

    private func genPercentages(difficulty: Int, wrongCount: Int) -> MathProblem {
        let pcts: [Int]
        switch difficulty {
        case 1: pcts = [50]
        case 2: pcts = [10, 50]
        case 3: pcts = [10, 20, 25, 50]
        default: pcts = [10, 20, 25, 50, 75]
        }
        let pct = pcts.randomElement()!
        let bases = [20, 40, 50, 60, 80, 100, 200]
        let base = bases.randomElement()!
        let correct = (pct * base) / 100
        return MathProblem(
            question: "\(pct)% of \(base) = ?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .percentages,
            difficulty: difficulty
        )
    }

    // MARK: - Negative Numbers (Grade 6)

    private func genNegatives(difficulty: Int, wrongCount: Int) -> MathProblem {
        let a = Int.random(in: -10...10)
        let b = Int.random(in: -10...10)
        let isAdd = difficulty <= 2 || Bool.random()
        let correct: Int
        let question: String
        if isAdd {
            correct = a + b
            question = "\(a) + \(b < 0 ? "(\(b))" : "\(b)") = ?"
        } else {
            correct = a - b
            question = "\(a) - \(b < 0 ? "(\(b))" : "\(b)") = ?"
        }
        return MathProblem(
            question: question,
            correctAnswer: correct,
            wrongAnswers: wrongAnswersNeg(correct: correct, count: wrongCount),
            topic: .negativeNumbers,
            difficulty: difficulty
        )
    }

    // MARK: - One-Step Equations (Grade 6)

    private func genOneStepEq(difficulty: Int, wrongCount: Int) -> MathProblem {
        let x = Int.random(in: 1...12)
        let a = Int.random(in: 2...8)
        let result = a * x
        return MathProblem(
            question: "\(a)x = \(result)  x = ?",
            correctAnswer: x,
            wrongAnswers: wrongAnswers(correct: x, count: wrongCount, minValue: 1),
            topic: .oneStepEquations,
            difficulty: difficulty
        )
    }

    // MARK: - Complex Area (Grade 6)

    private func genArea(difficulty: Int, wrongCount: Int) -> MathProblem {
        if difficulty <= 2 {
            let b = Int.random(in: 3...10)
            let h = Int.random(in: 3...10)
            let correct = (b * h) / 2
            return MathProblem(
                question: "Triangle: b=\(b), h=\(h). Area=?",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .complexArea,
                difficulty: difficulty
            )
        } else {
            let a = Int.random(in: 3...8)
            let b = Int.random(in: 5...12)
            let h = Int.random(in: 3...8)
            let correct = ((a + b) * h) / 2
            return MathProblem(
                question: "Trapezoid: a=\(a),b=\(b),h=\(h). Area=?",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .complexArea,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Two-Step Equations (Grade 7)

    private func genTwoStepEq(difficulty: Int, wrongCount: Int) -> MathProblem {
        let x = Int.random(in: 1...10)
        let a = Int.random(in: 2...5)
        let b = Int.random(in: 1...15)
        let result = a * x + b
        return MathProblem(
            question: "\(a)x + \(b) = \(result)  x = ?",
            correctAnswer: x,
            wrongAnswers: wrongAnswers(correct: x, count: wrongCount, minValue: 1),
            topic: .twoStepEquations,
            difficulty: difficulty
        )
    }

    // MARK: - Proportions (Grade 7)

    private func genProportions(difficulty: Int, wrongCount: Int) -> MathProblem {
        let a = Int.random(in: 2...6)
        let b = Int.random(in: 2...6)
        let mult = Int.random(in: 2...8)
        let newA = a * mult
        let correct = b * mult
        return MathProblem(
            question: "\(a)/\(b) = \(newA)/?",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .proportionalRelationships,
            difficulty: difficulty
        )
    }

    // MARK: - Probability (Grade 7)

    private func genProbability(difficulty: Int, wrongCount: Int) -> MathProblem {
        let denom = [2, 4, 5, 10].randomElement()!
        let num = Int.random(in: 1...(denom - 1))
        let correct = (num * 100) / denom
        return MathProblem(
            question: "\(num) in \(denom) chance = ?%",
            correctAnswer: correct,
            wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
            topic: .probability,
            difficulty: difficulty
        )
    }

    // MARK: - Geometry (Grade 7)

    private func genGeometry(difficulty: Int, wrongCount: Int) -> MathProblem {
        switch difficulty {
        case 1:
            return MathProblem(
                question: "Sum of angles in triangle = ?",
                correctAnswer: 180,
                wrongAnswers: wrongAnswers(correct: 180, count: wrongCount, minValue: 90),
                topic: .geometry,
                difficulty: difficulty
            )
        case 2:
            let angle1 = Int.random(in: 30...80)
            let angle2 = Int.random(in: 30...80)
            let correct = 180 - angle1 - angle2
            return MathProblem(
                question: "Triangle: \(angle1)\u{00B0}+\(angle2)\u{00B0}+?\u{00B0}=180\u{00B0}",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .geometry,
                difficulty: difficulty
            )
        case 3:
            return MathProblem(
                question: "Sum of angles in quadrilateral = ?",
                correctAnswer: 360,
                wrongAnswers: wrongAnswers(correct: 360, count: wrongCount, minValue: 180),
                topic: .geometry,
                difficulty: difficulty
            )
        default:
            let side = Int.random(in: 3...8)
            let correct = side * side
            return MathProblem(
                question: "Square side=\(side). Area=?",
                correctAnswer: correct,
                wrongAnswers: wrongAnswers(correct: correct, count: wrongCount, minValue: 1),
                topic: .geometry,
                difficulty: difficulty
            )
        }
    }

    // MARK: - Mixed Challenge (Grade 7)

    private func genMixed(difficulty: Int, wrongCount: Int) -> MathProblem {
        let topics: [MathTopic] = [.twoStepEquations, .percentages, .negativeNumbers, .probability, .geometry]
        let topic = topics.randomElement()!
        return generateForTopic(topic, difficulty: difficulty, wrongCount: wrongCount)
    }

    // MARK: - Wrong Answer Generation

    func wrongAnswers(correct: Int, count: Int, minValue: Int = 0) -> [Int] {
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

    private func wrongAnswersNeg(correct: Int, count: Int) -> [Int] {
        var wrongs = Set<Int>()
        let offsets = [-3, -2, -1, 1, 2, 3, -5, 5]
        for offset in offsets.shuffled() {
            let candidate = correct + offset
            if candidate != correct && !wrongs.contains(candidate) {
                wrongs.insert(candidate)
                if wrongs.count >= count { break }
            }
        }
        while wrongs.count < count {
            let candidate = correct + Int.random(in: 1...10) * (Bool.random() ? 1 : -1)
            if candidate != correct && !wrongs.contains(candidate) {
                wrongs.insert(candidate)
            }
        }
        return Array(wrongs.prefix(count))
    }
}
