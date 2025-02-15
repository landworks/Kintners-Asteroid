import SpriteKit
import GameplayKit

// ... existing code ...

// For the "zero" errors, you need to use CGPoint.zero instead
// Replace instances like this:
let position = CGPoint.zero

// For the GameState references, make sure you're using the enum properly
// Example fixes:
if gameState == .playing {
    // ... existing code ...
}

if gameState == .gameOver {
    // ... existing code ...
}

// For Player references, make sure you're using the enum
let currentPlayer: Player = .one

// ... existing code ...

// Define these enums at the top of the class if they're not in a separate file
enum Player {
    case one
}

enum GameState {
    case playing
    case gameOver
}

// For lines 197, 402, 408, 418, 878 where it can't infer 'playing'
if gameState == GameState.playing {
    // ... existing code ...
}

// For lines 444, 660 where it can't infer 'gameOver'
if gameState == GameState.gameOver {
    // ... existing code ...
}

// For line 251 where it can't find Player
let player = Player.one

// ... existing code ... 