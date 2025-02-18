import SpriteKit

class SplashScene: SKScene, HelpScreenProvider {
    var onStartGame: (() -> Void)?
    var helpOverlay: SKNode?  // Required by protocol
    var highScoresOverlay: SKNode?  // For high scores screen
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupTapToBegin()
        
        // Add observer for high score updates
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(highScoresDidUpdate),
                                             name: .highScoresDidUpdate,
                                             object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func highScoresDidUpdate() {
        // Only refresh if the high scores overlay is currently showing
        if let container = highScoresOverlay?.children.first(where: { $0.name == "container" }) as? SKNode {
            // Remove existing score nodes and loading label
            container.children.filter { $0.name == "highScore" || $0.name == "loadingLabel" }.forEach { $0.removeFromParent() }
            // Show updated scores
            showHighScoresTable(in: container, startingY: 100)
        }
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "SplashBackground")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.size = frame.size
        background.zPosition = -10
        addChild(background)
    }
    
    private func setupTapToBegin() {
        // Create the TAP TO BEGIN label
        let tapLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tapLabel.text = "TAP TO BEGIN"
        tapLabel.fontSize = 32
        tapLabel.fontColor = .white
        tapLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        tapLabel.name = "tapToBegin"
        
        // Add new button above tap to begin
        let newLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        newLabel.text = "TOP 10 CHAMPS"
        newLabel.fontSize = 32
        newLabel.fontColor = .white
        newLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.28)
        newLabel.name = "highScoresButton"
        
        // Add help label below tap to begin
        let helpLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        helpLabel.text = "HELP"
        helpLabel.fontSize = 32
        helpLabel.fontColor = .white
        helpLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.12)
        helpLabel.name = "helpButton"
        
        // Create background for TAP TO BEGIN
        let tapPadding: CGFloat = 20
        let tapCornerRadius: CGFloat = 10
        let tapBackgroundSize = CGSize(
            width: tapLabel.frame.width + tapPadding * 2,
            height: tapLabel.frame.height + tapPadding
        )
        let tapBackground = SKShapeNode(
            rect: CGRect(
                x: -tapBackgroundSize.width/2,
                y: -tapBackgroundSize.height/2,
                width: tapBackgroundSize.width,
                height: tapBackgroundSize.height
            ),
            cornerRadius: tapCornerRadius
        )
        tapBackground.fillColor = .black
        tapBackground.strokeColor = .clear
        tapBackground.position = CGPoint(x: frame.midX, y: frame.height * 0.2 + tapLabel.frame.height/2)
        tapBackground.alpha = 0
        addChild(tapBackground)
        
        // Create background for new button
        let newPadding: CGFloat = 20
        let newCornerRadius: CGFloat = 10
        let newBackgroundSize = CGSize(
            width: newLabel.frame.width + newPadding * 2,
            height: newLabel.frame.height + newPadding
        )
        let newBackground = SKShapeNode(
            rect: CGRect(
                x: -newBackgroundSize.width/2,
                y: -newBackgroundSize.height/2,
                width: newBackgroundSize.width,
                height: newBackgroundSize.height
            ),
            cornerRadius: newCornerRadius
        )
        newBackground.fillColor = .black
        newBackground.strokeColor = .clear
        newBackground.position = CGPoint(x: frame.midX, y: frame.height * 0.28 + newLabel.frame.height/2)
        newBackground.alpha = 0
        addChild(newBackground)
        
        // Create background for HELP
        let helpPadding: CGFloat = 20
        let helpCornerRadius: CGFloat = 10
        let helpBackgroundSize = CGSize(
            width: helpLabel.frame.width + helpPadding * 2,
            height: helpLabel.frame.height + helpPadding
        )
        let helpBackground = SKShapeNode(
            rect: CGRect(
                x: -helpBackgroundSize.width/2,
                y: -helpBackgroundSize.height/2,
                width: helpBackgroundSize.width,
                height: helpBackgroundSize.height
            ),
            cornerRadius: helpCornerRadius
        )
        helpBackground.fillColor = .black
        helpBackground.strokeColor = .clear
        helpBackground.position = CGPoint(x: frame.midX, y: frame.height * 0.12 + helpLabel.frame.height/2)
        helpBackground.alpha = 0
        addChild(helpBackground)
        
        // Add labels after backgrounds
        tapLabel.alpha = 0
        newLabel.alpha = 0
        helpLabel.alpha = 0
        addChild(tapLabel)
        addChild(newLabel)
        addChild(helpLabel)
        
        // Animate labels and backgrounds
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let tapPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        
        let newPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        
        let helpPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        
        tapLabel.run(SKAction.sequence([
            fadeIn,
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(tapPulse)
        ]))
        
        newLabel.run(SKAction.sequence([
            fadeIn,
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(newPulse)
        ]))
        
        helpLabel.run(SKAction.sequence([
            fadeIn,
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(helpPulse)
        ]))
        
        tapBackground.run(SKAction.fadeIn(withDuration: 0.5))
        newBackground.run(SKAction.fadeIn(withDuration: 0.5))
        helpBackground.run(SKAction.fadeIn(withDuration: 0.5))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if helpOverlay != nil {
            hideHelpScreen()
            return
        }
        
        if highScoresOverlay != nil {
            hideHighScores()
            return
        }
        
        // Check if help button was tapped
        if let helpButton = childNode(withName: "helpButton") as? SKLabelNode,
           helpButton.frame.contains(location) {
            showHelpScreen()
            return
        }
        
        // Check if high scores button was tapped
        if let highScoresButton = childNode(withName: "highScoresButton") as? SKLabelNode,
           highScoresButton.frame.contains(location) {
            showHighScores()
            return
        }
        
        // Check if tap to begin was tapped
        if let tapToBegin = childNode(withName: "tapToBegin") as? SKLabelNode,
           tapToBegin.frame.contains(location) {
            // Add a quick fade out transition
            run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.run { [weak self] in
                    self?.onStartGame?()
                }
            ]))
        }
    }
    
    private func showHighScores() {
        // Create the overlay node
        let overlay = SKNode()
        
        // Add semi-transparent black background
        let background = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.fillColor = .black
        background.strokeColor = .clear
        background.alpha = 0.9
        overlay.addChild(background)
        
        // Create content container for centered alignment
        let container = SKNode()
        container.position = CGPoint(x: size.width/2, y: size.height/2 + 50)
        container.name = "container"  // Add name for easy lookup
        overlay.addChild(container)
        
        // Add HIGH SCORES title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "TOP 10 CHAMPS"
        titleLabel.fontSize = 46
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 200)
        container.addChild(titleLabel)
        
        // Add loading indicator initially
        let loadingLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        loadingLabel.text = "Loading scores..."
        loadingLabel.fontSize = 24
        loadingLabel.fontColor = .white
        loadingLabel.position = CGPoint(x: 0, y: 0)
        loadingLabel.name = "loadingLabel"
        container.addChild(loadingLabel)
        
        // Add tap anywhere to return text
        let returnLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        returnLabel.text = "TAP ANYWHERE TO RETURN"
        returnLabel.fontSize = 24
        returnLabel.fontColor = .white
        returnLabel.position = CGPoint(x: 0, y: -350)
        container.addChild(returnLabel)
        
        // Add fade in animation
        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
        
        // Position the overlay
        overlay.zPosition = 100
        
        // Add to scene and store reference
        addChild(overlay)
        highScoresOverlay = overlay
        
        // Load scores with completion handler
        HighScoreManager.shared.loadScores { [weak self] scores in
            guard let self = self,
                  let container = self.highScoresOverlay?.children.first(where: { $0.name == "container" }) as? SKNode else { return }
            
            // Remove loading label
            container.children.filter { $0.name == "loadingLabel" }.forEach { $0.removeFromParent() }
            
            if !scores.isEmpty {
                // Show the scores
                self.showHighScoresTable(in: container, startingY: 100)
            } else {
                // Show no scores message
                let noScoresLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
                noScoresLabel.text = "No high scores yet!"
                noScoresLabel.fontSize = 24
                noScoresLabel.fontColor = .white
                noScoresLabel.position = CGPoint(x: 0, y: 0)
                noScoresLabel.name = "highScore" // Use highScore name so it gets cleaned up properly
                container.addChild(noScoresLabel)
            }
        }
    }
    
    private func showHighScoresTable(in container: SKNode, startingY: CGFloat) {
        let scores = HighScoreManager.shared.highScores.prefix(10)
        
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
    
    private func hideHighScores() {
        highScoresOverlay?.removeFromParent()
        highScoresOverlay = nil
    }
} 