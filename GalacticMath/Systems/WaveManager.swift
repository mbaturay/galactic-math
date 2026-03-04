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

    private let ageGroup: AgeGroup
    private let gameManager = GameManager.shared
    private let mathEngine = MathEngine.shared

    init(ageGroup: AgeGroup) {
        self.ageGroup = ageGroup
    }

    func startNewProblem() {
        guard !isWaitingForNext else { return }
        attemptCount = 0

        if gameManager.isBossRound() && !isBossActive {
            let problem = mathEngine.generateBossProblem(ageGroup: ageGroup, level: gameManager.currentLevel)
            currentProblem = problem
            isBossActive = true
            delegate?.waveManagerBossRound(problem)
            return
        }

        let problem = mathEngine.generateProblem(ageGroup: ageGroup, level: gameManager.currentLevel)
        currentProblem = problem
        delegate?.waveManagerDidRequestNewProblem(problem)
    }

    func handleAnswerHit(answer: Int, timeTaken: TimeInterval) -> Bool {
        guard let problem = currentProblem else { return false }

        if answer == problem.correctAnswer {
            gameManager.correctAnswer(timeTaken: timeTaken)
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
