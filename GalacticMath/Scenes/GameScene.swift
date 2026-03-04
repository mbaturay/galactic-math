import SpriteKit
import GameplayKit

final class GameScene: SKScene, WaveManagerDelegate {
    var selectedAgeGroup: AgeGroup = .cadet

    // MARK: - Proximity Zone

    private enum ProximityZone {
        case top, upper, middle, bottom

        static func from(_ yPercent: CGFloat) -> ProximityZone {
            if yPercent > 0.75 { return .top }
            if yPercent > 0.50 { return .upper }
            if yPercent > 0.25 { return .middle }
            return .bottom
        }

        var label: String {
            switch self {
            case .top: return "INCREDIBLE"
            case .upper: return "AMAZING"
            case .middle: return "GOOD"
            case .bottom: return "CLOSE"
            }
        }

        var displayLabel: String {
            switch self {
            case .top: return "INCREDIBLE!"
            case .upper: return "AMAZING!"
            case .middle: return "GOOD!"
            case .bottom: return "CLOSE!"
            }
        }

        var color: SKColor {
            switch self {
            case .top: return SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
            case .upper: return SKColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 1.0)
            case .middle: return .white
            case .bottom: return SKColor(white: 0.6, alpha: 1.0)
            }
        }

        var explosionSizeFactor: CGFloat {
            switch self {
            case .top: return 1.5
            case .upper: return 1.2
            case .middle: return 1.0
            case .bottom: return 0.7
            }
        }
    }

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

    // Boss movement
    private var bossIsDescending: Bool = false
    private var bossSpawnTime: TimeInterval = 0

    // Enemy management
    private var enemies: [NumberEnemy] = []
    private var enemyStartY: CGFloat = 0
    private var enemyTargetY: CGFloat = 0

    // Background asteroids
    private var backgroundAsteroids: [BackgroundAsteroid] = []
    private let backgroundAsteroidCount = Int.random(in: 5...8)

    override func didMove(to view: SKView) {
        backgroundColor = selectedAgeGroup.backgroundColor

        currentBeam = selectedAgeGroup.beamCount / 2
        enemySpeed = AdaptiveDifficulty.shared.currentSpeed(for: selectedAgeGroup)

        setupStarField()
        spawnBackgroundAsteroids()
        setupBeamGrid()
        setupZoneIndicators()
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

    private func spawnBackgroundAsteroids() {
        for _ in 0..<backgroundAsteroidCount {
            let startY = CGFloat.random(in: 0...size.height)
            let asteroid = BackgroundAsteroid.spawn(in: size, startY: startY)
            addChild(asteroid)
            backgroundAsteroids.append(asteroid)
        }
    }

    private func setupBeamGrid() {
        beamGrid = BeamGrid()
        beamGrid.setup(size: size, ageGroup: selectedAgeGroup)
        addChild(beamGrid)
        enemyStartY = beamGrid.vanishingPoint.y - 20
        enemyTargetY = size.height * 0.10
    }

    private func setupZoneIndicators() {
        let totalTravel = enemyStartY - enemyTargetY

        // Silver line at 50% travel height
        let silverY = enemyTargetY + totalTravel * 0.50
        let silverLine = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
        silverLine.position = CGPoint(x: size.width / 2, y: silverY)
        silverLine.fillColor = SKColor(white: 0.8, alpha: 0.10)
        silverLine.strokeColor = .clear
        silverLine.zPosition = -4
        addChild(silverLine)

        // Gold line at 75% travel height
        let goldY = enemyTargetY + totalTravel * 0.75
        let goldLine = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
        goldLine.position = CGPoint(x: size.width / 2, y: goldY)
        goldLine.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.10)
        goldLine.strokeColor = .clear
        goldLine.zPosition = -4
        addChild(goldLine)
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

        // Highlight starting beam
        beamGrid.setActiveBeam(currentBeam)
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

        // Flash the active beam when laser fires
        beamGrid.flashBeam(currentBeam)

        let laser = LaserBeam()
        let beamColors = selectedAgeGroup.beamColors
        laser.setup(color: beamColors[currentBeam % beamColors.count])
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
        audioManager.playAsteroidShatter()

        // Proximity scoring
        let totalTravel = enemyStartY - enemyTargetY
        let yPercent: CGFloat = totalTravel > 0
            ? (enemy.position.y - enemyTargetY) / totalTravel
            : 0
        let clampedPercent = min(max(yPercent, 0), 1)
        let zone = ProximityZone.from(clampedPercent)

        let basePoints = 50 + Int(clampedPercent * 450)
        let streak = gameManager.correctStreak
        let streakMul: Double = (streak + 1 >= 5) ? 2.0 : (streak + 1 >= 3) ? 1.5 : 1.0
        let diffMul = gameManager.difficultyMultiplier
        let lvlMul = 1.0 + Double(gameManager.currentLevel) * 0.1
        let rawPoints = Double(basePoints) * streakMul * diffMul * lvlMul
        let finalPoints = Int((rawPoints / 10).rounded() * 10)

        gameManager.correctAnswer(timeTaken: timeTaken, points: finalPoints)
        gameManager.updateBestZone(zone.label)

        hud.flashScreenEdge(color: .green)
        hud.updateScore(gameManager.score)
        hud.updateStreak(gameManager.correctStreak)
        hud.updateLives(gameManager.lives)

        playerShip.victorySpin()

        // Streak audio
        let newStreak = gameManager.correctStreak
        if newStreak == 5 || newStreak == 10 {
            audioManager.playCombo(newStreak)
        } else if newStreak == 3 {
            audioManager.playCombo(3)
        }

        // Zone feedback
        showZoneFeedback(zone: zone, points: finalPoints, at: enemy.position)

        // Proximity tip — show once per profile on first BOTTOM zone hit
        var showedProximityTip = false
        if zone == .bottom, let idx = gameManager.currentSlotIndex,
           let profile = gameManager.slots[idx], !profile.hasSeenProximityTip {
            showedProximityTip = true
            gameManager.markProximityTipSeen()
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in
                    self?.hud.showMessage("Shoot earlier for MORE points!", color: SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0))
                }
            ]))
        }

        // Adaptive message (only when no proximity tip was shown)
        if !showedProximityTip,
           let msg = AdaptiveDifficulty.shared.messageAfterCorrectAnswer(
            timeTaken: timeTaken, streak: newStreak, isBossRound: bossNode != nil
        ) {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.hud.showMessage(msg.text, color: msg.color)
                }
            ]))
        }

        // Star rating
        let stars: Int
        if timeTaken < 2.0 { stars = 3 }
        else if timeTaken < 4.0 { stars = 2 }
        else { stars = 1 }

        showStarRating(stars, at: enemy.position)

        // Confetti
        let confetti = ConfettiNode()
        confetti.zPosition = 150
        addChild(confetti)
        confetti.burst(in: size)

        // Chain explosion: correct enemy first (sized by zone), then remaining L→R
        let beamColors = selectedAgeGroup.beamColors
        let correctColor = beamColors[enemy.beamIndex % beamColors.count]

        let correctPos = enemy.position
        enemy.shatterIntoChunks { }
        let chainExp = Explosion.chainExplosion(at: correctPos, color: correctColor, sizeFactor: zone.explosionSizeFactor) { }
        addChild(chainExp)

        // Remaining enemies sorted L→R by beamIndex
        let remaining = enemies.filter { $0 !== enemy && $0.parent != nil }
            .sorted { $0.beamIndex < $1.beamIndex }

        var delay: TimeInterval = 0.15
        for other in remaining {
            let d = delay
            let otherPos = other.position
            run(SKAction.sequence([
                SKAction.wait(forDuration: d),
                SKAction.run { [weak self, weak other] in
                    guard let self = self, let other = other, other.parent != nil else { return }
                    self.audioManager.playAsteroidChunk()
                    other.shatterIntoChunks { }
                    let smallExp = Explosion.chainExplosion(at: otherPos, color: SKColor(white: 0.6, alpha: 1.0)) { }
                    self.addChild(smallExp)
                }
            ]))
            delay += 0.15
        }

        // Cleanup after chain completes
        let totalDelay = delay + 0.5
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalDelay),
            SKAction.run { [weak self] in
                self?.clearAllEnemies()
            }
        ]))

        // Check for level complete (skip if boss is active — boss defeat triggers it)
        if gameManager.isLevelComplete() && bossNode == nil {
            run(SKAction.sequence([
                SKAction.wait(forDuration: max(totalDelay, 1.5)),
                SKAction.run { [weak self] in
                    self?.levelComplete()
                }
            ]))
        }
    }

    private func showZoneFeedback(zone: ProximityZone, points: Int, at position: CGPoint) {
        let isCadet = selectedAgeGroup == .cadet

        let zoneLabel = SKLabelNode(text: zone.displayLabel)
        zoneLabel.fontName = "AvenirNext-Heavy"
        zoneLabel.fontSize = isCadet ? 28 : 24
        zoneLabel.fontColor = zone.color
        zoneLabel.verticalAlignmentMode = .center
        zoneLabel.horizontalAlignmentMode = .center
        zoneLabel.position = CGPoint(x: position.x, y: position.y + 20)
        zoneLabel.zPosition = 160
        addChild(zoneLabel)

        let pointsLabel = SKLabelNode(text: "+\(points)")
        pointsLabel.fontName = "AvenirNext-Bold"
        pointsLabel.fontSize = isCadet ? 22 : 18
        pointsLabel.fontColor = zone.color
        pointsLabel.verticalAlignmentMode = .center
        pointsLabel.horizontalAlignmentMode = .center
        pointsLabel.position = CGPoint(x: position.x, y: position.y - 8)
        pointsLabel.zPosition = 160
        addChild(pointsLabel)

        let floatUp = SKAction.moveBy(x: 0, y: 50, duration: 1.2)
        let fadeOut = SKAction.fadeOut(withDuration: 1.2)
        let group = SKAction.group([floatUp, fadeOut])
        let remove = SKAction.removeFromParent()

        zoneLabel.run(SKAction.sequence([group, remove]))
        pointsLabel.run(SKAction.sequence([group.copy() as! SKAction, remove.copy() as! SKAction]))
    }

    private func handleWrongHit(enemy: NumberEnemy) {
        audioManager.playWrong()
        audioManager.playAsteroidCrack()

        enemy.showDamage()
        enemy.bounceBack()

        let wrongExplosion = Explosion.wrongExplosion(at: enemy.position, ageGroup: selectedAgeGroup)
        addChild(wrongExplosion)

        hud.flashScreenEdge(color: .red)
        hud.updateLives(gameManager.lives)
        hud.updateStreak(gameManager.correctStreak)

        playerShip.hitFlash()
        playerShip.showShield()

        // Encouragement after consecutive wrong answers
        if let msg = AdaptiveDifficulty.shared.messageAfterWrongAnswer(isBossRound: bossNode != nil) {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.hud.showMessage(msg.text, color: msg.color)
                }
            ]))
        }

        if gameManager.isGameOver() {
            gameOver()
        }
    }

    // MARK: - Boss

    private func handleBossDestroyed() {
        guard let boss = bossNode else { return }
        bossIsDescending = false
        waveManager.bossDefeatedThisLevel = true

        audioManager.playBossDestroy()

        // Massive shatter explosion
        let explosion = Explosion.bossExplosion(at: boss.position)
        addChild(explosion)

        boss.destroy { }

        // Score via correctAnswer so problemsThisLevel is incremented
        let timeTaken = CACurrentMediaTime() - problemStartTime
        gameManager.correctAnswer(timeTaken: timeTaken, points: 500)
        hud.updateScore(gameManager.score)
        hud.showMessage("BOSS DEFEATED!", color: .yellow)

        // Screen flash white
        hud.flashScreenEdge(color: .white)

        let confetti = ConfettiNode()
        confetti.zPosition = 150
        addChild(confetti)
        confetti.burst(in: size)

        bossNode = nil
        clearAllEnemies()
        touchControls.switchToNormalMode()

        // Dramatic slow motion for 0.5s
        self.speed = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.speed = 1.0
        }

        // Boss defeated always completes the level
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.levelComplete()
            }
        ]))
    }

    private func handleBossEscaped() {
        guard let boss = bossNode else { return }
        bossIsDescending = false
        waveManager.bossDefeatedThisLevel = true
        boss.destroy { }
        bossNode = nil
        clearAllEnemies()
        touchControls.switchToNormalMode()
        hud.showMessage("Boss escaped!", color: .orange)

        // Boss escaped completes the level
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                self?.levelComplete()
            }
        ]))
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
        audioManager.playAsteroidImpact()

        // Screen shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 4, duration: 0.05),
            SKAction.moveBy(x: 16, y: -8, duration: 0.05),
            SKAction.moveBy(x: -16, y: 8, duration: 0.05),
            SKAction.moveBy(x: 8, y: -4, duration: 0.05)
        ])
        run(SKAction.repeat(shake, count: 2))

        // Bottom impact flash
        let impact = Explosion.bottomImpactFlash(across: size)
        addChild(impact)

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

        hud.showMessage("BOSS INCOMING!", color: .red)

        // Switch button to TORPEDO
        touchControls.switchToBossMode()

        let boss = SectorSentinel()
        boss.setup(ageGroup: selectedAgeGroup, sceneSize: size)
        boss.zPosition = 25
        addChild(boss)
        bossNode = boss

        // Boss spawns at top and descends toward player
        let bossStartPos = CGPoint(x: size.width / 2, y: enemyStartY + 30)
        boss.appear(at: bossStartPos) { [weak self] in
            guard let self = self else { return }
            boss.showProblem(problem)
            self.problemStartTime = CACurrentMediaTime()
            self.bossSpawnTime = CACurrentMediaTime()
            self.bossIsDescending = true
            self.hud.problemDisplay.showProblem(problem.question, topic: "BOSS ROUND")
            self.hud.problemDisplay.startPulse()
            self.spawnEnemies(for: problem)

            self.hud.showMessage("FIRE TORPEDO AT CORRECT ANSWER!", color: .orange)
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
            enemy.setScale(0.5)
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

        // Background asteroids — remove off-screen, respawn
        backgroundAsteroids.removeAll { asteroid in
            if asteroid.isOffScreen {
                asteroid.removeFromParent()
                return true
            }
            return false
        }
        while backgroundAsteroids.count < backgroundAsteroidCount {
            let asteroid = BackgroundAsteroid.spawn(in: size)
            addChild(asteroid)
            backgroundAsteroids.append(asteroid)
        }

        // Move enemies down
        updateEnemies(deltaTime: dt)

        // Move boss down (if descending)
        updateBoss(deltaTime: dt)
    }

    private func updateEnemies(deltaTime dt: TimeInterval) {
        for enemy in enemies {
            guard enemy.parent != nil else { continue }

            let movement = enemySpeed * CGFloat(dt)
            enemy.position.y -= movement

            // Update X position to follow beam perspective
            let newX = beamGrid.beamXAtY(enemy.beamIndex, y: enemy.position.y)
            enemy.position.x = newX

            // Perspective scaling with acceleration in bottom half
            let progress = 1.0 - (enemy.position.y - enemyTargetY) / (enemyStartY - enemyTargetY)
            let p = min(max(progress, 0), 1)
            // Quadratic ease-in: slow at top, fast rush at bottom
            let eased = p * p
            // Scale from 0.5 → 1.0 (asteroid perspective)
            let scale = 0.5 + eased * 0.5
            enemy.setScale(min(scale, 1.0))

            // Check if reached bottom
            if enemy.position.y <= enemyTargetY {
                waveManager.handleEnemyReachedBottom()
                return
            }
        }
    }

    private func updateBoss(deltaTime dt: TimeInterval) {
        guard let boss = bossNode, bossIsDescending else { return }

        // Boss moves slightly faster than normal asteroids
        let bossSpeed = enemySpeed * 1.2
        boss.position.y -= bossSpeed * CGFloat(dt)

        // Sinusoidal weave
        let elapsed = CACurrentMediaTime() - bossSpawnTime
        let waveAmplitude: CGFloat = size.width * 0.15
        boss.position.x = size.width / 2 + sin(CGFloat(elapsed) * 2.0) * waveAmplitude

        // Scale up dramatically as it descends (0.8 → 2.5)
        let totalTravel = enemyStartY + 30 - enemyTargetY
        let progress = totalTravel > 0
            ? 1.0 - (boss.position.y - enemyTargetY) / totalTravel
            : 0
        let p = min(max(progress, 0), 1)
        let bossScale = 0.8 + p * 1.7
        boss.setScale(bossScale)

        // Boss reached player = instant game over
        if boss.position.y <= enemyTargetY {
            handleBossReachedBottom()
        }
    }

    private func handleBossReachedBottom() {
        guard let boss = bossNode else { return }
        bossIsDescending = false
        waveManager.bossDefeatedThisLevel = true

        // Massive explosion
        let explosion = Explosion.bossExplosion(at: boss.position)
        addChild(explosion)

        boss.removeFromParent()
        bossNode = nil
        clearAllEnemies()
        touchControls.switchToNormalMode()

        // Full red flash
        hud.flashScreenEdge(color: .red)

        // Screen shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -12, y: 6, duration: 0.05),
            SKAction.moveBy(x: 24, y: -12, duration: 0.05),
            SKAction.moveBy(x: -24, y: 12, duration: 0.05),
            SKAction.moveBy(x: 12, y: -6, duration: 0.05)
        ])
        run(SKAction.repeat(shake, count: 4))

        // Instant game over — boss destroyed the player
        bossGameOver()
    }

    private func bossGameOver() {
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
                gameOverScene.bossDestroyedPlayer = true
                self.view?.presentScene(gameOverScene, transition: transition)
            }
        ]))
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

    private func showPauseOverlay() {
        guard pauseOverlay == nil else { return }
        isPaused_ = true

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
            // Find the CLOSEST named button (prevents 80pt overlap between adjacent buttons)
            var closestName: String?
            var closestDist: CGFloat = .greatestFiniteMagnitude
            for child in overlay.children {
                guard let name = child.name else { continue }
                let dist = hypot(location.x - child.position.x, location.y - child.position.y)
                if dist < 80 && dist < closestDist {
                    closestDist = dist
                    closestName = name
                }
            }

            if let name = closestName {
                if name == "pauseResume" {
                    pauseOverlay?.removeFromParent()
                    pauseOverlay = nil
                    isPaused_ = false
                    return
                }
                if name == "pauseMenu" {
                    pauseOverlay?.removeFromParent()
                    pauseOverlay = nil
                    isPaused_ = false
                    navigateBack()
                    return
                }
            }
            return
        }

        if hud.handleTap(at: location) {
            return
        }
    }
}
