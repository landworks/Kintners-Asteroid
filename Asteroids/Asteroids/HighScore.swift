import Foundation

struct HighScore: Codable, Comparable {
    let name: String
    let score: Int
    let date: Date
    
    static func < (lhs: HighScore, rhs: HighScore) -> Bool {
        return lhs.score > rhs.score // Higher scores first
    }
}

class HighScoreManager {
    static let shared = HighScoreManager()
    private let maxScores = 10
    private let defaults = UserDefaults.standard
    private let highScoresKey = "highScores"
    
    var highScores: [HighScore] {
        get {
            guard let data = defaults.data(forKey: highScoresKey),
                  let scores = try? JSONDecoder().decode([HighScore].self, from: data) else {
                return []
            }
            return scores
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: highScoresKey)
            }
        }
    }
    
    func addScore(_ name: String, score: Int) {
        var scores = highScores
        let newScore = HighScore(name: name, score: score, date: Date())
        scores.append(newScore)
        scores.sort()
        scores = Array(scores.prefix(maxScores))
        highScores = scores
        
        // Force immediate save
        defaults.synchronize()
    }
    
    func isHighScore(_ score: Int) -> Bool {
        let scores = highScores
        if scores.count < maxScores { return true }
        return score > scores.last?.score ?? 0
    }
    
    // Add function to clear scores (for testing)
    func clearScores() {
        defaults.removeObject(forKey: highScoresKey)
        defaults.synchronize()
    }
} 