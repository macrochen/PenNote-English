import SwiftUI
import CoreData

struct WordListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Word.createdAt, ascending: false)],
        animation: .default)
    private var words: FetchedResults<Word>
    
    var body: some View {
        List {
            // 统计卡片
            Section {
                HStack(spacing: 10) {
                    StatCard(value: "85%", label: "正确率")
                    StatCard(value: "12", label: "今日待复习")
                    StatCard(value: "7", label: "连续学习")
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
            }
            
            // 待复习单词
            Section(header: Text("今日待复习")) {
                ForEach(words.filter { $0.status == 1 }) { word in
                    WordRow(word: word, showReviewButton: true)
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
        .searchable(text: .constant(""), prompt: "搜索单词...")
        .navigationTitle("笔记英语")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: clearAllWords) {
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
            
            HStack(spacing: 10) {
                Button(action: {
                    // 播放发音
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.blue)
                }
                
                if showReviewButton {
                    Button(action: {
                        // 开始复习
                    }) {
                        Text("复习")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}