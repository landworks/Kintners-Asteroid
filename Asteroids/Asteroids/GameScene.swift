import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate, HelpScreenProvider {
    
    // MARK: - Properties
    private(set) var player: Player?
    private var gameState: GameState = .ready
    private var level: Int = 1
    private var score: Int = 0
    private var gameOverContainer: SKNode?
    
    private var isTouching: Bool = false
    private var touchLocation: CGPoint = CGPoint.zero
    
    private var explosionRadius: CGFloat = 60.0
    private var largeAsteroidSize: CGFloat = 40.0
    private var mediumAsteroidSize: CGFloat = 25.0
    private var smallAsteroidSize: CGFloat = 15.0
    
    private var asteroidsSpawned: Int = 0
    private var asteroidsDestroyed: Int = 0
    private var scoreLabel: SKLabelNode?
    
    private let controlAreaHeight: CGFloat = 100.0  // Height of bottom control area
    private let rotationRange: CGFloat = .pi * 2    // Full 360 degrees
    private var isThrusting: Bool = false
    private var initialTouchX: CGFloat = 0
    private var initialTouchY: CGFloat = 0
    private let thrustPower: CGFloat = 5.0  // Reduced from 20.0 for much slower acceleration
    
    private var lastTouchX: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var currentRotation: CGFloat = 0
    private var rotationSensitivity: CGFloat = 0.005  // Reduced from 0.01 for slower rotation
    
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
                0.08,   // Life
                0.20,   // Shield
                0.32,   // Super
                0.44,   // Level
                0.56,   // Time
                0.68,   // Active
                0.80,   // Score
                0.92    // Bullets
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
        static let maxForceFields: Int = 10        // Maximum force field uses
        static let maxSuperFires: Int = 5          // Maximum super fire uses
        static let bulletsPerLevel: Int = 200      // Bullets per level
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
    private var remainingForceFields: Int = GameConstants.maxForceFields
    private var remainingSuperFires: Int = GameConstants.maxSuperFires
    private var bulletsTitleLabel: SKLabelNode?
    private var bulletsValueLabel: SKLabelNode?
    
    // Add helpOverlay property at the top with other properties
    var helpOverlay: SKNode?
    
    // Add touch indicator properties
    private var touchIndicator: SKShapeNode?
    private var directionIndicator: SKShapeNode?
    
    // Add new properties at the top
    private var enterNameLabel: SKLabelNode?
    
    // Add property for notification observer
    private var highScoreObserver: NSObjectProtocol?
    
    // Add these properties at the top with other properties
    private var remainingBullets: Int = 0
    private var bulletsPerLevel: Int {
        return GameConstants.bulletsPerLevel
    }
    
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
        setupTouchIndicators()
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
        remainingForceFields = GameConstants.maxForceFields
        remainingSuperFires = GameConstants.maxSuperFires
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
        
        // Check for help overlay first
        if helpOverlay != nil {
            hideHelpScreen()
            return
        }
        
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
            guard let touch = touches.first else { return }
            let location = touch.location(in: self)
            
            if let container = children.first(where: { $0.zPosition == 91 }) {
                let containerLocation = container.convert(location, from: self)
                
                // Check for help button tap
                if let helpButton = container.childNode(withName: "helpButton") as? SKLabelNode,
                   helpButton.frame.contains(containerLocation) {
                    showHelpScreen()
                    return
                }
                
                // Check for restart button tap (existing code)
                if let restartLabel = container.childNode(withName: "restartLabel") as? SKLabelNode {
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
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              isTouching,
              let player = player else { return }
        
        let newLocation = touch.location(in: self)
        let previousLocation = touchLocation
        
        // Calculate horizontal and vertical movement
        let deltaX = newLocation.x - previousLocation.x
        let deltaY = newLocation.y - previousLocation.y
        
        // Handle rotation (horizontal movement)
        player.zRotation += deltaX * -rotationSensitivity
        
        // Only apply thrust for significant vertical movement (moving finger up/down)
        if abs(deltaY) > abs(deltaX) && abs(deltaY) > 1.0 {
            // Calculate thrust vector based on ship's rotation
            let angle = player.zRotation + CGFloat.pi/2  // Adjust for sprite orientation
            let thrustVector = CGVector(
                dx: cos(angle) * thrustPower,
                dy: sin(angle) * thrustPower
            )
            
            // Apply thrust
            player.physicsBody?.applyForce(thrustVector)
            
            // Show thrust visual
            showThrustFire(active: true)
        } else {
            // Hide thrust visual when not moving vertically
            showThrustFire(active: false)
        }
        
        touchLocation = newLocation
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        stopRapidFire()
        showThrustFire(active: false)  // Hide thrust when touch ends
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        stopRapidFire()
        showThrustFire(active: false)  // Hide thrust when touch cancelled
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
                // Call loseLife instead of duplicating the logic
                loseLife()
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
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = 90
        addChild(overlay)
        gameOverOverlay = overlay
        
        // Create main container for all content
        let contentNode = SKNode()
        contentNode.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        contentNode.zPosition = 91
        addChild(contentNode)
        
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
        if let container = children.first(where: { $0.zPosition == 91 }),
           let gameOverLabel = container.childNode(withName: "gameOverLabel") as? SKLabelNode {
            let containerLocation = container.convert(sceneLocation, from: self)
            
            // Check if tap is on "GAME OVER" text frame
            if gameOverLabel.frame.contains(containerLocation) {
                print("Triple tap detected on GAME OVER text")
                // Clear high scores
                HighScoreManager.shared.clearScores()
                
                // Remove existing scores
                container.enumerateChildNodes(withName: "highScore") { node, _ in
                    node.removeFromParent()
                }
                
                // Show empty high scores list
                showHighScores(in: container, startingY: 100)
                
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
        showHighScores(in: container, startingY: 100)
    }
    
    // MARK: - High Score Display Methods
    
    /// Shows the high score entry interface when player achieves a high score
    /// - Parameter container: The container node where high score UI will be displayed
    private func showHighScoreEntry(in container: SKNode) {
        print("\n=== Setting up High Score Entry ===")
        
        // Store reference to container for later updates
        gameOverContainer = container
        
        // Clean up any existing observer to prevent duplicates
        if let observer = highScoreObserver {
            NotificationCenter.default.removeObserver(observer)
            highScoreObserver = nil
        }
        
        // Single GAME OVER at top
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: 100)
        gameOverLabel.name = "gameOverLabel"
        container.addChild(gameOverLabel)
        
        // Create text field for name entry on main thread
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self,
                  let view = self.view,
                  let window = view.window else { return }
            
            // Remove any existing text field
            self.cleanupTextField()
            
            // Calculate text field position in window coordinates
            let sceneSpacePoint = CGPoint(x: view.bounds.midX - 100,
                                        y: view.bounds.height/2)
            let windowSpacePoint = view.convert(sceneSpacePoint, to: window)
            
            let textField = UITextField(frame: CGRect(
                x: windowSpacePoint.x,
                y: windowSpacePoint.y,
                width: 200,
                height: 40
            ))
            
            textField.backgroundColor = .white
            textField.textColor = .black
            textField.textAlignment = .center
            textField.font = UIFont(name: "AvenirNext-DemiBold", size: 20)
            textField.placeholder = "ENTER YOUR NAME"
            textField.delegate = self
            textField.returnKeyType = .done
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .allCharacters
            textField.spellCheckingType = .no
            textField.smartQuotesType = .no
            textField.smartDashesType = .no
            textField.smartInsertDeleteType = .no
            textField.layer.cornerRadius = 6
            textField.layer.borderWidth = 2
            textField.layer.borderColor = UIColor.white.cgColor
            
            // Add to window instead of view
            window.addSubview(textField)
            self.nameEntryField = textField
            
            // Delay becoming first responder slightly to ensure proper setup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textField.becomeFirstResponder()
            }
            
            self.isEnteringName = true
            
            // Add "ENTER NAME FOR HIGH SCORE" label above text field
            let enterNameLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            enterNameLabel.text = "NAME FOR HIGH SCORE"
            enterNameLabel.fontSize = 28
            enterNameLabel.fontColor = .white
            enterNameLabel.position = CGPoint(x: 0, y: 0)
            enterNameLabel.name = "enterNameLabel"
            container.addChild(enterNameLabel)
            self.enterNameLabel = enterNameLabel
            
            // Add score lxabel
            let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            scoreLabel.text = "SCORE: \(asteroidsDestroyed)"
            scoreLabel.fontSize = 32
            scoreLabel.fontColor = .white
            scoreLabel.position = CGPoint(x: 0, y: -150)  // Fixed position relative to container
            container.addChild(scoreLabel)
            
            // Add level label
            let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            levelLabel.text = "LEVEL: \(currentLevel)"
            levelLabel.fontSize = 32
            levelLabel.fontColor = .white
            levelLabel.position = CGPoint(x: 0, y: scoreLabel.position.y - 40)  // Position below score
            container.addChild(levelLabel)
        }
        
        // Dispatch the work item
        DispatchQueue.main.async(execute: workItem)
    }
    
    /// Shows the high scores screen after game over
    private func showHighScoresAfterGameOver() {
        // Remove the previous game over container and create a new one
        gameOverContainer?.removeFromParent()
        
        let container = SKNode()
        container.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        container.zPosition = 91
        addChild(container)
        gameOverContainer = container
        
        // Single HIGH SCORES label
        let highScoresLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoresLabel.text = "TOP 10 CHAMPS"
        highScoresLabel.fontSize = 46
        highScoresLabel.fontColor = .white
        highScoresLabel.position = CGPoint(x: 0, y: 200)
        container.addChild(highScoresLabel)
        
        // Show high scores table
        showHighScores(in: container, startingY: 100)
        
        // Bottom buttons
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        restartLabel.text = "TAP TO RESTART"
        restartLabel.fontSize = 28
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -300)
        restartLabel.name = "restartLabel"
        container.addChild(restartLabel)
        
        let helpLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        helpLabel.text = "HELP"
        helpLabel.fontSize = 28
        helpLabel.fontColor = .white
        helpLabel.position = CGPoint(x: 0, y: -350)
        helpLabel.name = "helpButton"
        container.addChild(helpLabel)
    }
    
    /// Shows the final score screen for non-high scores
    private func showFinalScore(in container: SKNode) {
        // Create a simplified version of the high scores screen
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: 200)
        gameOverLabel.name = "gameOverLabel"
        container.addChild(gameOverLabel)
        
        // Show the score
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "FINAL SCORE: \(asteroidsDestroyed)"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: 140)
        container.addChild(scoreLabel)
        
        // Add level label
        let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelLabel.text = "FINAL LEVEL: \(currentLevel)"
        levelLabel.fontSize = 36
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: 0, y: 100)  // Position below score
        container.addChild(levelLabel)
        
        // Show high scores table
        showHighScores(in: container, startingY: 50)  // Adjusted Y position to accommodate new label
        
        // Bottom buttons (same as high score screen)
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        restartLabel.text = "TAP TO RESTART"
        restartLabel.fontSize = 28
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -400)
        restartLabel.name = "restartLabel"
        container.addChild(restartLabel)
        
        let helpLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        helpLabel.text = "HELP"
        helpLabel.fontSize = 28
        helpLabel.fontColor = .white
        helpLabel.position = CGPoint(x: 0, y: -450)
        helpLabel.name = "helpButton"
        container.addChild(helpLabel)
    }
    
    /// Displays the high score table
    /// - Parameters:
    ///   - container: The container node where scores will be displayed
    ///   - startingY: The Y position to start displaying scores from
    private func showHighScores(in container: SKNode, startingY: CGFloat) {
        print("\n=== Showing High Scores ===")
        let scores = HighScoreManager.shared.highScores.prefix(10)
        print("📊 Displaying \(scores.count) scores")
        
        // Adjust x-positions to center the table
        let nameX: CGFloat = -180
        let scoreX: CGFloat = -5
        let dateX: CGFloat = 60
        
        // Column Headers
        let columnY = startingY - 40
        
        let nameHeader = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nameHeader.text = "NAME"
        nameHeader.fontSize = 20
        nameHeader.fontColor = .white
        nameHeader.horizontalAlignmentMode = .left
        nameHeader.position = CGPoint(x: nameX, y: columnY)
        nameHeader.name = "highScore"
        container.addChild(nameHeader)
        
        let scoreHeader = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreHeader.text = "SCORE"
        scoreHeader.fontSize = 20
        scoreHeader.fontColor = .white
        scoreHeader.horizontalAlignmentMode = .center
        scoreHeader.position = CGPoint(x: scoreX, y: columnY)
        scoreHeader.name = "highScore"
        container.addChild(scoreHeader)
        
        let dateHeader = SKLabelNode(fontNamed: "AvenirNext-Bold")
        dateHeader.text = "DATE"
        dateHeader.fontSize = 20
        dateHeader.fontColor = .white
        dateHeader.horizontalAlignmentMode = .left
        dateHeader.position = CGPoint(x: dateX, y: columnY)
        dateHeader.name = "highScore"
        container.addChild(dateHeader)
        
        // Score list with table layout
        for (index, score) in scores.enumerated() {
            let rowY = startingY - 70 - CGFloat(index * 28)
            
            // Name column (left-aligned)
            let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            nameLabel.text = score.name
            nameLabel.fontSize = 20
            nameLabel.fontColor = .white
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: nameX, y: rowY)
            nameLabel.name = "highScore"
            container.addChild(nameLabel)
            
            // Score column (center-aligned)
            let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            scoreLabel.text = "\(score.score)"
            scoreLabel.fontSize = 20
            scoreLabel.fontColor = .white
            scoreLabel.horizontalAlignmentMode = .center
            scoreLabel.position = CGPoint(x: scoreX, y: rowY)
            scoreLabel.name = "highScore"
            container.addChild(scoreLabel)
            
            // Date column (left-aligned)
            let dateLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd HH:mm"
            let dateText = dateFormatter.string(from: score.date)
            dateLabel.text = dateText
            dateLabel.fontSize = 20
            dateLabel.fontColor = .white
            dateLabel.horizontalAlignmentMode = .left
            dateLabel.position = CGPoint(x: dateX, y: rowY)
            dateLabel.name = "highScore"
            container.addChild(dateLabel)
        }
    }
    
    // Add restart game functionality
    private func restartGame() {
        // Remove high score observer
        if let observer = highScoreObserver {
            NotificationCenter.default.removeObserver(observer)
            highScoreObserver = nil
        }
        
        // Clean up the text field first
        cleanupTextField()
        
        // Remove game over overlay
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
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
    
    // MARK: - Text Field Cleanup Methods
    
    /// Cleanup text field and associated resources
    private func cleanupTextField() {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupTextField()
            }
            return
        }
        
        // Disable interaction and mark as not entering name
        nameEntryField?.isUserInteractionEnabled = false
        isEnteringName = false
        
        // Remove the "ENTER NAME" label
        enterNameLabel?.removeFromParent()
        enterNameLabel = nil
        
        // Properly dismiss keyboard first
        if nameEntryField?.isFirstResponder == true {
            nameEntryField?.resignFirstResponder()
            // Give time for keyboard to dismiss before final cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.finalizeTextFieldCleanup()
            }
        } else {
            finalizeTextFieldCleanup()
        }
    }
    
    /// Final step of text field cleanup
    private func finalizeTextFieldCleanup() {
        nameEntryField?.removeFromSuperview()
        nameEntryField = nil
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
        levelUpLabel.position = CGPoint(x: frame.midX, y: frame.midY+100)
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
            ("LIFE", "\(lives)"),
            ("SHD", "\(remainingForceFields)"),
            ("SPR", "\(remainingSuperFires)"),
            ("LVL", "\(currentLevel)"),
            ("TIME", String(format: "%02d:%02d", Int(gameTimer) / 60, Int(gameTimer) % 60)),
            ("ACT", "\(currentAsteroids)"),
            ("SCR", "\(asteroidsDestroyed)"),
            ("BUL", "\(remainingBullets)")
        ]
        
        // Create HUD elements
        for (index, item) in hudItems.enumerated() {
            let position = UI.Position.positions[index]
            
            // Create title label (smaller font)
            let titleLabel = SKLabelNode(fontNamed: "SF Pro Text")
            titleLabel.fontSize = UI.titleFontSize
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
            valueLabel.fontSize = UI.valueFontSize
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
        if let livesLabel = childNode(withName: "HUD_LIFE_value") as? SKLabelNode {
            livesLabel.text = "\(lives)"
        }
        if let shieldLabel = childNode(withName: "HUD_SHD_value") as? SKLabelNode {
            shieldLabel.text = "\(remainingForceFields)"
        }
        if let superLabel = childNode(withName: "HUD_SPR_value") as? SKLabelNode {
            superLabel.text = "\(remainingSuperFires)"
        }
        if let levelLabel = childNode(withName: "HUD_LVL_value") as? SKLabelNode {
            levelLabel.text = "\(currentLevel)"
        }
        if let timeLabel = childNode(withName: "HUD_TIME_value") as? SKLabelNode {
            timeLabel.text = String(format: "%02d:%02d", Int(gameTimer) / 60, Int(gameTimer) % 60)
        }
        if let activeLabel = childNode(withName: "HUD_ACT_value") as? SKLabelNode {
            activeLabel.text = "\(currentAsteroids)"
        }
        if let scoreLabel = childNode(withName: "HUD_SCR_value") as? SKLabelNode {
            scoreLabel.text = "\(asteroidsDestroyed)"
        }
        if let bulletsLabel = childNode(withName: "HUD_BUL_value") as? SKLabelNode {
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
        guard let player = player, !isForceFieldActive, remainingForceFields > 0 else { return }
        
        print("Creating force field")
        isForceFieldActive = true
        remainingForceFields -= 1
        updateHUD()
        
        // Create force field visual effect
        let forceFieldRadius: CGFloat = 50.0
        let forceField = SKShapeNode(circleOfRadius: forceFieldRadius)
        forceField.strokeColor = .yellow
        forceField.lineWidth = 4.0
        forceField.position = CGPoint.zero
        forceField.zPosition = 2
        forceField.fillColor = .yellow.withAlphaComponent(0.4)
        
        // Add physics body to force field
        let forceFieldBody = SKPhysicsBody(circleOfRadius: forceFieldRadius)
        forceFieldBody.isDynamic = false
        forceFieldBody.categoryBitMask = PhysicsCategory.boundary
        forceFieldBody.collisionBitMask = PhysicsCategory.asteroid // Only collide with asteroids
        forceFieldBody.contactTestBitMask = PhysicsCategory.asteroid
        forceFieldBody.restitution = 1.0 // Make asteroids bounce off
        forceField.physicsBody = forceFieldBody
        
        // Add to player
        player.addChild(forceField)
        self.forceField = forceField
        
        // Make player immune to asteroids but NOT to force field
        player.physicsBody?.categoryBitMask = 0
        player.physicsBody?.collisionBitMask = 0 // Prevent all collisions for player
        
        // Add pulse animation
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        forceField.run(SKAction.repeatForever(pulseAction))
        
        // Remove force field after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
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
        guard let player = player, !isSpinAttackActive, remainingSuperFires > 0 else { return }
        
        isSpinAttackActive = true
        remainingSuperFires -= 1
        updateHUD()
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
                    print("Before reset - Player position: \(player.position)")
                    print("Scene center: (\(size.width/2), \(size.height/2))")
                    
                    // Create explosion at current position
                    createExplosion(at: player.position, radius: explosionRadius)
                    
                    // Remove any ongoing actions first
                    player.removeAllActions()
                    
                    // Force position update to center
                    let centerPoint = CGPoint(x: size.width/2, y: size.height/2)
                    player.position = centerPoint
                    player.run(SKAction.move(to: centerPoint, duration: 0))
                    
                    print("After reset - Player position: \(player.position)")
                    
                    // Completely stop all movement
                    player.physicsBody?.velocity = .zero
                    player.physicsBody?.angularVelocity = 0
                    player.zRotation = 0
                    
                    // Ensure physics body is active but temporarily invulnerable
                    player.physicsBody?.isDynamic = true
                    player.physicsBody?.categoryBitMask = 0
                    
                    // Stop any ongoing thrust
                    showThrustFire(active: false)
                    isThrusting = false
                    
                    // Reset bullets for the current level
                    remainingBullets = bulletsPerLevel
                    updateHUD()
                    
                    // Make player temporarily invulnerable with blinking effect
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
                        print("Final position check - Player position: \(player.position)")
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
    
    private func setupTouchIndicators() {
        // Touch point indicator
        let indicator = SKShapeNode(circleOfRadius: 20)
        indicator.strokeColor = .white
        indicator.fillColor = .white.withAlphaComponent(0.3)
        indicator.alpha = 0
        addChild(indicator)
        touchIndicator = indicator
        
        // Direction arrow
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: 0, y: 15))
        arrowPath.addLine(to: CGPoint(x: -5, y: 0))
        arrowPath.addLine(to: CGPoint(x: 5, y: 0))
        arrowPath.closeSubpath()
        
        let arrow = SKShapeNode(path: arrowPath)
        arrow.strokeColor = .white
        arrow.fillColor = .white.withAlphaComponent(0.5)
        arrow.alpha = 0
        addChild(arrow)
        directionIndicator = arrow
    }
    
    private func showThrustFire(active: Bool) {
        guard let player = player else { return }
        player.showThrust(active)
    }
}

// MARK: - High Score Entry Handling
extension GameScene: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("\n=== Processing High Score Entry ===")
        
        guard let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            print("❌ No name entered, ignoring submission")
            return false
        }
        
        print("📝 Name entered: \(name), Score: \(asteroidsDestroyed)")
        
        // Disable further editing
        textField.isUserInteractionEnabled = false
        
        // Clean up the text field immediately
        cleanupTextField()
        
        // Set up observer for high score updates
        highScoreObserver = NotificationCenter.default.addObserver(
            forName: .highScoresDidUpdate,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self = self else { return }
                self.showHighScoresAfterGameOver()
        }
        
        // Save high score and show the high scores screen
        print("💾 Saving score to CloudKit")
        HighScoreManager.shared.addScore(name, score: asteroidsDestroyed)
        
        return true
    }
} 
