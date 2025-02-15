import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    private(set) var player: Player?
    private var gameState: GameState = .ready
    private var level: Int = 1
    private var score: Int = 0
    
    private var isTouching: Bool = false
    private var touchLocation: CGPoint = CGPoint.zero
    
    private let explosionRadius: CGFloat = 60.0
    private let largeAsteroidSize: CGFloat = 40.0
    private let mediumAsteroidSize: CGFloat = 25.0
    private let smallAsteroidSize: CGFloat = 15.0
    
    private var asteroidsSpawned: Int = 0
    private var asteroidsDestroyed: Int = 0
    private var scoreLabel: SKLabelNode?
    
    private let controlAreaHeight: CGFloat = 100.0  // Height of bottom control area
    private let rotationRange: CGFloat = .pi * 2    // Full 360 degrees
    private var isThrusting: Bool = false
    private var initialTouchX: CGFloat = 0
    private var initialTouchY: CGFloat = 0
    private let thrustPower: CGFloat = 20.0  // Reduced from 50.0 for more gradual acceleration
    
    private var lastTouchX: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var currentRotation: CGFloat = 0
    private var rotationSensitivity: CGFloat = 0.01
    
    private var levelLabel: SKLabelNode?
    private var currentLevel: Int = 1
    private var asteroidsNeededForNextLevel: Int {
        return GameConstants.startingAsteroids + 
               ((currentLevel - 1) * GameConstants.asteroidsPerLevel)
    }
    private var asteroidsDestroyedThisLevel: Int = 0
    
    private var currentAsteroids: Int = 0
    private var spawnInterval: TimeInterval = 2.0
    
    private var gameTimer: TimeInterval = 0
    private var lastSpawnIncrease: TimeInterval = 0
    private let spawnIncreaseInterval: TimeInterval = 10.0 // Every 10 seconds
    
    // Add lives property
    private var lives: Int = 3
    private var livesLabel: SKLabelNode?
    
    // Update UI constants
    private struct UI {
        static let titleFontSize: CGFloat = 14  // Smaller font for titles
        static let valueFontSize: CGFloat = 20  // Larger font for values
        static let spacing: CGFloat = 20
        
        struct Position {
            // Top row
            static let topRow: CGFloat = 0.90  // Changed from 0.95 to move down
            static let valueRow: CGFloat = 0.87 // Changed from 0.92 to move down
            
            // Horizontal positions (evenly spaced)
            static let positions: [CGFloat] = [
                0.15,   // Lives
                0.30,   // Level
                0.45,   // Time
                0.60,   // Active
                0.75,   // Score
                0.90    // Bullets
            ]
        }
    }
    
    // Update score label to split stats into separate labels
    private var timeLabel: SKLabelNode?
    private var activeLabel: SKLabelNode?
    private var destroyedLabel: SKLabelNode?
    
    // Add title labels
    private var livesTitleLabel: SKLabelNode?
    private var levelTitleLabel: SKLabelNode?
    private var timerTitleLabel: SKLabelNode?
    private var hitsTitleLabel: SKLabelNode?
    
    // Add value labels
    private var livesValueLabel: SKLabelNode?
    private var levelValueLabel: SKLabelNode?
    private var timerValueLabel: SKLabelNode?
    private var hitsValueLabel: SKLabelNode?
    
    // Add new label properties
    private var activeTitleLabel: SKLabelNode?
    private var activeValueLabel: SKLabelNode?
    
    // Update the asteroid size constants to ensure valid ranges
    private struct AsteroidSizes {
        static let minimum: CGFloat = 10.0
        static let small: CGFloat = max(15.0, minimum + 5.0)
        static let medium: CGFloat = max(25.0, small + 5.0)
        static let large: CGFloat = max(40.0, medium + 5.0)
        
        static func randomRadius(for size: CGFloat, variation: CGFloat = 0.2) -> CGFloat {
            // Ensure minimum size is respected
            let baseSize = max(size, minimum)
            // Calculate range with safety checks
            let minVariation = max(minimum, baseSize * (1.0 - variation))
            let maxVariation = max(minVariation + 1.0, baseSize * (1.0 + variation))
            return CGFloat.random(in: minVariation...maxVariation)
        }
    }
    
    // Update these properties at the top of GameScene class
    private struct GameConstants {
        static let startingAsteroids: Int = 20     // Level 1 starts with 20
        static let asteroidsPerLevel: Int = 5      // Add 5 more each level
        static let baseSpeed: CGFloat = 50.0       // Reduced from 150.0
        static let speedIncrease: CGFloat = 10.0   // Reduced from 25.0
    }
    
    // Calculate total asteroids needed for current level
    private var totalAsteroidsForLevel: Int {
        return GameConstants.startingAsteroids + 
               ((currentLevel - 1) * GameConstants.asteroidsPerLevel)
    }
    
    // Calculate asteroid speed for current level
    private var asteroidSpeedForLevel: CGFloat {
        return GameConstants.baseSpeed + 
               (CGFloat(currentLevel - 1) * GameConstants.speedIncrease)
    }
    
    // Add properties for high score entry
    private var nameEntryField: UITextField?
    private var isEnteringName: Bool = false
    
    // Add overlay background property
    private var gameOverOverlay: SKShapeNode?
    
    // Add property for force field
    private var forceField: SKShapeNode?
    private var isForceFieldActive = false
    
    // Add new properties at the top with other properties
    private var isSpinAttackActive = false
    private var spinAttackTimer: Timer?
    
    // Add these properties at the top with other properties
    private var touchStartTime: TimeInterval = 0
    private var isRapidFiring = false
    private var rapidFireTimer: Timer?
    private let rapidFireDelay: TimeInterval = 2.0  // Time to hold before rapid fire starts
    private let rapidFireInterval: TimeInterval = 0.1  // Time between rapid fire shots
    
    // Update properties at the top
    private var lastTapTime: TimeInterval = 0
    private var doubleTapTimeWindow: TimeInterval = 0.3  // Time window for double tap detection
    private let rapidFireFastInterval: TimeInterval = 0.05  // Faster interval for double-tap rapid fire
    
    // Add these properties at the top
    private let bulletsPerLevel: Int = 200
    private var remainingBullets: Int = 200
    private var bulletsTitleLabel: SKLabelNode?
    private var bulletsValueLabel: SKLabelNode?
    
    // MARK: - Lifecycle
    override init(size: CGSize) {
        super.init(size: size)
        print("GameScene: Initialized with size \(size)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        print("GameScene: didMove called")
        print("Scene size: \(size)")
        print("Scene frame: \(frame)")
        
        // Set up physics world first
        setupPhysicsWorld()
        
        backgroundColor = .black
        gameState = .playing
        setupGame()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        gameTimer += 1.0 / 60.0
        
        // Add this line to constantly check and wrap player position
        wrapPlayerPosition()
        // Add this line to wrap asteroids
        wrapAsteroids()
        
        // Periodically verify asteroid count
        if Int(gameTimer) % 5 == 0 {
            verifyAsteroidCount()
        }
        
        updateHUD()
    }
    
    // MARK: - Game Setup
    private func setupGame() {
        print("Setting up game...")
        setupPhysicsWorld()
        setupPlayer()
        currentLevel = 1
        lives = 3
        asteroidsDestroyed = 0
        currentAsteroids = 0
        setupHUD()
        
        print("Starting level 1 with initial asteroid spawn...")
        startLevel()
    }
    
    // Update setupPhysicsWorld for tighter boundaries
    private func setupPhysicsWorld() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // Create boundary with padding to keep ship visible
        let padding: CGFloat = 20
        let boundaryFrame = CGRect(
            x: -padding,
            y: -padding,
            width: size.width + (padding * 2),
            height: size.height + (padding * 2)
        )
        
        let boundary = SKPhysicsBody(edgeLoopFrom: boundaryFrame)
        boundary.friction = 0
        boundary.restitution = 1.0
        boundary.categoryBitMask = PhysicsCategory.boundary
        boundary.collisionBitMask = PhysicsCategory.player | PhysicsCategory.asteroid
        self.physicsBody = boundary
    }
    
    private func setupPlayer() {
        print("GameScene: Setting up player") // Debug print
        player = Player()
        if let player = player {
            player.position = CGPoint(x: frame.midX, y: frame.midY)
            print("GameScene: Player position set to \(player.position)") // Debug print
            addChild(player)
        }
    }
    
    // Update startLevel for gradual spawning
    private func startLevel() {
        print("\n=== Starting Level \(currentLevel) ===")
        
        // Clear any existing asteroids first
        enumerateChildNodes(withName: "asteroid") { node, _ in
            node.removeFromParent()
        }
        currentAsteroids = 0
        
        let asteroidCount = GameConstants.startingAsteroids + ((currentLevel - 1) * GameConstants.asteroidsPerLevel)
        print("Planning to spawn \(asteroidCount) asteroids")
        
        // Spawn new asteroids gradually
        for i in 0..<asteroidCount {
            let delay = TimeInterval(i) * 0.3
            run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    self?.spawnSingleAsteroid()
                    print("Spawned asteroid \(i + 1) of \(asteroidCount)")
                    self?.verifyAsteroidCount()
                }
            ]))
        }
        
        // Reset bullets for new level
        remainingBullets = bulletsPerLevel
        updateHUD()
    }
    
    // Move this function outside of spawnSingleAsteroid
    private func createIrregularAsteroidPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let segments = 10  // More segments for more irregularity
        var points: [CGPoint] = []
        
        // Generate random points around a circle
        for i in 0..<segments {
            let angle = (CGFloat(i) * 2.0 * .pi) / CGFloat(segments)
            let randomRadius = radius * CGFloat.random(in: 0.7...1.3) // More variation
            let point = CGPoint(
                x: cos(angle) * randomRadius,
                y: sin(angle) * randomRadius
            )
            points.append(point)
        }
        
        // Create the path
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.closeSubpath()
        return path
    }
    
    // Update spawnSingleAsteroid to handle radius in collision
    private func spawnSingleAsteroid() {
        let radius: CGFloat = CGFloat.random(in: 15...30)
        
        // Create visible asteroid
        let asteroid = SKShapeNode(path: createIrregularAsteroidPath(radius: radius))
        asteroid.strokeColor = .white
        asteroid.fillColor = .clear
        asteroid.lineWidth = 2
        asteroid.name = "asteroid"
        
        // Position asteroid outside screen
        let side = Int.random(in: 0...3)
        let position: CGPoint
        let direction: CGPoint
        
        switch side {
        case 0:  // Top
            position = CGPoint(
                x: CGFloat.random(in: radius...(size.width - radius)),
                y: size.height + radius
            )
            direction = CGPoint(x: 0, y: -1)
            
        case 1:  // Right
            position = CGPoint(
                x: size.width + radius,
                y: CGFloat.random(in: radius...(size.height - radius))
            )
            direction = CGPoint(x: -1, y: 0)
            
        case 2:  // Bottom
            position = CGPoint(
                x: CGFloat.random(in: radius...(size.width - radius)),
                y: -radius
            )
            direction = CGPoint(x: 0, y: 1)
            
        default:  // Left
            position = CGPoint(
                x: -radius,
                y: CGFloat.random(in: radius...(size.height - radius))
            )
            direction = CGPoint(x: 1, y: 0)
        }
        
        asteroid.position = position
        
        // Create physics body that accounts for the asteroid's size
        let physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody.categoryBitMask = PhysicsCategory.asteroid
        physicsBody.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
        physicsBody.collisionBitMask = PhysicsCategory.boundary | PhysicsCategory.asteroid
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.restitution = 1.0
        physicsBody.friction = 0
        physicsBody.linearDamping = 0
        
        asteroid.physicsBody = physicsBody
        addChild(asteroid)
        
        let speed: CGFloat = 50 + (CGFloat(currentLevel - 1) * 10)
        let velocity = CGVector(
            dx: direction.x * speed,
            dy: direction.y * speed
        )
        
        asteroid.physicsBody?.velocity = velocity
        currentAsteroids += 1
    }
    
    // Add touch handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let allTouches = event?.allTouches ?? Set<UITouch>()
        let currentTime = Date().timeIntervalSince1970
        
        // Check for three-finger touch during gameplay first
        if gameState == GameState.playing && allTouches.count >= 3 && !isSpinAttackActive {
            activateSpinAttack()
            return
        }
        
        // Check for two-finger force field
        if gameState == GameState.playing && allTouches.count >= 2 && !isForceFieldActive {
            activateForceField()
            return
        }
        
        // Single touch handling
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        self.touchLocation = touchLocation
        
        if gameState == GameState.playing && allTouches.count == 1 {
            isTouching = true
            
            // Check for double tap
            if currentTime - lastTapTime <= doubleTapTimeWindow {
                // Double tap detected - start rapid fire immediately
                startRapidFire(fast: true)
            } else {
                // Single tap - normal shot and check for hold
                shoot()
                touchStartTime = currentTime
                
                // Start timer to check for hold rapid fire
                DispatchQueue.main.asyncAfter(deadline: .now() + rapidFireDelay) { [weak self] in
                    guard let self = self,
                          self.isTouching,
                          !self.isRapidFiring,  // Don't start if already rapid firing
                          Date().timeIntervalSince1970 - self.touchStartTime >= self.rapidFireDelay else {
                        return
                    }
                    
                    self.startRapidFire(fast: false)
                }
            }
            
            lastTapTime = currentTime
        } else if gameState == GameState.gameOver && !isEnteringName {
            // Check if tap is on "TAP TO RESTART" text
            if let container = children.first(where: { $0.zPosition == 101 }),
               let restartLabel = container.childNode(withName: "restartLabel") as? SKLabelNode {
                let containerLocation = container.convert(touchLocation, from: self)
                
                let hitArea = CGRect(
                    x: restartLabel.frame.minX - 20,
                    y: restartLabel.frame.minY - 10,
                    width: restartLabel.frame.width + 40,
                    height: restartLabel.frame.height + 20
                )
                
                if hitArea.contains(containerLocation) {
                    restartLabel.run(SKAction.sequence([
                        SKAction.scale(to: 1.2, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1),
                        SKAction.run { [weak self] in
                            self?.restartGame()
                        }
                    ]))
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              isTouching,
              let player = player else { return }
        
        let newLocation = touch.location(in: self)
        let previousLocation = touchLocation
        
        // Only handle rotation - remove all thrust code
        let deltaX = newLocation.x - previousLocation.x
        player.zRotation += deltaX * -0.01  // Smooth rotation
        
        touchLocation = newLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        stopRapidFire()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        stopRapidFire()
    }
    
    private func wrapPlayerPosition() {
        guard let player = player else { return }
        
        // Wrap horizontally with padding
        if player.position.x < -20 {
            player.position.x = frame.width + 20
        } else if player.position.x > frame.width + 20 {
            player.position.x = -20
        }
        
        // Wrap vertically with padding
        if player.position.y < -20 {
            player.position.y = frame.height + 20
        } else if player.position.y > frame.height + 20 {
            player.position.y = -20
        }
    }
    
    // Update the shoot function to fire in the direction the player is facing
    private func shoot() {
        guard let player = player else { return }
        
        // Check if we have bullets remaining
        if remainingBullets <= 0 {
            outOfBullets()
            return
        }
        
        // Decrease bullet count
        remainingBullets -= 1
        updateHUD()
        
        let bullet = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 4))
        bullet.position = player.getNosePosition()  // Use the nose position
        bullet.zRotation = player.zRotation
        bullet.name = "bullet"
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 2)
        physicsBody.categoryBitMask = PhysicsCategory.bullet
        physicsBody.contactTestBitMask = PhysicsCategory.asteroid
        physicsBody.collisionBitMask = PhysicsCategory.none
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        bullet.physicsBody = physicsBody
        
        // Ensure consistent bullet speed across levels
        let bulletSpeed: CGFloat = 400  // Remove level-based speed increase for bullets
        
        let angle = player.zRotation + CGFloat.pi/2  // Match the nose position angle
        let vector = CGVector(
            dx: cos(angle) * bulletSpeed,
            dy: sin(angle) * bulletSpeed
        )
        
        addChild(bullet)
        bullet.physicsBody?.velocity = vector
        
        // Remove bullet after 1.5 seconds
        bullet.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ]))
    }
    
    private func createExplosion(at position: CGPoint, radius: CGFloat) {
        let particleCount = 12
        let duration: TimeInterval = 0.5
        
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = .white
            particle.strokeColor = .white
            particle.position = position
            
            let angle = CGFloat.random(in: 0...2 * .pi)
            let distance = radius * CGFloat.random(in: 0.5...1.0)
            let endPosition = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )
            
            addChild(particle)
            
            let fadeOut = SKAction.fadeOut(withDuration: duration)
            let moveAction = SKAction.move(to: endPosition, duration: duration)
            let group = SKAction.group([fadeOut, moveAction])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            
            particle.run(sequence)
        }
    }
    
    private func spawnAsteroids(count: Int) {
        guard count > 0 else { return }
        
        // Spawn the exact number needed for the level
        for _ in 0..<count {
            spawnSingleAsteroid()
        }
    }
    
    // Add collision detection
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.player | PhysicsCategory.asteroid {
            if lives > 0 {
                lives -= 1
                updateHUD()
                
                if lives <= 0 {
                    // Game over
                    createExplosion(at: player?.position ?? CGPoint.zero, radius: explosionRadius)
                    player?.removeFromParent()
                    gameOver()
                } else {
                    // Reset player position and give temporary invulnerability
                    if let player = player {
                        createExplosion(at: player.position, radius: explosionRadius)
                        player.position = CGPoint(x: frame.midX, y: frame.midY)
                        player.physicsBody?.velocity = CGVector.zero
                        player.zRotation = 0
                        
                        // Make player temporarily invulnerable
                        player.physicsBody?.categoryBitMask = 0
                        let blinkCount = 6
                        let blinkDuration = 0.2
                        let blink = SKAction.sequence([
                            SKAction.fadeOut(withDuration: blinkDuration/2),
                            SKAction.fadeIn(withDuration: blinkDuration/2)
                        ])
                        let blinkAction = SKAction.repeat(blink, count: blinkCount)
                        
                        // Run the blink action and restore collision after completion
                        player.run(blinkAction) {
                            player.physicsBody?.categoryBitMask = PhysicsCategory.player
                        }
                    }
                }
            }
        } else if collision == PhysicsCategory.bullet | PhysicsCategory.asteroid {
            if let bullet = contact.bodyA.node?.name == "bullet" ? contact.bodyA.node : contact.bodyB.node,
               let asteroid = contact.bodyA.node?.name == "asteroid" ? contact.bodyA.node : contact.bodyB.node {
                
                handleAsteroidDestruction(asteroid: asteroid, bullet: bullet)
            }
        }
    }
    
    private func updateScoreLabel() {
        // This can be removed if you're not using it anymore
    }
    
    // Add game over handling
    private func gameOver() {
        gameState = .gameOver
        
        // Create full screen dark overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor.black.withAlphaComponent(0.95)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 100
        addChild(overlay)
        gameOverOverlay = overlay
        
        // Create main container for all content
        let contentNode = SKNode()
        contentNode.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        contentNode.zPosition = 101
        addChild(contentNode)
        
        // Game Over text with hidden triple tap functionality
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 60
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: 250)
        gameOverLabel.name = "gameOverLabel"
        contentNode.addChild(gameOverLabel)
        
        // Add triple tap gesture recognizer
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap(_:)))
        tripleTap.numberOfTapsRequired = 3
        view?.addGestureRecognizer(tripleTap)
        
        if HighScoreManager.shared.isHighScore(asteroidsDestroyed) {
            showHighScoreEntry(in: contentNode)
        } else {
            showFinalScore(in: contentNode)
        }
    }
    
    @objc private func handleTripleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let sceneLocation = convertPoint(fromView: location)
        
        // Convert tap location to the container's coordinate space
        if let container = children.first(where: { $0.zPosition == 101 }),
           let gameOverLabel = container.childNode(withName: "gameOverLabel") as? SKLabelNode {
            // Convert the point to the container's coordinate space
            let containerLocation = container.convert(sceneLocation, from: self)
            
            // Check if tap is on "GAME OVER" text frame
            if gameOverLabel.frame.contains(containerLocation) {
                print("Triple tap detected on GAME OVER text")
                // Clear high scores
                HighScoreManager.shared.clearScores()
                
                // Remove only the score labels
                container.enumerateChildNodes(withName: "highScore") { node, _ in
                    node.removeFromParent()
                }
                
                // Add empty high scores list
                let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
                titleLabel.text = "HIGH SCORES"
                titleLabel.name = "highScore"
                titleLabel.fontSize = 40
                titleLabel.fontColor = .white
                titleLabel.position = CGPoint(x: 0, y: 60)
                container.addChild(titleLabel)
                
                // Add visual feedback
                gameOverLabel.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
            }
        }
    }
    
    // Helper function to refresh high scores display
    private func refreshHighScores(in container: SKNode) {
        // Remove existing high scores
        enumerateChildNodes(withName: "highScore") { node, _ in
            node.removeFromParent()
        }
        // Show updated (empty) high scores
        showHighScores(in: container, startingY: -40)
    }
    
    private func showHighScoreEntry(in container: SKNode) {
        // Game Over text at top
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 60
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: 250)
        gameOverLabel.name = "gameOverLabel"
        container.addChild(gameOverLabel)
        
        // Name entry prompt right below game over
        let promptLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        promptLabel.text = "ENTER YOUR NAME"
        promptLabel.fontSize = 30
        promptLabel.fontColor = .white
        promptLabel.position = CGPoint(x: 0, y: 200)
        promptLabel.name = "namePrompt"
        container.addChild(promptLabel)
        
        // Create text field directly below the prompt
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let textField = UITextField(frame: CGRect(
                x: self.frame.midX - 100,
                y: self.frame.midY - 220,  // Moved higher to be just below prompt
                width: 200,
                height: 40
            ))
            textField.backgroundColor = .white
            textField.textColor = .black
            textField.textAlignment = .center
            textField.font = UIFont(name: "AvenirNext-DemiBold", size: 20)
            textField.placeholder = "TAP HERE"
            textField.delegate = self
            textField.returnKeyType = .done
            textField.layer.cornerRadius = 6
            textField.layer.borderWidth = 2
            textField.layer.borderColor = UIColor.white.cgColor
            
            self.view?.addSubview(textField)
            textField.becomeFirstResponder()
            self.nameEntryField = textField
            self.isEnteringName = true
        }
        
        // Show high scores below
        showHighScores(in: container, startingY: 60)
    }
    
    private func showFinalScore(in container: SKNode) {
        let finalScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScoreLabel.text = "FINAL SCORE"
        finalScoreLabel.fontSize = 40
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: 0, y: 120)
        container.addChild(finalScoreLabel)
        
        let scoreValueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreValueLabel.text = "\(asteroidsDestroyed)"
        scoreValueLabel.fontSize = 80
        scoreValueLabel.fontColor = .white
        scoreValueLabel.position = CGPoint(x: 0, y: 40)
        container.addChild(scoreValueLabel)
        
        // Show high scores
        showHighScores(in: container, startingY: -40)
        
        // Add tap to restart at bottom
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        restartLabel.text = "TAP TO RESTART"
        restartLabel.fontSize = 30
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -350)  // Moved to bottom
        restartLabel.name = "restartLabel"
        container.addChild(restartLabel)
    }
    
    private func showHighScores(in container: SKNode, startingY: CGFloat) {
        let scores = HighScoreManager.shared.highScores.prefix(5)
        
        // High Scores header
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "HIGH SCORES"
        titleLabel.name = "highScore"
        titleLabel.fontSize = 40
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: startingY)
        container.addChild(titleLabel)
        
        // Score list
        for (index, score) in scores.enumerated() {
            let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            scoreLabel.text = "\(score.name): \(score.score)"
            scoreLabel.name = "highScore"
            scoreLabel.fontSize = 24
            scoreLabel.fontColor = .white
            scoreLabel.position = CGPoint(x: 0, y: startingY - 60 - CGFloat(index * 35))
            container.addChild(scoreLabel)
        }
    }
    
    // Add restart game functionality
    private func restartGame() {
        // Remove game over overlay
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        // Remove name entry field if it exists
        nameEntryField?.removeFromSuperview()
        nameEntryField = nil
        
        // Reset all firing and power-up states
        isRapidFiring = false
        isForceFieldActive = false
        isSpinAttackActive = false
        isTouching = false
        touchStartTime = 0
        lastTapTime = 0
        
        // Clean up timers
        rapidFireTimer?.invalidate()
        rapidFireTimer = nil
        spinAttackTimer?.invalidate()
        spinAttackTimer = nil
        
        // Remove force field if it exists
        forceField?.removeFromParent()
        forceField = nil
        
        // Reset game values
        gameState = .playing
        asteroidsSpawned = 0
        asteroidsDestroyed = 0
        currentLevel = 1
        lives = 3
        gameTimer = 0
        currentAsteroids = 0
        
        // Remove all existing nodes except HUD
        children.forEach { node in
            if ![livesTitleLabel, levelTitleLabel, activeTitleLabel, timerTitleLabel, hitsTitleLabel,
                livesValueLabel, levelValueLabel, activeValueLabel, timerValueLabel, hitsValueLabel].contains(node) {
                node.removeFromParent()
            }
        }
        
        // Reset and restart the game in the current scene
        setupGame()
        updateHUD()
        
        remainingBullets = bulletsPerLevel
    }
    
    // Add function to split asteroid
    private func splitAsteroid(_ asteroid: SKNode, at position: CGPoint) {
        guard let radius = asteroid.userData?["radius"] as? CGFloat else { return }
        
        // Determine split configuration
        let splitConfig: (count: Int, size: CGFloat)
        
        if radius >= AsteroidSizes.large {
            splitConfig = (count: 3, size: AsteroidSizes.medium)
        } else if radius >= AsteroidSizes.medium {
            splitConfig = (count: 2, size: AsteroidSizes.small)
        } else {
            return  // Too small to split
        }
        
        print("Splitting asteroid - Before split count: \(currentAsteroids)")
        
        // Create split asteroids
        for i in 0..<splitConfig.count {
            let newAsteroid = SKShapeNode(path: createIrregularAsteroidPath(radius: splitConfig.size))
            newAsteroid.strokeColor = .white
            newAsteroid.fillColor = .clear
            newAsteroid.lineWidth = 2
            newAsteroid.name = "asteroid"
            newAsteroid.position = position
            
            let physicsBody = SKPhysicsBody(circleOfRadius: splitConfig.size)
            physicsBody.categoryBitMask = PhysicsCategory.asteroid
            physicsBody.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.player
            physicsBody.collisionBitMask = PhysicsCategory.boundary | PhysicsCategory.asteroid
            physicsBody.isDynamic = true
            physicsBody.affectedByGravity = false
            physicsBody.restitution = 1.0
            newAsteroid.physicsBody = physicsBody
            
            let angle = CGFloat.random(in: 0..<2 * .pi)
            let speed: CGFloat = 75
            let vector = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            
            addChild(newAsteroid)
            newAsteroid.physicsBody?.velocity = vector
            currentAsteroids += 1
            print("Added split asteroid \(i + 1) - Current count: \(currentAsteroids)")
        }
        
        verifyAsteroidCount()
        print("After split total count: \(currentAsteroids)")
    }
    
    // Add function to update level label
    private func updateLevelLabel() {
        // This can be removed
    }
    
    // Update handleAsteroidDestruction with better counting
    private func handleAsteroidDestruction(asteroid: SKNode, bullet: SKNode) {
        print("\n--- Handling Asteroid Destruction ---")
        print("Before destruction - Count: \(currentAsteroids)")
        
        // Remove the bullet and asteroid
        bullet.removeFromParent()
        asteroid.removeFromParent()
        
        currentAsteroids -= 1
        asteroidsDestroyed += 1
        
        print("After removing asteroid - Count: \(currentAsteroids)")
        
        // Create explosion effect
        createExplosion(at: asteroid.position, radius: explosionRadius)
        
        // Split the asteroid if it's large enough
        splitAsteroid(asteroid, at: asteroid.position)
        
        verifyAsteroidCount()
        
        print("Final count after destruction and splits: \(currentAsteroids)")
        
        // Only advance level if truly no asteroids remain
        let actualCount = children.filter { $0.name == "asteroid" }.count
        if actualCount == 0 {
            print("All asteroids confirmed destroyed! Advancing to next level...")
            advanceToNextLevel()
        } else if currentAsteroids <= 0 {
            print("Count mismatch - Fixing count. Actual asteroids: \(actualCount)")
            currentAsteroids = actualCount
        }
        
        updateHUD()
    }
    
    // Update advanceToNextLevel to ensure proper level transition
    private func advanceToNextLevel() {
        print("Current level: \(currentLevel), advancing to next level")
        
        // Remove any remaining asteroids
        enumerateChildNodes(withName: "asteroid") { node, _ in
            node.removeFromParent()
        }
        
        currentLevel += 1
        currentAsteroids = 0
        
        print("Starting level \(currentLevel)")
        
        // Show level advancement message
        let levelUpLabel = SKLabelNode(fontNamed: "SF Pro Text")
        levelUpLabel.text = "Level \(currentLevel)!"
        levelUpLabel.fontSize = 40
        levelUpLabel.fontColor = .white
        levelUpLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(levelUpLabel)
        
        // Wait a moment before starting next level
        levelUpLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])) { [weak self] in
            guard let self = self else { return }
            print("Starting new level with \(self.totalAsteroidsForLevel) asteroids")
            self.startLevel()
        }
        
        updateHUD()
    }
    
    private func setupHUD() {
        // Remove any existing HUD elements
        children.forEach { node in
            if node.name?.contains("HUD") == true {
                node.removeFromParent()
            }
        }
        
        // Define HUD items (title, value)
        let hudItems = [
            ("LIVES", "\(lives)"),
            ("LEVEL", "\(currentLevel)"),
            ("TIME", String(format: "%02d:%02d", Int(gameTimer) / 60, Int(gameTimer) % 60)),
            ("ACTIVE", "\(currentAsteroids)"),
            ("SCORE", "\(asteroidsDestroyed)"),
            ("BULLETS", "\(remainingBullets)")
        ]
        
        // Create HUD elements
        for (index, item) in hudItems.enumerated() {
            let position = UI.Position.positions[index]
            
            // Create title label (smaller font)
            let titleLabel = SKLabelNode(fontNamed: "SF Pro Text")
            titleLabel.fontSize = UI.titleFontSize  // Smaller font for titles
            titleLabel.fontColor = .white
            titleLabel.text = item.0
            titleLabel.horizontalAlignmentMode = .center
            titleLabel.verticalAlignmentMode = .top
            titleLabel.position = CGPoint(
                x: frame.width * position,
                y: frame.height * UI.Position.topRow
            )
            titleLabel.name = "HUD_\(item.0)_title"
            addChild(titleLabel)
            
            // Create value label (larger font)
            let valueLabel = SKLabelNode(fontNamed: "SF Pro Text")
            valueLabel.fontSize = UI.valueFontSize  // Larger font for values
            valueLabel.fontColor = .white
            valueLabel.text = item.1
            valueLabel.horizontalAlignmentMode = .center
            valueLabel.verticalAlignmentMode = .top
            valueLabel.position = CGPoint(
                x: frame.width * position,
                y: frame.height * UI.Position.valueRow
            )
            valueLabel.name = "HUD_\(item.0)_value"
            addChild(valueLabel)
        }
    }
    
    private func updateHUD() {
        // Update value labels
        if let livesLabel = childNode(withName: "HUD_LIVES_value") as? SKLabelNode {
            livesLabel.text = "\(lives)"
        }
        if let levelLabel = childNode(withName: "HUD_LEVEL_value") as? SKLabelNode {
            levelLabel.text = "\(currentLevel)"
        }
        if let timeLabel = childNode(withName: "HUD_TIME_value") as? SKLabelNode {
            timeLabel.text = String(format: "%02d:%02d", Int(gameTimer) / 60, Int(gameTimer) % 60)
        }
        if let activeLabel = childNode(withName: "HUD_ACTIVE_value") as? SKLabelNode {
            activeLabel.text = "\(currentAsteroids)"
        }
        if let scoreLabel = childNode(withName: "HUD_SCORE_value") as? SKLabelNode {
            scoreLabel.text = "\(asteroidsDestroyed)"
        }
        if let bulletsLabel = childNode(withName: "HUD_BULLETS_value") as? SKLabelNode {
            bulletsLabel.text = "\(remainingBullets)"
        }
    }
    
    // Update verifyAsteroidCount to be more thorough
    private func verifyAsteroidCount() {
        let actualCount = children.filter { $0.name == "asteroid" }.count
        if actualCount != currentAsteroids {
            print("Asteroid count mismatch!")
            print("Current tracked count: \(currentAsteroids)")
            print("Actual asteroids in scene: \(actualCount)")
            print("Asteroid positions:")
            children.filter { $0.name == "asteroid" }.forEach { asteroid in
                print("Asteroid at: \(asteroid.position)")
            }
            currentAsteroids = actualCount
            updateHUD()
        }
    }
    
    private func activateForceField() {
        guard let player = player, !isForceFieldActive else { 
            print("Force field activation failed - conditions not met")
            return 
        }
        
        print("Creating force field")
        isForceFieldActive = true
        
        // Create force field visual effect
        let forceFieldRadius: CGFloat = 50.0  // Made even larger
        let forceField = SKShapeNode(circleOfRadius: forceFieldRadius)
        forceField.strokeColor = .yellow
        forceField.lineWidth = 4.0  // Made thicker
        forceField.position = CGPoint.zero
        forceField.zPosition = 2  // Ensure it's above other elements
        
        // Add stronger glow effect
        forceField.fillColor = .yellow.withAlphaComponent(0.4)
        
        // Add to player
        player.addChild(forceField)
        self.forceField = forceField
        
        // Disable player collisions
        player.physicsBody?.categoryBitMask = 0
        
        // Add more noticeable pulse animation
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        forceField.run(SKAction.repeatForever(pulseAction))
        
        // Add activation effect
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.1),
            SKAction.fadeAlpha(to: 0.4, duration: 0.1)
        ])
        forceField.run(flash)
        
        print("Force field activated")
        
        // Remove force field after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            print("Deactivating force field")
            self?.deactivateForceField()
        }
    }
    
    private func deactivateForceField() {
        guard let player = player, isForceFieldActive else { return }
        
        // Remove force field visual
        forceField?.removeFromParent()
        forceField = nil
        
        // Re-enable player collisions
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        
        isForceFieldActive = false
    }
    
    // Add new function for spin attack
    private func activateSpinAttack() {
        guard let player = player, !isSpinAttackActive else { return }
        
        isSpinAttackActive = true
        print("Starting spin attack")
        
        // Create rotation action
        let rotateAction = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 1.0))
        player.run(rotateAction)
        
        // Set up rapid fire timer
        var fireCount = 0
        spinAttackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Fire in three directions
            for i in 0..<3 {
                let angle = (CGFloat(i) * (2.0 * .pi / 3.0)) + self.player!.zRotation
                self.fireSpinAttackBullet(at: angle)
            }
            
            fireCount += 1
            if fireCount >= 30 { // 3 seconds (30 * 0.1 second intervals)
                self.deactivateSpinAttack()
                timer.invalidate()
            }
        }
    }
    
    private func fireSpinAttackBullet(at angle: CGFloat) {
        guard let player = player else { return }
        
        let bullet = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 4))
        bullet.position = player.position
        bullet.zRotation = angle
        bullet.name = "bullet"
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 2)
        physicsBody.categoryBitMask = PhysicsCategory.bullet
        physicsBody.contactTestBitMask = PhysicsCategory.asteroid
        physicsBody.collisionBitMask = PhysicsCategory.none
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        bullet.physicsBody = physicsBody
        
        // Higher speed for spin attack bullets
        let bulletSpeed: CGFloat = 500
        let vector = CGVector(
            dx: cos(angle) * bulletSpeed,
            dy: sin(angle) * bulletSpeed
        )
        
        addChild(bullet)
        bullet.physicsBody?.velocity = vector
        
        // Remove bullet after 1 second (faster cleanup for rapid fire)
        bullet.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }
    
    private func deactivateSpinAttack() {
        guard let player = player, isSpinAttackActive else { return }
        
        print("Deactivating spin attack")
        isSpinAttackActive = false
        
        // Stop rotation
        player.removeAllActions()
        
        // Reset rotation to upright
        let resetRotation = SKAction.rotate(toAngle: 0, duration: 0.3)
        player.run(resetRotation)
        
        // Clean up timer
        spinAttackTimer?.invalidate()
        spinAttackTimer = nil
    }
    
    private func startRapidFire(fast: Bool) {
        guard !isRapidFiring else { return }
        isRapidFiring = true
        
        let interval = fast ? rapidFireFastInterval : rapidFireInterval
        rapidFireTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.shoot()
        }
    }
    
    private func stopRapidFire() {
        isRapidFiring = false
        rapidFireTimer?.invalidate()
        rapidFireTimer = nil
    }
    
    // Add new function for handling out of bullets
    private func outOfBullets() {
        // Stop any ongoing rapid fire
        stopRapidFire()
        
        // Create warning message
        let warningNode = SKNode()
        warningNode.position = CGPoint(x: frame.midX, y: frame.midY)
        warningNode.zPosition = 100
        addChild(warningNode)
        
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 150))
        background.fillColor = .black
        background.strokeColor = .white
        background.lineWidth = 2
        warningNode.addChild(background)
        
        let warningLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        warningLabel.text = "OUT OF BULLETS!"
        warningLabel.fontSize = 32
        warningLabel.fontColor = .white
        warningLabel.position = CGPoint(x: 0, y: 20)
        warningNode.addChild(warningLabel)
        
        // Flash the warning
        let flashAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ])
        warningNode.run(flashAction) { [weak self] in
            self?.loseLife()
        }
    }
    
    // Update loseLife function
    private func loseLife() {
        if lives > 0 {
            lives -= 1
            updateHUD()
            
            if lives <= 0 {
                createExplosion(at: player?.position ?? CGPoint.zero, radius: explosionRadius)
                player?.removeFromParent()
                gameOver()
            } else {
                // Reset player position and give temporary invulnerability
                if let player = player {
                    createExplosion(at: player.position, radius: explosionRadius)
                    player.position = CGPoint(x: frame.midX, y: frame.midY)
                    player.physicsBody?.velocity = CGVector.zero
                    player.zRotation = 0
                    
                    // Reset bullets for the current level
                    remainingBullets = bulletsPerLevel
                    updateHUD()
                    
                    // Make player temporarily invulnerable
                    player.physicsBody?.categoryBitMask = 0
                    let blinkCount = 6
                    let blinkDuration = 0.2
                    let blink = SKAction.sequence([
                        SKAction.fadeOut(withDuration: blinkDuration/2),
                        SKAction.fadeIn(withDuration: blinkDuration/2)
                    ])
                    let blinkAction = SKAction.repeat(blink, count: blinkCount)
                    
                    player.run(blinkAction) {
                        player.physicsBody?.categoryBitMask = PhysicsCategory.player
                    }
                }
            }
        }
    }
    
    private func wrapAsteroids() {
        enumerateChildNodes(withName: "asteroid") { node, _ in
            if node.position.x < -20 {
                node.position.x = self.frame.width + 20
            } else if node.position.x > self.frame.width + 20 {
                node.position.x = -20
            }
            
            if node.position.y < -20 {
                node.position.y = self.frame.height + 20
            } else if node.position.y > self.frame.height + 20 {
                node.position.y = -20
            }
        }
    }
}

extension GameScene: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let name = textField.text, !name.isEmpty else { return false }
        
        // Save high score
        HighScoreManager.shared.addScore(name, score: asteroidsDestroyed)
        
        // Remove text field
        textField.removeFromSuperview()
        nameEntryField = nil
        isEnteringName = false
        
        // Clear existing high scores and "ENTER YOUR NAME" text from view
        enumerateChildNodes(withName: "highScore") { node, _ in
            node.removeFromParent()
        }
        
        // Remove "ENTER YOUR NAME" text
        if let container = children.first(where: { $0.zPosition == 101 }) {
            container.enumerateChildNodes(withName: "namePrompt") { node, _ in
                node.removeFromParent()
            }
            
            // Show updated high scores (only once)
            showHighScores(in: container, startingY: 60)
            
            // Add tap to restart text at bottom
            let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            restartLabel.text = "TAP TO RESTART"
            restartLabel.fontSize = 30
            restartLabel.fontColor = .white
            restartLabel.position = CGPoint(x: 0, y: -250)
            restartLabel.name = "restartLabel"
            container.addChild(restartLabel)
        }
        
        return true
    }
} 