struct LearningRecommendation {
    enum RecommendationType {
        case review
        case practice
        case general
    }
    
    enum Priority {
        case high
        case medium
        case low
    }
    
    let type: RecommendationType
    let message: String
    let priority: Priority
    let words: [Word]
}

struct LearningStatsData {
    var averageAccuracy: Double = 0
    var averageInterval: Double = 0
    var averageDifficulty: Double = 0
    var weeklyReviewCount: Int = 0
    var weeklyCorrectCount: Int = 0
    
    var weeklyAccuracy: Double {
        guard weeklyReviewCount > 0 else { return 0 }
        return Double(weeklyCorrectCount) / Double(weeklyReviewCount)
    }
}