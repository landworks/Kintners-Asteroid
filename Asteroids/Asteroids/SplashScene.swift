import SpriteKit

class SplashScene: SKScene {
    var onStartGame: (() -> Void)?
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupTapToBegin()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "SplashBackground")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.size = frame.size
        background.zPosition = -10
        addChild(background)
    }
    
    private func setupTapToBegin() {
        let tapLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        tapLabel.text = "TAP TO BEGIN"
        tapLabel.fontSize = 32
        tapLabel.fontColor = .white
        tapLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        tapLabel.alpha = 0
        addChild(tapLabel)
        
        // Animate tap label
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])
        
        tapLabel.run(SKAction.sequence([
            fadeIn,
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(pulse)
        ]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Add a quick fade out transition
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.run { [weak self] in
                self?.onStartGame?()
            }
        ]))
    }
} 