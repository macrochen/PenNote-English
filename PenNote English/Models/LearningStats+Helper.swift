import Foundation

extension LearningStats {
    var accuracyRate: Double {
        return reviewedCount > 0 ? Double(correctCount) / Double(reviewedCount) : 0
    }
    
    var averageTimePerWord: Double {
        let totalWords = newWordsCount + reviewedCount
        return totalWords > 0 ? totalTime / Double(totalWords) : 0
    }
}