import Foundation
import CoreData
import SwiftUI

class StatsViewModel: ObservableObject {
    @Published var totalAccuracy: Double = 0
    @Published var totalWords: Int = 0
    @Published var consecutiveDays: Int = 0
    @Published var weeklyProgress: [Double] = Array(repeating: 0, count: 7)
    @Published var difficultWords: [DifficultWord] = []
    @Published var errorTypeStats: [ErrorTypeStat] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        print("StatsViewModel 初始化开始")
        self.context = context
        
        // 设置初始测试数据
        print("设置测试数据")
        self.totalWords = 10
        self.totalAccuracy = 0.85
        self.consecutiveDays = 5
        self.weeklyProgress = [0.3, 0.5, 0.8, 0.4, 0.6, 0.9, 0.7]
        self.difficultWords = [
            DifficultWord(english: "example", chinese: "示例", errorRate: 0.8),
            DifficultWord(english: "test", chinese: "测试", errorRate: 0.6)
        ]
        self.errorTypeStats = [
            ErrorTypeStat(type: .typo, percentage: 0.4),
            ErrorTypeStat(type: .missing, percentage: 0.3),
            ErrorTypeStat(type: .extra, percentage: 0.2),
            ErrorTypeStat(type: .wrong, percentage: 0.1)
        ]
        
        print("开始加载实际数据")
        loadStats()
        print("数据加载完成")
    }
    
    func loadStats() {
        print("=== 开始加载统计数据 ===")
        loadTotalStats()
        loadWeeklyProgress()
        loadDifficultWords()
        loadErrorTypeStats()
        print("=== 统计数据加载完成 ===")
        print("总单词：\(totalWords)")
        print("正确率：\(totalAccuracy)")
        print("难词数量：\(difficultWords.count)")
    }
    
    private func loadTotalStats() {
        let fetchRequest: NSFetchRequest<WordResult> = WordResult.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            let totalAttempts = results.count
            let correctAttempts = results.filter { $0.isCorrect }.count
            
            totalAccuracy = totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0
            totalWords = try context.count(for: Word.fetchRequest())
            consecutiveDays = calculateConsecutiveDays(from: results)
        } catch {
            print("加载总体统计失败: \(error)")
        }
    }
    
    private func loadWeeklyProgress() {
        let calendar = Calendar.current
        let now = Date()
        
        weeklyProgress = (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { return 0 }
            return calculateDailyAccuracy(for: date)
        }.reversed()
    }
    
    private func loadDifficultWords() {
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        
        do {
            let words = try context.fetch(fetchRequest)
            difficultWords = words.compactMap { word in
                let results = word.wordResults?.allObjects as? [WordResult] ?? []
                let totalAttempts = results.count
                let errorCount = results.filter { !$0.isCorrect }.count
                
                guard totalAttempts > 0 else { return nil }
                let errorRate = Double(errorCount) / Double(totalAttempts)
                
                return errorRate > 0 ? DifficultWord(
                    english: word.english ?? "",
                    chinese: word.chinese ?? "",
                    errorRate: errorRate
                ) : nil
            }
            .sorted(by: { $0.errorRate > $1.errorRate })
            .prefix(5)
            .map { $0 }
        } catch {
            print("加载易错单词失败: \(error)")
        }
    }
    
    private func loadErrorTypeStats() {
        let fetchRequest: NSFetchRequest<WordResult> = WordResult.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCorrect == NO")
        
        do {
            let results = try context.fetch(fetchRequest)
            var typeCounts: [SpellingErrorType: Int] = [:]
            
            results.forEach { result in
                if let errorTypes = result.errorTypes as? [String] {
                    errorTypes.forEach { errorTypeString in
                        if let errorTypeInt = Int16(errorTypeString),
                           let type = SpellingErrorType(rawValue: errorTypeInt) {
                            typeCounts[type, default: 0] += 1
                        } else {
                            typeCounts[.other, default: 0] += 1
                        }
                    }
                }
            }
            
            let total = Double(results.count)
            errorTypeStats = SpellingErrorType.allCases.map { type in
                let count = Double(typeCounts[type] ?? 0)
                return ErrorTypeStat(type: type, percentage: total > 0 ? count / total : 0)
            }
        } catch {
            print("加载错误类型统计失败: \(error)")
        }
    }
    
    private func calculateDailyAccuracy(for date: Date) -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        
        let fetchRequest: NSFetchRequest<WordResult> = WordResult.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            let totalAttempts = results.count
            let correctAttempts = results.filter { $0.isCorrect }.count
            
            return totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0
        } catch {
            print("计算每日正确率失败: \(error)")
            return 0
        }
    }
    
    private func calculateConsecutiveDays(from results: [WordResult]) -> Int {
        let calendar = Calendar.current
        let dates = Set(results.compactMap { result in
            calendar.startOfDay(for: result.date ?? Date())
        })
        
        var consecutiveDays = 0
        let today = calendar.startOfDay(for: Date())
        
        for dayOffset in 0... {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  dates.contains(date) else {
                break
            }
            consecutiveDays += 1
        }
        
        return consecutiveDays
    }
    
    @Published var practiceMode: PracticeViewModel.PracticeMode = .none
    
    func startPractice(word: DifficultWord) -> some View {
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "english == %@", word.english)
        
        do {
            if let wordEntity = try context.fetch(fetchRequest).first {
                practiceMode = .single
                return AnyView(SpellingPracticeView(
                    viewModel: SpellingPracticeViewModel(
                        words: [wordEntity],
                        mode: .single
                    )
                ))
            }
        } catch {
            print("获取练习单词失败: \(error)")
        }
        
        return AnyView(EmptyView())
    }
    
    private func calculateStats(for words: [Word], date: Date) -> LearningStats {
        let stats = LearningStats(context: context)  // 使用 context 而不是 viewContext
        stats.id = UUID()
        stats.date = date
        
        // 获取当天的学习记录
        let calendar = Calendar.current
        let results = words.flatMap { word in
            (word.wordResults?.allObjects as? [WordResult] ?? []).filter { result in
                calendar.isDate(result.date ?? Date(), inSameDayAs: date)
            }
        }
        
        // 计算正确和错误数量
        let correctCount = results.filter { $0.isCorrect }.count
        stats.correctCount = Int16(correctCount)
        
        // 计算新学单词数（当天首次学习的单词）
        let newWords = words.filter { word in
            guard let firstResult = (word.wordResults?.allObjects as? [WordResult] ?? [])
                .min(by: { ($0.date ?? Date()) < ($1.date ?? Date()) }) else {
                return false
            }
            return calendar.isDate(firstResult.date ?? Date(), inSameDayAs: date)
        }
        stats.newWordsCount = Int16(newWords.count)
        
        // 计算已掌握的单词数
        let masteredWords = words.filter { word in
            let results = word.wordResults?.allObjects as? [WordResult] ?? []
            let recentResults = results.filter { result in
                if let resultDate = result.date {
                    return resultDate <= date
                }
                return false
            }
            // 连续答对3次以上视为掌握
            let lastThreeResults = Array(recentResults.prefix(3))
            return lastThreeResults.count >= 3 && lastThreeResults.allSatisfy { $0.isCorrect }
        }
        stats.masteredCount = Int16(masteredWords.count)
        
        return stats
    }
}