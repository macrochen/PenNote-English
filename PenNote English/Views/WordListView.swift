import SwiftUI
import CoreData

struct WordListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Word.grade, ascending: true),
            NSSortDescriptor(keyPath: \Word.semester, ascending: true),
            NSSortDescriptor(keyPath: \Word.unit, ascending: true),
            NSSortDescriptor(keyPath: \Word.createdAt, ascending: true)
        ],
        animation: .default
    ) private var words: FetchedResults<Word>
    
    // 移除原来使用 status 的 reviewWords FetchRequest
    
    // 添加计算属性
    private var filteredWords: [Word] {
        guard !searchText.isEmpty else { return Array(words) }
        return words.filter { word in
            (word.english ?? "").localizedCaseInsensitiveContains(searchText) ||
            (word.chinese ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var accuracy: String {
        // 计算正确率：通过 wordResults 关系来计算
        let results = words.flatMap { $0.wordResults?.allObjects as? [WordResult] ?? [] }
        let total = results.count
        let correct = results.filter { $0.isCorrect }.count
        
        guard total > 0 else { return "0%" }
        return String(format: "%.1f%%", Double(correct) / Double(total) * 100)
    }
    
    // 添加分组数据的计算属性
    private var groupedWords: [Int: [Int: [Int: [Word]]]] {
        Dictionary(grouping: words) { Int($0.grade) }
            .mapValues { gradeWords in
                Dictionary(grouping: gradeWords) { Int($0.semester) }
                    .mapValues { semesterWords in
                        Dictionary(grouping: semesterWords) { Int($0.unit) }
                    }
            }
    }

    private var totalPracticeDays: Int {
        let results = words.flatMap { $0.wordResults?.allObjects as? [WordResult] ?? [] }
        let calendar = Calendar.current
        // 获取所有不同的练习日期
        let uniqueDates = Set(results.compactMap { result in
            calendar.startOfDay(for: result.date ?? Date())
        })
        return uniqueDates.count
    }

    var body: some View {
        NavigationView {
            List {
                // 统计卡片部分保持不变
                Section {
                    HStack(spacing: 10) {
                        StatCard(value: accuracy, label: "正确率", color: .green)
                        StatCard(value: "\(words.count)", label: "单词总数", color: .orange)
                        StatCard(value: "\(totalPracticeDays)", label: "练习天数", color: .blue)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                }
                
                // 按年级学期单元分组显示
                ForEach(groupedWords.keys.sorted(), id: \.self) { grade in
                    Section(header: Text("\(grade)年级")) {
                        ForEach(groupedWords[grade]?.keys.sorted() ?? [], id: \.self) { semester in
                            DisclosureGroup("\(semester)学期") {
                                ForEach(groupedWords[grade]?[semester]?.keys.sorted() ?? [], id: \.self) { unit in
                                    NavigationLink {
                                        WordReviewListView(words: groupedWords[grade]?[semester]?[unit] ?? [])
                                    } label: {
                                        HStack {
                                            Text("Unit \(unit)")
                                            Spacer()
                                            Text("\(groupedWords[grade]?[semester]?[unit]?.count ?? 0)个单词")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索单词...")
            .navigationTitle("单词列表")  // 添加导航标题
            .navigationBarTitleDisplayMode(.inline)  // 设置标题显示模式
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        NavigationLink {
                            WordImportView()
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // 添加一个默认的详情视图
            Text("选择一个单词查看详情")
                .foregroundColor(.secondary)
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive, action: clearAllWords)
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除所有单词吗？此操作不可撤销。")
        }
    }
    
    private func clearAllWords() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Word.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs // 设置返回被删除对象的 ID
        
        do {
            let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []
            ]
            
            // 合并更改到主上下文
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
            try viewContext.save()
            
            // 手动刷新 FetchRequest
            words.nsPredicate = words.nsPredicate
        } catch {
            print("Error clearing words: \(error)")
        }
    }
    
    private func deleteWords(offsets: IndexSet) {
        withAnimation {
            offsets.map { words[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting words: \(error)")
            }
        }
    }
}
