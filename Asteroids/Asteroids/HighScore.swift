import Foundation
import CloudKit

// Add notification name at the top
extension Notification.Name {
    static let highScoresDidUpdate = Notification.Name("highScoresDidUpdate")
    static let cloudKitStatusDidChange = Notification.Name("cloudKitStatusDidChange")
    static let cloudKitError = Notification.Name("cloudKitError")
}

struct HighScore: Codable, Comparable {
    let name: String
    let score: Int
    let date: Date
    var recordID: CKRecord.ID?
    var source: ScoreSource
    
    enum ScoreSource: String, Codable {
        case local
        case cloudKit
    }
    
    static func < (lhs: HighScore, rhs: HighScore) -> Bool {
        return lhs.score > rhs.score // Higher scores first
    }
    
    init(name: String, score: Int, date: Date = Date(), recordID: CKRecord.ID? = nil, source: ScoreSource = .local) {
        self.name = name
        self.score = score
        self.date = date
        self.recordID = recordID
        self.source = source
        print("HighScore created: name=\(name), score=\(score), date=\(date), source=\(source)")
    }
    
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let score = record["score"] as? Int,
              let date = record["date"] as? Date else {
            print("Failed to create HighScore from record: \(record.recordType)")
            print("Values: name=\(String(describing: record["name"])), score=\(String(describing: record["score"])), date=\(String(describing: record["date"]))")
            return nil
        }
        
        self.name = name
        self.score = score
        self.date = date
        self.recordID = record.recordID
        self.source = .cloudKit
        print("HighScore created from record: name=\(name), score=\(score), date=\(date), recordID=\(record.recordID.recordName)")
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "HighScore")
        record["name"] = name
        record["score"] = score
        record["date"] = date
        print("Created CKRecord: recordID=\(record.recordID.recordName), name=\(name), score=\(score), date=\(date)")
        return record
    }
    
    // Add Codable conformance
    enum CodingKeys: String, CodingKey {
        case name, score, date, source
        case recordID
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        score = try container.decode(Int.self, forKey: .score)
        date = try container.decode(Date.self, forKey: .date)
        source = try container.decode(ScoreSource.self, forKey: .source)
        // recordID is optional and might not be present when decoding
        recordID = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(score, forKey: .score)
        try container.encode(date, forKey: .date)
        try container.encode(source, forKey: .source)
        // We don't encode recordID as it's only used internally
    }
}

class HighScoreManager {
    static let shared = HighScoreManager()
    private let maxScores = 10
    private let container: CKContainer
    private let database: CKDatabase
    private var cachedScores: [HighScore] = []
    private var isLoading = false
    private var loadCompletionHandlers: [(([HighScore]) -> Void)] = []
    
    // Add properties for CloudKit status and local storage
    private var isCloudAvailable = false {
        didSet {
            if oldValue != isCloudAvailable {
                print("☁️ CloudKit availability changed: \(isCloudAvailable)")
                NotificationCenter.default.post(name: .cloudKitStatusDidChange, object: nil)
            }
        }
    }
    private let userDefaults = UserDefaults.standard
    private let localScoresKey = "localHighScores"
    private var lastSyncTime: Date? {
        get { userDefaults.object(forKey: "lastSyncTime") as? Date }
        set { userDefaults.set(newValue, forKey: "lastSyncTime") }
    }
    
    private var cloudRetryCount = 0
    private let maxCloudRetries = 3
    
