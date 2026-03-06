import Foundation

struct MathProblem {
    let question: String
    let correctAnswer: Int
    let wrongAnswers: [Int]
    let topic: MathTopic
    let difficulty: Int
    var countingEmoji: String? = nil

    var allAnswers: [Int] {
        return ([correctAnswer] + wrongAnswers).shuffled()
    }

    /// The bare math expression with no "= ?", "Count:", or narrative wrapper.
    /// e.g. "3 + 5 = ?" → "3 + 5",  "Count: 🍎 🍎 🍎" → "🍎 🍎 🍎"
    var coreExpression: String {
        let q = question

        // Counting problems: strip "Count: " prefix
        if q.hasPrefix("Count: ") {
            return String(q.dropFirst(7))
        }
        if q.hasPrefix("Count:") {
            return String(q.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        }

        // Strip "  x = ?" (two-step/one-step equations: "5x + 14 = 29  x = ?")
        if let range = q.range(of: "  x = ?") {
            return String(q[q.startIndex..<range.lowerBound])
        }

        // Fraction with denominator context: "3/4 + 1/4 = ?/4" — keep the "= ?/4" part
        // The player needs to see the target denominator to know they're entering a numerator
        if q.range(of: " = ?/") != nil {
            return q
        }

        // Ratio/proportion: "3:5 = 6:?" or "2/3 = 10/?" — keep the full form
        if q.hasSuffix(":?") || q.hasSuffix("/?") {
            return q
        }

        // Strip " = ?" at end
        if q.hasSuffix(" = ?") {
            return String(q.dropLast(4))
        }

        // Strip trailing "=?" (no space, e.g. "Area=?")
        if q.hasSuffix("=?") {
            return String(q.dropLast(2))
        }

        // Strip trailing "?" for narrative questions ("Which is bigger: 5 or 3?")
        if q.hasSuffix("?") {
            return String(q.dropLast(1)).trimmingCharacters(in: .whitespaces)
        }

        return q.trimmingCharacters(in: .whitespaces)
    }

    func answers(for beamCount: Int) -> [Int] {
        var answers = [correctAnswer]
        let needed = beamCount - 1
        let available = Array(wrongAnswers.prefix(needed))
        answers.append(contentsOf: available)
        while answers.count < beamCount {
            var extra = correctAnswer + Int.random(in: 1...10)
            while answers.contains(extra) {
                extra += 1
            }
            answers.append(extra)
        }
        return answers.shuffled()
    }
}
