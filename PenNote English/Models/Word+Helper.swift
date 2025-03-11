import Foundation
import CoreData

public extension Word {
    // 复习状态
    var needsReview: Bool {
        if let lastReview = updatedAt {
            let calendar = Calendar.current
            return calendar.isDateInToday(lastReview) || 
                   calendar.isDateInYesterday(lastReview)
        }
        return false
    }
    
    // 更新复习状态
    func updateReviewStatus(correct: Bool) {
        let context = self.managedObjectContext
        self.updatedAt = Date()
        
        // 创建新的复习记录
        let record = ReviewRecord(context: context!)
        record.id = UUID()
        record.reviewDate = Date()
        record.isCorrect = correct
        record.word = self
        
        // 更新错误计数
        if !correct {
            self.errorCount += 1
        }
        
        // 更新单词状态
        if let records = self.reviewRecords?.allObjects as? [ReviewRecord] {
            let totalReviews = records.count
            let correctReviews = records.filter { $0.isCorrect }.count
            
            // 根据复习情况更新状态
            if totalReviews >= 5 && Float(correctReviews) / Float(totalReviews) > 0.8 {
                self.status = 2  // 已掌握
            } else {
                self.status = 1  // 学习中
            }
        }
        
        try? context?.save()
    }
    
    // 其他辅助方法
    var reviewProgress: Float {
        guard let records = reviewRecords?.allObjects as? [ReviewRecord],
              !records.isEmpty else { return 0 }
        
        let correctReviews = records.filter { $0.isCorrect }.count
        return Float(correctReviews) / Float(records.count)
    }
    
    var statusText: String {
        switch status {
        case 0: return "未学习"
        case 1: return "学习中"
        case 2: return "已掌握"
        default: return "未知"
        }
    }
}