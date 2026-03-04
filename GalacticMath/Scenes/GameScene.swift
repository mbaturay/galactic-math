import SpriteKit
import GameplayKit

final class GameScene: SKScene, WaveManagerDelegate {
    var selectedAgeGroup: AgeGroup = .cadet

    // Nodes
    private var starField: StarField!
    private var beamGrid: BeamGrid!
    private var playerShip: PlayerShip!
    private var hud: HUDNode!
    private var touchControls: TouchControlsNode!

    // Systems
    private var waveManager: WaveManager!
    private var gameManager = GameManager.shared
    private var audioManager = AudioManager.shared

    // State
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpeed: CGFloat = 100
    private var currentBeam: Int = 0
    private var problemStartTime: TimeInterval = 0
    private var isGameActive: Bool = false
    private var isPaused_: Bool = false
    private var pauseOverlay: SKNode?
    private var bossNode: SectorSentinel?

    private var activeLasers: [LaserBeam] = []
    private var activeTorpedoes: [Torpedo] = []

    // Enemy management
    private var enemies: [NumberEnemy] = []
    private var enemyStartY: CGFloat = 0
    private var enemyTargetY: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = selectedAgeGroup.backgroundColor

        currentBeam = selectedAgeGroup.beamCount / 2
        enemySpeed = AdaptiveDifficulty.shared.currentSpeed(for: selectedAgeGroup)

        setupStarField()
        setupBeamGrid()
        setupPlayerShip()
        setupHUD()
        setupTouchControls()

        // Start game
        isGameActive = true
        let topics = MathTopic.topics(for: selectedAgeGroup, level: gameManager.currentLevel)
        hud.updateLevel(gameManager.currentLevel, topic: topics.first?.displayName ?? "")

        waveManager = WaveManager(ageGroup: selectedAgeGroup)
        waveManager.delegate = self

