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