    private init() {
        print("\n=== Initializing HighScoreManager ===")
        self.container = CKContainer.default()
        self.database = container.publicCloudDatabase
        print("Using CloudKit container: \(container.containerIdentifier ?? "unknown")")
        
        // Load local scores immediately
        loadLocalScores()
        
        // Check CloudKit availability
        checkCloudKitAvailability()
        
        // Set up periodic CloudKit status check (every 5 minutes)
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkCloudKitAvailability()
        }
    }
    
    private func checkCloudKitAvailability() {
        print("\n=== Checking CloudKit Availability ===")
        container.accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let wasAvailable = self.isCloudAvailable
                
                switch status {
                case .available:
                    print("✅ CloudKit is available")
                    self.isCloudAvailable = true
                case .noAccount:
                    print("❌ No iCloud account")
                    self.isCloudAvailable = false
                case .restricted:
                    print("❌ iCloud is restricted")
                    self.isCloudAvailable = false
                case .couldNotDetermine:
                    print("❌ Could not determine iCloud status")
                    self.isCloudAvailable = false
                case .temporarilyUnavailable:
                    print("❌ CloudKit temporarily unavailable")
                    self.isCloudAvailable = false
                @unknown default:
                    print("❌ Unknown iCloud status")
                    self.isCloudAvailable = false
                }
                
                if let error = error {
                    print("❌ CloudKit status error: \(self.getDetailedErrorDescription(error))")
                    self.notifyError(error)
                }
                
                if self.isCloudAvailable && !wasAvailable {
                    print("🔄 CloudKit became available, syncing data")
                    self.syncWithCloud()
                }
            }
        }
    }
    
    private func notifyError(_ error: Error) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .cloudKitError,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }
    
    private func loadLocalScores() {
        print("\n=== Loading Local Scores ===")
        if let data = userDefaults.data(forKey: localScoresKey),
           let scores = try? JSONDecoder().decode([HighScore].self, from: data) {
            print("📱 Loaded \(scores.count) scores from local storage")
            self.cachedScores = scores.sorted()
            scores.forEach { score in
                print("- \(score.name): \(score.score) (\(score.source))")
            }
        } else {
            print("📱 No scores found in local storage")
            self.cachedScores = []
        }
    }
    
    private func saveLocalScores() {
        print("\n=== Saving Local Scores ===")
        if let data = try? JSONEncoder().encode(cachedScores) {
            userDefaults.set(data, forKey: localScoresKey)
            print("📱 Saved \(cachedScores.count) scores to local storage")
            cachedScores.forEach { score in
                print("- \(score.name): \(score.score) (\(score.source))")
            }
        } else {
            print("❌ Failed to encode scores for local storage")
        }
    }
    
    private func syncWithCloud() {
        print("\n=== Syncing with CloudKit ===")
        guard isCloudAvailable else {
            print("☁️ CloudKit not available, using local storage only")
            return
        }
        
        loadScores()
    }
    
    var highScores: [HighScore] {
        get {
            print("\n=== Getting High Scores ===")
            print("Returning \(cachedScores.count) cached scores")
            return cachedScores.sorted()
        }
    }
    
    func loadScores(_ completion: @escaping ([HighScore]) -> Void) {
        print("\n=== Loading Scores ===")
        if isCloudAvailable {
            print("☁️ Loading from CloudKit")
            isLoading = false
            loadCompletionHandlers.append(completion)
            loadScores()
        } else {
            print("📱 Using local scores (CloudKit unavailable)")
            completion(cachedScores.sorted())
        }
    }
    
    private func loadScores() {
        guard !isLoading else {
            print("⏳ Already loading scores, skipping")
            return
        }
        
        print("\n=== Loading Scores from CloudKit ===")
        isLoading = true
        
        let query = CKQuery(recordType: "HighScore", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = maxScores
        
        var loadedScores: [HighScore] = []
        
        operation.recordMatchedBlock = { [weak self] (_, result) in
            switch result {
            case .success(let record):
                if let score = HighScore(from: record) {
                    loadedScores.append(score)
                    print("✅ Loaded score: \(score.name) - \(score.score)")
                }
            case .failure(let error):
                let errorDescription = self?.getDetailedErrorDescription(error) ?? error.localizedDescription
                print("❌ Error loading record: \(errorDescription)")
                self?.notifyError(error)
            }
        }
        
        operation.queryResultBlock = { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if !loadedScores.isEmpty {
                        print("✅ Successfully loaded \(loadedScores.count) scores from CloudKit")
                        
                        // Merge cloud scores with local scores
                        self.mergeCloudScores(loadedScores)
                        
                        // Update last sync time
                        self.lastSyncTime = Date()
                        
                        // Save merged scores locally
                        self.saveLocalScores()
                        
                        // Notify observers
                        print("📢 Posting highScoresDidUpdate notification")
                        NotificationCenter.default.post(name: .highScoresDidUpdate, object: nil)
                    } else {
                        print("ℹ️ No scores found in CloudKit")
                    }
                    
                case .failure(let error):
                    print("❌ Error loading scores from CloudKit: \(self.getDetailedErrorDescription(error))")
                    self.notifyError(error)
                    
                    // On error, use local cache
                    print("📱 Using local cache due to CloudKit error")
                }
                
                // Notify completion handlers
                print("🔔 Notifying \(self.loadCompletionHandlers.count) completion handlers")
                let sortedScores = self.cachedScores.sorted()
                self.loadCompletionHandlers.forEach { $0(sortedScores) }
                self.loadCompletionHandlers.removeAll()
                
                self.isLoading = false
            }
        }
        
        database.add(operation)
    }
    
    private func mergeCloudScores(_ cloudScores: [HighScore]) {
        print("\n=== Merging Cloud Scores ===")
        
        // Keep track of local-only scores
        let localOnlyScores = cachedScores.filter { $0.source == .local }
        print("📱 Found \(localOnlyScores.count) local-only scores")
        
        // Combine cloud scores with local-only scores
        var allScores = cloudScores
        allScores.append(contentsOf: localOnlyScores)
        
        // Sort and limit to max scores
        cachedScores = Array(allScores.sorted().prefix(maxScores))
        
        print("✅ Merged scores count: \(cachedScores.count)")
        cachedScores.forEach { score in
            print("- \(score.name): \(score.score) (\(score.source))")
        }
    }
    
    func addScore(_ name: String, score: Int) {
        print("\n=== Adding New High Score ===")
        print("Adding score: \(name) - \(score)")
        
        // Create the new score
        let newScore = HighScore(name: name, score: score, source: .local)
        
        // Update local cache and storage
        self.cachedScores.append(newScore)
        self.cachedScores.sort()
        
        // Keep only top scores
        if self.cachedScores.count > self.maxScores {
            self.cachedScores = Array(self.cachedScores.prefix(self.maxScores))
        }
        
        // Save locally first
        saveLocalScores()
        
        // Create and save CloudKit record if available
        if isCloudAvailable {
            print("☁️ Saving score to CloudKit")
            let record = newScore.toCKRecord()
            container.publicCloudDatabase.save(record) { [weak self] record, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error saving score to CloudKit: \(self.getDetailedErrorDescription(error))")
                        self.notifyError(error)
                        
                        // Schedule a retry if it's a network error
                        if let ckError = error as? CKError,
                           ckError.code == .serviceUnavailable || ckError.code == .networkUnavailable {
                            self.scheduleCloudKitRetry()
                        }
                    } else {
                        print("✅ Successfully saved score to CloudKit")
                        // Update the score's source and record ID
                        if let index = self.cachedScores.firstIndex(where: { $0.name == name && $0.score == score }) {
                            let updatedScore = HighScore(name: name, score: score, date: newScore.date, recordID: record?.recordID, source: .cloudKit)
                            self.cachedScores[index] = updatedScore
                            self.saveLocalScores()
                        }
                        // Update last sync time
                        self.lastSyncTime = Date()
                    }
                }
            }
        } else {
            print("☁️ CloudKit not available, score saved locally only")
        }
        
        // Notify UI immediately with our updated cache
        print("📊 Updated cached scores:")
        self.cachedScores.forEach { score in
            print("- \(score.name): \(score.score) (\(score.source))")
        }
        NotificationCenter.default.post(name: .highScoresDidUpdate, object: nil)
    }
    
    private func scheduleCloudKitRetry() {
        guard cloudRetryCount < maxCloudRetries else {
            print("❌ Maximum retry attempts reached")
            cloudRetryCount = 0
            return
        }
        
        cloudRetryCount += 1
        let delay = TimeInterval(pow(2.0, Double(cloudRetryCount))) // Exponential backoff
        print("🔄 Scheduling retry attempt \(cloudRetryCount) in \(delay) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.syncWithCloud()
        }
    }
    
    func isHighScore(_ score: Int) -> Bool {
        print("\n=== Checking High Score ===")
        print("Checking if \(score) is a high score")
        let scores = highScores
        if scores.count < maxScores {
            print("✅ Less than \(maxScores) scores, \(score) is a high score")
            return true
        }
        let isHigh = score > scores.last?.score ?? 0
        print("\(score) is\(isHigh ? "" : " not") a high score (current lowest: \(scores.last?.score ?? 0))")
        return isHigh
    }
    
    func clearScores() {
        print("\n=== Clearing All Scores ===")
        
        // Clear local scores
        cachedScores = []
        saveLocalScores()
        
        // Clear CloudKit scores if available
        if isCloudAvailable {
            let query = CKQuery(recordType: "HighScore", predicate: NSPredicate(value: true))
            
            if #available(iOS 15.0, *) {
                database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { [weak self] result in
                    switch result {
                    case .success(let (matchResults, _)):
                        let records: [CKRecord] = matchResults.compactMap { try? $0.1.get() }
                        print("🗑️ Deleting \(records.count) CloudKit records")
                        
                        let deleteOperations = records.map { CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [$0.recordID]) }
                        deleteOperations.forEach { operation in
                            operation.modifyRecordsResultBlock = { result in
                                switch result {
                                case .success:
                                    print("✅ Successfully deleted CloudKit record")
                                case .failure(let error):
                                    print("❌ Error deleting CloudKit record: \(error.localizedDescription)")
                                    self?.notifyError(error)
                                }
                            }
                            self?.database.add(operation)
                        }
                    case .failure(let error):
                        print("❌ Error fetching records to delete: \(error.localizedDescription)")
                        self?.notifyError(error)
                    }
                }
            } else {
                // Fallback for iOS 14 and earlier
                database.perform(query, inZoneWith: nil) { [weak self] records, error in
                    guard let records = records else {
                        print("❌ Error fetching records to delete: \(error?.localizedDescription ?? "unknown error")")
                        return
                    }
                    
                    print("🗑️ Deleting \(records.count) CloudKit records")
                    
                    let deleteOperations = records.map { CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [$0.recordID]) }
                    deleteOperations.forEach { operation in
                        operation.modifyRecordsResultBlock = { result in
                            switch result {
                            case .success:
                                print("✅ Successfully deleted CloudKit record")
                            case .failure(let error):
                                print("❌ Error deleting CloudKit record: \(error.localizedDescription)")
                                self?.notifyError(error)
                            }
                        }
                        self?.database.add(operation)
                    }
                }
            }
        }
        
        // Notify observers
        NotificationCenter.default.post(name: .highScoresDidUpdate, object: nil)
        print("✅ All scores cleared")
    }
    
    private func getDetailedErrorDescription(_ error: Error) -> String {
        if let ckError = error as? CKError {
            let errorMessage = "CloudKit Error: \(ckError.localizedDescription)"
            if let underlyingError = ckError.userInfo[NSUnderlyingErrorKey] as? NSError {
                return "\(errorMessage)\nDetails: \(underlyingError.localizedDescription)"
            }
            return errorMessage
        }
        return error.localizedDescription
    }
} 