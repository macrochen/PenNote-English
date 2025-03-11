import Foundation
import CoreData

class PracticeViewModel: ObservableObject {
    private let viewContext = PersistenceController.shared.container.viewContext
    @Published var selectedWords: [Word] = []
    @Published var currentPracticeMode: PracticeMode = .none
    
    enum PracticeMode {
        case none
        case batch
        case single
    }
    
    func fetchWords(count: Int, range: String) -> [Word] {
        let request = Word.fetchRequest()
        
        // 根据练习范围设置查询条件
        switch range {
        case "待复习":
            request.predicate = NSPredicate(format: "status == %d", 1) // 假设status 1表示待复习
        case "易错词":
            request.predicate = NSPredicate(format: "errorCount > 0")
        default:
            break // 所有单词
        }
        
        // 随机排序
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Word.createdAt, ascending: true)]
        request.fetchLimit = count
        
        do {
            let words = try viewContext.fetch(request)
            // 如果获取的单词数量不足，返回所有获取到的单词
            return words.shuffled()
        } catch {
            print("获取单词失败: \(error)")
            return []
        }
    }
    
    func startBatchPractice(wordCount: Int, range: String) {
        selectedWords = fetchWords(count: wordCount, range: range)
        currentPracticeMode = .batch
    }
    
    func startSinglePractice(wordCount: Int, range: String) {
        selectedWords = fetchWords(count: wordCount, range: range)
        currentPracticeMode = .single
    }
    
    func saveWordResult(word: Word, isCorrect: Bool, errorTypes: [SpellingErrorType] = []) {
        let record = ReviewRecord(context: viewContext)
        record.id = UUID()
        record.word = word
        record.isCorrect = isCorrect
        record.reviewDate = Date()
        record.memoryStrength = 0.0
        record.reviewInterval = 0.0
        record.errorType = errorTypes.first?.rawValue ?? 0
        
        word.reviewCount += 1
        if isCorrect {
            word.correctCount += 1
        } else {
            word.errorCount += 1
        }
        
        updateWordStatus(word: word)
        
        do {
            try viewContext.save()
        } catch {
            print("保存练习结果失败: \(error)")
        }
    }
    
    private func updateWordStatus(word: Word) {
        // 根据正确率和复习次数更新单词状态
        let correctRate = Double(word.correctCount) / Double(word.reviewCount)
        if correctRate >= 0.8 && word.reviewCount >= 5 {
            word.status = 2 // 已掌握
        } else if correctRate < 0.6 {
            word.status = 1 // 需要复习
        }
    }
    
    func saveBatchResults(results: [String: Bool]) {
        for word in selectedWords {
            if let isCorrect = results[word.english ?? ""] {
                saveWordResult(word: word, isCorrect: isCorrect)
            }
        }
    }
}