import SwiftUI

struct WordSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let grade: Int16
    let semester: Int16
    let unit: Int16
    @Binding var selectedWords: [Word]
    
    // 添加分组相关状态
    @State private var selectedGroups: Set<Int> = []
    
    private var words: [Word] {
        let request = Word.fetchRequest()
        request.predicate = NSPredicate(
            format: "grade == %d AND semester == %d AND unit == %d",
            grade, semester, unit
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("获取单词失败: \(error)")
            return []
        }
    }
    
    // 计算分组信息
    private var groups: [(range: ClosedRange<Int>, words: [Word])] {
        let wordArray = words
        let total = wordArray.count
        var result: [(range: ClosedRange<Int>, words: [Word])] = []
        
        let groupSize = 9 // 每组9个单词
        var start = 0
        
        while start < total {
            let end = min(start + groupSize - 1, total - 1)
            let range = start...end
            let groupWords = Array(wordArray[start...end])
            result.append((range: range, words: groupWords))
            start = end + 1
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 分组选择按钮
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(groups.indices, id: \.self) { index in
                            let group = groups[index]
                            // 修改分组选择按钮的 action
                            Button(action: {
                                if selectedGroups.contains(index) {
                                    selectedGroups.remove(index)
                                    selectedWords.removeAll { word in
                                        group.words.contains(word)
                                    }
                                } else {
                                    selectedGroups.insert(index)
                                    // 移除可能已经存在的单词，以避免重复
                                    selectedWords.removeAll { word in
                                        group.words.contains(word)
                                    }
                                    // 按照原始顺序添加单词
                                    selectedWords.append(contentsOf: group.words)
                                }
                            }) {
                                Text("\(group.range.lowerBound + 1)-\(group.range.upperBound + 1)")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedGroups.contains(index) ? Color.blue : Color.blue.opacity(0.1))
                                    .foregroundColor(selectedGroups.contains(index) ? .white : .blue)
                                    .cornerRadius(15)
                            }
                        }
                    }
                    .padding()
                }
                
                // 单词列表
                List {
                    ForEach(words) { word in
                        // 修改单个单词选择的 action
                        WordRow(word: word, isSelected: selectedWords.contains(word)) {
                            if selectedWords.contains(word) {
                                selectedWords.removeAll { $0 == word }
                            } else {
                                // 直接添加到末尾，保持选择顺序
                                selectedWords.append(word)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WordRow: View {
    let word: Word
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading) {
                    Text(word.english ?? "")
                    Text(word.chinese ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}