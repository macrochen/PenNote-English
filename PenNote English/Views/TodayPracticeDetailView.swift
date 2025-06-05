import SwiftUI
import CoreData

struct TodayPracticeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var todayWords: [Word] = []
    @State private var errorWords: [Word] = []
    @State private var correctWords: [Word] = []
    @State private var errorTypeStats: [ErrorTypeStat] = []
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    StatCard(value: "\(todayWords.count)", label: "总单词", color: .blue)
                    StatCard(value: "\(correctWords.count)", label: "正确", color: .green)
                    StatCard(value: "\(errorWords.count)", label: "错误", color: .orange)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
            }
            
            if !errorTypeStats.isEmpty {
                Section("错误类型分析") {
                    ErrorTypeAnalysisCard(errorTypes: errorTypeStats)
                }
            }
            
            if !errorWords.isEmpty {
                Section("错误单词") {
                    ForEach(errorWords) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.english ?? "")
                                .font(.headline)
                            Text(word.chinese ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let lastResult = word.wordResults?.allObjects.last as? WordResult,
                               let errorTypes = lastResult.errorTypes {
                                Text("错误类型: \(errorTypes.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if !correctWords.isEmpty {
                Section("正确单词") {
                    ForEach(correctWords) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.english ?? "")
                                .font(.headline)
                            Text(word.chinese ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("今日听写详情")
        .onAppear {
            loadTodayPracticeData()
        }
    }
    
    private func loadTodayPracticeData() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "ANY wordResults.date >= %@",
            startOfDay as NSDate
        )
        
        do {
            let words = try viewContext.fetch(fetchRequest)
            todayWords = words
            
            // 分类正确和错误的单词
            correctWords = words.filter { word in
                if let results = word.wordResults?.allObjects as? [WordResult],
                   let lastResult = results.max(by: { ($0.date ?? Date()) < ($1.date ?? Date()) }) {
                    return lastResult.isCorrect
                }
                return false
            }
            
            errorWords = words.filter { word in
                if let results = word.wordResults?.allObjects as? [WordResult],
                   let lastResult = results.max(by: { ($0.date ?? Date()) < ($1.date ?? Date()) }) {
                    return !lastResult.isCorrect
                }
                return false
            }
            
            // 计算错误类型统计
            var typeCounts: [SpellingErrorType: Int] = [:]
            let errorResults = errorWords.compactMap { word in
                word.wordResults?.allObjects.last as? WordResult
            }
            
            for result in errorResults {
                if let errorTypes = result.errorTypes {
                    for errorTypeString in errorTypes {
                        let errorType = SpellingErrorType.from(description: errorTypeString)
                        typeCounts[errorType, default: 0] += 1
                    }
                }
            }
            
            let total = Double(errorResults.count)
            errorTypeStats = SpellingErrorType.allCases.map { type in
                let count = Double(typeCounts[type] ?? 0)
                return ErrorTypeStat(
                    type: type,
                    count: Int(count),
                    percentage: total > 0 ? count / total : 0
                )
            }
        } catch {
            print("加载今日练习数据失败: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        TodayPracticeDetailView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
} 