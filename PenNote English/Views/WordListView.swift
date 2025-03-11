import SwiftUI
import CoreData

struct WordListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Word.updatedAt, ascending: false)
        ],
        animation: .default
    ) private var words: FetchedResults<Word>
    
    // 待复习单词
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Word.updatedAt, ascending: true)
        ],
        predicate: NSPredicate(format: "status < 2"),  // 未掌握的单词
        animation: .default
    ) private var reviewWords: FetchedResults<Word>
    
    // 添加计算属性
    private var filteredWords: [Word] {
        guard !searchText.isEmpty else { return Array(words) }
        return words.filter { word in
            (word.english ?? "").localizedCaseInsensitiveContains(searchText) ||
            (word.chinese ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var accuracy: String {
        // 计算正确率
        let total = words.reduce(into: 0) { $0 += Int($1.reviewCount) }
        let correct = words.reduce(into: 0) { $0 += Int($1.correctCount) }
        guard total > 0 else { return "0%" }
        return String(format: "%.1f%%", Double(correct) / Double(total) * 100)
    }
    
    var body: some View {
        List {
            // 统计卡片
            Section {
                HStack(spacing: 10) {
                    StatCard(value: accuracy, label: "正确率")
                    StatCard(value: "\(reviewWords.count)", label: "今日待复习")
                    StatCard(value: "7", label: "连续学习") // 这个值需要另外计算
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
            }
            
            // 待复习单词
            if !reviewWords.isEmpty {
                Section(header: Text("今日待复习")) {
                    ForEach(reviewWords) { word in
                        WordRow(word: word, showReviewButton: true)
                    }
                }
            }
            
            // 最近添加
            Section(header: Text("最近添加")) {
                ForEach(words) { word in
                    WordRow(word: word, showReviewButton: false)
                }
                .onDelete(perform: deleteWords)
            }
        }
        .searchable(text: $searchText, prompt: "搜索单词...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if !reviewWords.isEmpty {
                        NavigationLink {
                            WordReviewListView(words: Array(reviewWords))
                        } label: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
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
        
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
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

// 统计卡片组件
struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}


// 单词行组件
struct WordRow: View {
    let word: Word
    let showReviewButton: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(word.english ?? "")
                        .font(.headline)
                    if let phonetic = word.phonetic {
                        Text(phonetic)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Text(word.chinese ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if let english = word.english {
                    SpeechService.shared.speak(english)
                }
            }) {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            if showReviewButton {
                Text("复习")
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            NavigationLink(destination: WordDetailView(word: word)) {
                EmptyView()
            }
            .opacity(0)
            .frame(width: 0)
        }
        .padding(.vertical, 4)
    }
}