        // Small delay before first problem
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.waveManager.startNewProblem()
            }
        ]))

        // Observe app lifecycle
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appWillResignActive() {
        showPauseOverlay()
    }

    @objc private func appDidBecomeActive() {
        // Pause overlay stays until tapped
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupStarField() {
        starField = StarField()
        starField.setup(size: size, ageGroup: selectedAgeGroup)
        addChild(starField)
    }

    private func setupBeamGrid() {
        beamGrid = BeamGrid()
        beamGrid.setup(size: size, ageGroup: selectedAgeGroup)
        addChild(beamGrid)
        enemyStartY = beamGrid.vanishingPoint.y - 20
        enemyTargetY = size.height * 0.10
    }

    private func setupPlayerShip() {
        playerShip = PlayerShip()
        playerShip.setup(ageGroup: selectedAgeGroup)
        let shipX = beamGrid.positionForBeam(currentBeam)
        playerShip.position = CGPoint(x: shipX, y: enemyTargetY)
        playerShip.zPosition = 20
        playerShip.currentBeam = currentBeam
        playerShip.setBeamAngle(beamGrid.beamAngle(at: currentBeam, y: enemyTargetY))
        addChild(playerShip)
    }

    private func setupHUD() {
        hud = HUDNode()
        let safeTop = view?.safeAreaInsets.top ?? 0
        hud.setup(size: size, ageGroup: selectedAgeGroup, safeAreaTop: safeTop)
        hud.onPauseTapped = { [weak self] in
            self?.showPauseOverlay()
        }
        addChild(hud)
    }

    private func setupTouchControls() {
        touchControls = TouchControlsNode()
        touchControls.setup(size: size, ageGroup: selectedAgeGroup)
        addChild(touchControls)

        touchControls.onBackTap = { [weak self] in
            self?.showPauseOverlay()
        }
        touchControls.onMoveLeft = { [weak self] in
            self?.movePlayerLeft()
        }
        touchControls.onMoveRight = { [weak self] in
            self?.movePlayerRight()
        }
        touchControls.onFire = { [weak self] in
            self?.fireLaser()
        }
        touchControls.onTorpedo = { [weak self] in
            self?.fireTorpedo()
        }
    }

    // MARK: - Player Movement

    private func movePlayerLeft() {
        guard isGameActive && !isPaused_ else { return }
        if currentBeam > 0 {
            currentBeam -= 1
            let x = beamGrid.positionForBeam(currentBeam)
            let angle = beamGrid.beamAngle(at: currentBeam, y: enemyTargetY)
            playerShip.moveToBeam(currentBeam, x: x, beamAngle: angle)
            beamGrid.setActiveBeam(currentBeam)
            hud.updateActiveBeam(currentBeam)
        }
    }

    private func movePlayerRight() {
        guard isGameActive && !isPaused_ else { return }
        if currentBeam < selectedAgeGroup.beamCount - 1 {
            currentBeam += 1
            let x = beamGrid.positionForBeam(currentBeam)
            let angle = beamGrid.beamAngle(at: currentBeam, y: enemyTargetY)
            playerShip.moveToBeam(currentBeam, x: x, beamAngle: angle)
            beamGrid.setActiveBeam(currentBeam)
            hud.updateActiveBeam(currentBeam)
        }
    }

    // MARK: - Shooting

    private func fireLaser() {
        guard isGameActive && !isPaused_ else { return }

        audioManager.playLaser()

        let laser = LaserBeam()
        laser.setup(ageGroup: selectedAgeGroup)
        laser.beamIndex = currentBeam
        laser.zPosition = 15
        laser.position = playerShip.position
        addChild(laser)

        laser.fire(from: playerShip.position, toY: enemyStartY, beamGrid: beamGrid, duration: 0.3)
        activeLasers.append(laser)

        // Check for hits after brief delay
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                self?.checkLaserHits()
            }
        ]))
    }

    private func fireTorpedo() {
        guard isGameActive && !isPaused_ else { return }
        guard bossNode != nil else { return }

        audioManager.playTorpedo()

        let torpedo = Torpedo()
        torpedo.setup(ageGroup: selectedAgeGroup)
        torpedo.beamIndex = currentBeam
        torpedo.zPosition = 15
        torpedo.position = playerShip.position
        addChild(torpedo)

        torpedo.fire(from: playerShip.position, toY: enemyStartY, beamGrid: beamGrid, duration: 0.4)
        activeTorpedoes.append(torpedo)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.run { [weak self] in
                self?.checkTorpedoHits()
            }
        ]))
    }

    // MARK: - Hit Detection

    private func checkLaserHits() {
        for enemy in enemies {
            if enemy.beamIndex == currentBeam && enemy.parent != nil {
                let timeTaken = CACurrentMediaTime() - problemStartTime
                let isCorrect = waveManager.handleAnswerHit(answer: enemy.answerValue, timeTaken: timeTaken)

                if isCorrect {
                    handleCorrectHit(enemy: enemy, timeTaken: timeTaken)
                } else {
                    handleWrongHit(enemy: enemy)
                }
                break
            }
        }
        activeLasers.removeAll { $0.parent == nil }
    }

    private func checkTorpedoHits() {
        guard bossNode != nil else { return }

        for enemy in enemies {
            if enemy.beamIndex == currentBeam && enemy.parent != nil && enemy.isCorrect {
                let timeTaken = CACurrentMediaTime() - problemStartTime
                let isCorrect = waveManager.handleAnswerHit(answer: enemy.answerValue, timeTaken: timeTaken)
                if isCorrect {
                    handleBossDestroyed()
                }
                break
            }
        }
        activeTorpedoes.removeAll { $0.parent == nil }
    }

    private func handleCorrectHit(enemy: NumberEnemy, timeTaken: TimeInterval) {
        audioManager.playCorrect()

        enemy.explodeCorrect { }
        let explosion = Explosion.correctExplosion(at: enemy.position, ageGroup: selectedAgeGroup)
        addChild(explosion)

        hud.flashScreenEdge(color: .green)
        hud.updateScore(gameManager.score)
        hud.updateStreak(gameManager.correctStreak)
        hud.updateLives(gameManager.lives)

        playerShip.victorySpin()

        // Streak effects
        if gameManager.correctStreak == 3 {
            audioManager.playCombo(3)
            hud.showMessage("NICE! 🔥🔥🔥", color: .orange)
        } else if gameManager.correctStreak == 5 {
            audioManager.playCombo(5)
            hud.showMessage("PERFECT! 🔥🔥🔥🔥🔥", color: .red)
        }

        // Star rating
        let stars: Int
        if timeTaken < 2.0 { stars = 3 }
        else if timeTaken < 4.0 { stars = 2 }
        else { stars = 1 }

        showStarRating(stars, at: enemy.position)

        // Confetti for correct
        let confetti = ConfettiNode()
        confetti.zPosition = 150
        addChild(confetti)
        confetti.burst(in: size)

        // Clear remaining enemies
        clearAllEnemies()

        // Adaptive difficulty message
        if let message = AdaptiveDifficulty.shared.encouragementMessage {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.hud.showMessage(message, color: .cyan)
                }
            ]))
        }

        // Check for level complete (skip if boss is active — boss defeat triggers it)
        if gameManager.isLevelComplete() && bossNode == nil {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in
                    self?.levelComplete()
                }
            ]))
        }
    }

    private func handleWrongHit(enemy: NumberEnemy) {
        audioManager.playWrong()

        enemy.explodeWrong()
        enemy.bounceBack()

        let wrongExplosion = Explosion.wrongExplosion(at: enemy.position, ageGroup: selectedAgeGroup)
        addChild(wrongExplosion)

        hud.flashScreenEdge(color: .red)
        hud.updateLives(gameManager.lives)
        hud.updateStreak(gameManager.correctStreak)

        playerShip.hitFlash()
        playerShip.showShield()

        if gameManager.isGameOver() {
            gameOver()
        }
    }

    // MARK: - Boss

    private func handleBossDestroyed() {
        guard let boss = bossNode else { return }

        audioManager.playBossDestroy()

        let explosion = Explosion.bossExplosion(at: boss.position)
        addChild(explosion)

        boss.destroy { }

        gameManager.score += 500
        hud.updateScore(gameManager.score)
        hud.showMessage("BOSS DESTROYED! +500", color: .yellow)

        let confetti = ConfettiNode()
        confetti.zPosition = 150
        addChild(confetti)
        confetti.burst(in: size)

        bossNode = nil
        clearAllEnemies()
        touchControls.switchToNormalMode()

        // Boss defeated completes the level
        if gameManager.isLevelComplete() {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    self?.levelComplete()
                }
            ]))
        }
    }

    private func handleBossEscaped() {
        guard let boss = bossNode else { return }
        boss.destroy { }
        bossNode = nil
        clearAllEnemies()
        touchControls.switchToNormalMode()
        hud.showMessage("Boss escaped!", color: .orange)
    }

    private func showStarRating(_ stars: Int, at position: CGPoint) {
        let rating = StarRatingNode()
        rating.setup(rating: stars, size: 20)
        rating.position = CGPoint(x: position.x, y: position.y + 50)
        rating.zPosition = 160
        addChild(rating)

        let floatUp = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        rating.run(SKAction.sequence([
            SKAction.group([floatUp, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - WaveManagerDelegate

    func waveManagerDidRequestNewProblem(_ problem: MathProblem) {
        // If boss was active but new normal problem started, boss escaped
        if bossNode != nil {
            handleBossEscaped()
        }

        problemStartTime = CACurrentMediaTime()
        let topicName = problem.topic.displayName
        hud.problemDisplay.showProblem(problem.question, topic: topicName)
        hud.problemDisplay.startPulse()

        let topics = MathTopic.topics(for: selectedAgeGroup, level: gameManager.currentLevel)
        hud.updateLevel(gameManager.currentLevel, topic: topics.first?.displayName ?? "")

        spawnEnemies(for: problem)
        enemySpeed = AdaptiveDifficulty.shared.currentSpeed(for: selectedAgeGroup)
    }

    func waveManagerCorrectAnswer() {
        hud.problemDisplay.stopPulse()
    }

    func waveManagerWrongAnswer() {
        if gameManager.isGameOver() {
            gameOver()
        }
    }

    func waveManagerEnemyReachedBottom() {
        hud.updateLives(gameManager.lives)
        playerShip.hitFlash()

        if gameManager.isGameOver() {
            gameOver()
        } else {
            // Respawn enemies for same problem
            if let problem = waveManager.currentProblem {
                clearAllEnemies()
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { [weak self] in
                        self?.spawnEnemies(for: problem)
                    }
                ]))
            }
        }
    }

    func waveManagerBossRound(_ problem: MathProblem) {
        audioManager.playBossAppear()

        // Dramatic entrance — flash screen edge red
        hud.flashScreenEdge(color: .red)

        // Screen shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 3, duration: 0.05),
            SKAction.moveBy(x: 10, y: -6, duration: 0.05),
            SKAction.moveBy(x: -10, y: 6, duration: 0.05),
            SKAction.moveBy(x: 5, y: -3, duration: 0.05)
        ])
        run(SKAction.repeat(shake, count: 3))

        hud.showMessage("⚠️ BOSS INCOMING! ⚠️", color: .red)

        // Switch button to TORPEDO
        touchControls.switchToBossMode()

        let boss = SectorSentinel()
        boss.setup(ageGroup: selectedAgeGroup, sceneSize: size)
        boss.zPosition = 25
        addChild(boss)
        bossNode = boss

        let bossPos = CGPoint(x: size.width / 2, y: size.height * 0.65)
        boss.appear(at: bossPos) { [weak self] in
            guard let self = self else { return }
            boss.showProblem(problem)
            self.problemStartTime = CACurrentMediaTime()
            self.hud.problemDisplay.showProblem(problem.question, topic: "BOSS ROUND")
            self.hud.problemDisplay.startPulse()
            self.spawnEnemies(for: problem)

            // Show torpedo instruction after boss appears
            self.hud.showMessage("USE TORPEDO TO DEFEAT THE BOSS!", color: .orange)
        }
    }

    // MARK: - Enemy Management

    private func spawnEnemies(for problem: MathProblem) {
        clearAllEnemies()

        let beamCount = selectedAgeGroup.beamCount
        let answers = problem.answers(for: beamCount)
        let colors = selectedAgeGroup.beamColors

        for i in 0..<beamCount {
            let isCorrect = answers[i] == problem.correctAnswer
            let color = colors[i % colors.count]

            let enemy = NumberEnemy(answer: answers[i], beam: i, isCorrect: isCorrect, ageGroup: selectedAgeGroup, beamColor: color)
            enemy.position = CGPoint(
                x: beamGrid.beamXAtY(i, y: enemyStartY),
                y: enemyStartY
            )
            enemy.setScale(0.3)
            enemy.zPosition = 10
            addChild(enemy)
            enemies.append(enemy)
            waveManager.answersOnScreen.append(enemy)
        }
    }

    private func clearAllEnemies() {
        for enemy in enemies {
            enemy.removeFromParent()
        }
        enemies.removeAll()
        waveManager.answersOnScreen.removeAll()
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime

        guard isGameActive && !isPaused_ else { return }

        starField.update(deltaTime: dt)
        beamGrid.update(deltaTime: dt)

        // Move enemies down
        updateEnemies(deltaTime: dt)
    }

    private func updateEnemies(deltaTime dt: TimeInterval) {
        for enemy in enemies {
            guard enemy.parent != nil else { continue }

            let movement = enemySpeed * CGFloat(dt)
            enemy.position.y -= movement

            // Update X position to follow beam perspective
            let newX = beamGrid.beamXAtY(enemy.beamIndex, y: enemy.position.y)
            enemy.position.x = newX

            // Scale based on Y position (perspective)
            let progress = 1.0 - (enemy.position.y - enemyTargetY) / (enemyStartY - enemyTargetY)
            let scale = 0.3 + progress * 0.7
            enemy.setScale(min(max(scale, 0.3), 1.0))

            // Check if reached bottom
            if enemy.position.y <= enemyTargetY {
                waveManager.handleEnemyReachedBottom()
                return
            }
        }
    }

    // MARK: - Navigation

    private func navigateBack() {
        isGameActive = false
        NotificationCenter.default.removeObserver(self)
        GameManager.shared.resetToMenu()
        let scene = TitleScene(size: self.size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    // MARK: - Game State

    private func levelComplete() {
        isGameActive = false
        audioManager.playLevelClear()

        let transition = SKTransition.crossFade(withDuration: 0.8)
        let levelClear = LevelClearScene(size: size)
        levelClear.scaleMode = .resizeFill
        levelClear.selectedAgeGroup = selectedAgeGroup
        view?.presentScene(levelClear, transition: transition)
    }

    private func gameOver() {
        isGameActive = false
        audioManager.playGameOver()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let transition = SKTransition.crossFade(withDuration: 0.8)
                let gameOverScene = GameOverScene(size: self.size)
                gameOverScene.scaleMode = .resizeFill
                gameOverScene.selectedAgeGroup = self.selectedAgeGroup
                self.view?.presentScene(gameOverScene, transition: transition)
            }
        ]))
    }

    // MARK: - Pause

    private var showingQuitConfirm = false

    private func showPauseOverlay() {
        guard pauseOverlay == nil else { return }
        isPaused_ = true
        showingQuitConfirm = false

        let overlay = SKNode()
        overlay.zPosition = 1000

        let bg = SKShapeNode(rectOf: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let label = SKLabelNode(text: "PAUSED")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 40
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        overlay.addChild(label)

        // Resume button
        let resumeBtn = createPauseButton(text: "Resume", color: SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0))
        resumeBtn.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resumeBtn.name = "pauseResume"
        overlay.addChild(resumeBtn)

        // Main Menu button
        let menuBtn = createPauseButton(text: "Main Menu", color: SKColor(white: 0.5, alpha: 1.0))
        menuBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 60)
        menuBtn.name = "pauseMenu"
        overlay.addChild(menuBtn)

        overlay.name = "pauseOverlay"
        addChild(overlay)
        pauseOverlay = overlay
    }

    private func showQuitConfirm() {
        guard let overlay = pauseOverlay else { return }
        showingQuitConfirm = true

        // Remove existing buttons
        overlay.children.filter { $0.name == "pauseResume" || $0.name == "pauseMenu" }
            .forEach { $0.removeFromParent() }
        overlay.children.filter { $0 is SKLabelNode }.forEach { $0.removeFromParent() }

        let msg = SKLabelNode(text: "Quit game?")
        msg.fontName = "AvenirNext-Bold"
        msg.fontSize = 28
        msg.fontColor = .white
        msg.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        overlay.addChild(msg)

        let sub = SKLabelNode(text: "Progress will be lost")
        sub.fontName = "AvenirNext-Medium"
        sub.fontSize = 16
        sub.fontColor = SKColor(white: 0.7, alpha: 1.0)
        sub.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        overlay.addChild(sub)

        let quitBtn = createPauseButton(text: "Quit", color: SKColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0))
        quitBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        quitBtn.name = "confirmQuit"
        overlay.addChild(quitBtn)

        let cancelBtn = createPauseButton(text: "Cancel", color: SKColor(white: 0.5, alpha: 1.0))
        cancelBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 90)
        cancelBtn.name = "cancelQuit"
        overlay.addChild(cancelBtn)
    }

    private func createPauseButton(text: String, color: SKColor) -> SKNode {
        let btn = SKNode()
        let btnSize = CGSize(width: min(size.width * 0.6, 200), height: 44)
        let bg = SKShapeNode(rectOf: btnSize, cornerRadius: 12)
        bg.fillColor = color.withAlphaComponent(0.3)
        bg.strokeColor = color.withAlphaComponent(0.8)
        bg.lineWidth = 2.0
        btn.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        btn.addChild(label)

        return btn
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if isPaused_, let overlay = pauseOverlay {
            // Handle pause menu taps
            for child in overlay.children {
                guard let name = child.name else { continue }
                let dist = hypot(location.x - child.position.x, location.y - child.position.y)
                if dist < 80 {
                    if name == "pauseResume" {
                        pauseOverlay?.removeFromParent()
                        pauseOverlay = nil
                        isPaused_ = false
                        showingQuitConfirm = false
                        return
                    }
                    if name == "pauseMenu" {
                        showQuitConfirm()
                        return
                    }
                    if name == "confirmQuit" {
                        pauseOverlay?.removeFromParent()
                        pauseOverlay = nil
                        isPaused_ = false
                        navigateBack()
                        return
                    }
                    if name == "cancelQuit" {
                        // Go back to pause menu
                        pauseOverlay?.removeFromParent()
                        pauseOverlay = nil
                        showingQuitConfirm = false
                        showPauseOverlay()
                        return
                    }
                }
            }
            return
        }

        if hud.handleTap(at: location) {
            return
        }
    }
}
