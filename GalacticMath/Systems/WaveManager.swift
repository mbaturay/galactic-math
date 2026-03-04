import SpriteKit

protocol WaveManagerDelegate: AnyObject {
    func waveManagerDidRequestNewProblem(_ problem: MathProblem)
    func waveManagerCorrectAnswer()
    func waveManagerWrongAnswer()
    func waveManagerEnemyReachedBottom()
    func waveManagerBossRound(_ problem: MathProblem)
}

final class WaveManager {
    weak var delegate: WaveManagerDelegate?

    var currentProblem: MathProblem?
    var answersOnScreen: [NumberEnemy] = []
    var attemptCount: Int = 0
    var maxAttempts: Int = 3
    var isWaitingForNext: Bool = false
    var isBossActive: Bool = false
    var bossDefeatedThisLevel: Bool = false

    private let grade: Grade
    private let gameManager = GameManager.shared
    private let mathEngine = MathEngine.shared

    init(grade: Grade) {
        self.grade = grade
    }

    func startNewProblem() {
        guard !isWaitingForNext else { return }
        attemptCount = 0

        if gameManager.isBossRound() && !isBossActive && !bossDefeatedThisLevel {
            let problem = mathEngine.generateBossProblem(grade: grade, level: gameManager.currentLevel)
            currentProblem = problem
            isBossActive = true
            delegate?.waveManagerBossRound(problem)
            return
        }

        if let gradeLevel = Curriculum.level(for: grade, levelNumber: gameManager.currentLevel) {
            let problem = mathEngine.generateProblem(grade: grade, level: gradeLevel)
            currentProblem = problem
            delegate?.waveManagerDidRequestNewProblem(problem)
        }
    }

    func handleAnswerHit(answer: Int, timeTaken: TimeInterval) -> Bool {
        guard let problem = currentProblem else { return false }

        if answer == problem.correctAnswer {
            gameManager.recordTopicResult(topic: problem.topic, correct: true, time: timeTaken)
            delegate?.waveManagerCorrectAnswer()
            isBossActive = false

            isWaitingForNext = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.isWaitingForNext = false
                if self?.gameManager.isLevelComplete() == true {
                    return
                }
                self?.startNewProblem()
            }
            return true
        } else {
            attemptCount += 1
            gameManager.wrongAnswer()
            gameManager.recordTopicResult(topic: problem.topic, correct: false, time: timeTaken)
            delegate?.waveManagerWrongAnswer()
            return false
        }
    }

    func handleEnemyReachedBottom() {
        attemptCount += 1
        gameManager.wrongAnswer()
        delegate?.waveManagerEnemyReachedBottom()

        if attemptCount >= maxAttempts {
            isBossActive = false
            isWaitingForNext = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isWaitingForNext = false
                self?.startNewProblem()
            }
        }
    }

    func clearEnemies() {
        for enemy in answersOnScreen {
            enemy.removeFromParent()
        }
        answersOnScreen.removeAll()
    }
}
