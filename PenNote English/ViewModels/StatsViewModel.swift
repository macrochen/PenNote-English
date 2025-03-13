import Foundation
import CoreData
import SwiftUI

/// StatsViewModel 负责管理应用的统计数据
/// 包括：总体统计、每日统计、连续学习天数、周进度、易错词等数据的计算和更新
class StatsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 总体正确率
    @Published var totalAccuracy: Double = 0
    /// 词库中的总单词数量
    @Published var totalWords = 0
    /// 已经练习过的单词数量（每个单词只计算一次）
    @Published var practiceWords = 0
    /// 最近一次练习错误的单词数量
    @Published var errorWords = 0
    /// 今天练习的单词数量（每个单词只计算一次）
    @Published var todayPracticeCount: Int = 0

    /// 连续学习天数
    @Published var consecutiveDays: Int = 0
    /// 最近7天的学习进度数组，每个元素代表当天的正确率
    @Published var weeklyProgress: [Double] = Array(repeating: 0, count: 7)
    /// 最常错误的5个单词
    @Published var difficultWords: [DifficultWord] = []
    /// 错误类型统计数据
    @Published var errorTypeStats: [ErrorTypeStat] = []
    
    // MARK: - Private Properties
    
    /// Core Data 上下文
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadStats()
    }
    
    // MARK: - Public Methods
    
    /// 加载所有统计数据
    /// 包括：总体统计、今日统计、连续天数、周进度、易错词、错误类型分析
    func loadStats() {
        print("=== 开始加载统计数据 ===")
        
        loadTotalWordsCount()
        loadOverallAccuracyStats()
        loadTodayPracticeCount()
        loadConsecutiveDays()
        
        loadWeeklyProgress()
        loadDifficultWords()
        loadErrorTypeStats()
        print("=== 统计数据加载完成 ===")
    }
    
    /// 加载词库中的总单词数
    private func loadTotalWordsCount() {
        let wordsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Word")
        totalWords = (try? context.count(for: wordsFetch)) ?? 0
    }
    
    /// 加载总体正确率统计数据
    private func loadOverallAccuracyStats() {
        let wordRequest = NSFetchRequest<Word>(entityName: "Word")
        do {
            let words = try context.fetch(wordRequest)
            let stats = calculateOverallStats(from: words)
            practiceWords = stats.practiced
            errorWords = stats.errors
            totalAccuracy = practiceWords > 0 ? Double(practiceWords - errorWords) / Double(practiceWords) : 0
        } catch {
            print("加载听写统计失败: \(error)")
        }
    }
    
    /// 加载今日练习单词数量
    private func loadTodayPracticeCount() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let todayFetch = NSFetchRequest<Word>(entityName: "Word")
        todayFetch.predicate = NSPredicate(
            format: "ANY wordResults.date >= %@",
            startOfDay as NSDate
        )
        
        todayPracticeCount = (try? context.count(for: todayFetch)) ?? 0
    }
    
    /// 加载连续学习天数
    private func loadConsecutiveDays() {
        do {
            let fetchRequest: NSFetchRequest<WordResult> = WordResult.fetchRequest()
            let results = try context.fetch(fetchRequest)
            consecutiveDays = calculateConsecutiveDays(from: results)
        } catch {
            print("加载连续天数失败: \(error)")
            consecutiveDays = 0
        }
    }

    /// 计算总体正确率和练习统计
    /// - Parameters:
    ///   - words: 所有单词数组
    /// - Returns: 包含练习数量和错误数量的元组
    private func calculateOverallStats(from words: [Word]) -> (practiced: Int, errors: Int) {
        var practicedCount = 0
        var errorCount = 0
        
        for word in words {
            if let results = word.wordResults?.allObjects as? [WordResult],
               let latestResult = results.max(by: { ($0.date ?? Date()) < ($1.date ?? Date()) }) {
                practicedCount += 1
                if !latestResult.isCorrect {
                    errorCount += 1
                }
            }
        }
        
        return (practicedCount, errorCount)
    }
    
    
    private func loadWeeklyProgress() {
        let calendar = Calendar.current
        let now = Date()
        // 获取本周的开始日期（周一）
        let weekday = calendar.component(.weekday, from: now)
        // 由于 Swift 的 Calendar 中周日是1，周一是2，所以需要调整偏移量
        let daysToMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysToMonday, to: now) else {
            return
        }
        
        // 从周一开始，获取一周的数据
        weeklyProgress = (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monday) else { return 0 }
            let accuracy = calculateDailyAccuracy(for: date)
            print("日期: \(date), 星期: \(calendar.component(.weekday, from: date)), 正确率: \(accuracy)")
            return accuracy
        }
    }
    
    /// 加载最常见的易错单词
    /// 处理流程：
    /// 1. 获取所有单词
    /// 2. 计算每个单词的错误率（错误次数/总尝试次数）
    /// 3. 筛选出错误率大于0的单词
    /// 4. 按错误率降序排序
    /// 5. 取前5个错误率最高的单词
    /// 
    /// 错误率计算方式：
    /// - 错误率 = 错误次数 / 总尝试次数
    /// - 只统计有练习记录的单词
    /// - 错误率为0的单词会被过滤掉
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
    
    /// 加载错误类型统计数据
    /// 统计所有错误的听写记录中各种拼写错误类型的分布情况
    /// 处理流程：
    /// 1. 获取所有错误的听写记录
    /// 2. 统计每种错误类型出现的次数
    /// 3. 计算每种错误类型的百分比
    /// 4. 更新 errorTypeStats 属性
    private func loadErrorTypeStats() {
        // 创建查询请求，只获取错误的听写记录
        let fetchRequest: NSFetchRequest<WordResult> = WordResult.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isCorrect == NO")
        
        do {
            // 获取所有错误记录
            let results = try context.fetch(fetchRequest)
            // 用字典记录每种错误类型的出现次数
            var typeCounts: [SpellingErrorType: Int] = [:]
            
            // 遍历每条错误记录
            results.forEach { result in
                // 获取该记录的错误类型数组
                if let errorTypes = result.errorTypes {
                    // 遍历每个错误类型字符串
                    errorTypes.forEach { errorTypeString in
                        // 将 errorTypeString 转换为 errorTypeInt
                        let errorType = SpellingErrorType.from(description: errorTypeString)
                        // 对应类型计数加1
                        typeCounts[errorType, default: 0] += 1
                    }
                }
            }
            
            // 计算错误记录总数（用于计算百分比）
            let total = Double(results.count)
            // 生成每种错误类型的统计数据
            errorTypeStats = SpellingErrorType.allCases.map { type in
                let count = Double(typeCounts[type] ?? 0)
                return ErrorTypeStat(
                    type: type,
                    count: 1,
                    percentage: total > 0 ? count / total : 0
                )
            }
        } catch {
            print("加载错误类型统计失败: \(error)")
        }
    }
    
    /// 计算指定日期的学习正确率
    /// - Parameter date: 要计算的日期
    /// - Returns: 该日期的正确率（0.0-1.0）
    private func calculateDailyAccuracy(for date: Date) -> Double {
        let calendar = Calendar.current
        // 获取指定日期的0点时间
        let startOfDay = calendar.startOfDay(for: date)
        
        // 创建查询请求，获取在指定日期有听写记录的单词
        let fetchRequest = NSFetchRequest<Word>(entityName: "Word")
        fetchRequest.predicate = NSPredicate(
            format: "ANY wordResults.date >= %@ AND ANY wordResults.date < %@",
            startOfDay as NSDate,
            calendar.date(byAdding: .day, value: 1, to: startOfDay)! as NSDate
        )
        
        do {
            // 获取符合条件的所有单词
            let words = try context.fetch(fetchRequest)
            var correctCount = 0  // 最后一次听写正确的单词数
            var totalCount = 0    // 当天练习的总单词数
            
            // 遍历每个单词
            for word in words {
                // 获取单词的所有听写记录
                if let results = word.wordResults?.allObjects as? [WordResult],
                   // 筛选出当天的听写记录，并获取最后一次的结果
                   let latestResult = results.filter({ calendar.isDate($0.date ?? Date(), inSameDayAs: date) })
                    .max(by: { ($0.date ?? Date()) < ($1.date ?? Date()) }) {
                    totalCount += 1  // 单词计数加1
                    // 如果最后一次听写正确，正确计数加1
                    if latestResult.isCorrect {
                        correctCount += 1
                    }
                }
            }
            
            // 计算正确率：正确单词数 / 总单词数
            // 如果没有练习任何单词，返回0
            return totalCount > 0 ? Double(correctCount) / Double(totalCount) : 0
        } catch {
            print("计算每日正确率失败: \(error)")
            return 0
        }
    }
    
    /// 计算连续学习天数
    /// - Parameter results: 所有听写记录
    /// - Returns: 从今天往前计算的连续学习天数
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
    
    
}
