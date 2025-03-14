import SwiftUI
import CoreData

struct WordSelectorView: View {
    let grade: Int16
    let semester: Int16
    let unit: Int16
    let importanceFilter: Int16  // 添加重要程度过滤
    let practiceStatusFilter: Int16  // 添加听写状态过滤
    let errorCountFilter: Int16  // 添加错误次数过滤
    @Binding var selectedWords: [Word]
    
    // 添加环境变量
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 添加分组相关状态
    @State private var selectedGroups: Set<Int> = []
    
    private var words: [Word] {
        let request = Word.fetchRequest()
        
        // 构建基本查询条件
        var predicates: [NSPredicate] = []
        
        // 年级、学期、单元的基本条件
        predicates.append(NSPredicate(format: "grade == %d AND semester == %d AND unit == %d", 
                                     grade, semester, unit))
        
        // 重要程度过滤
        if importanceFilter != -1 {  // -1 表示"全部"
            predicates.append(NSPredicate(format: "importance == %d", importanceFilter))
        }
        
        // 听写状态过滤
        if practiceStatusFilter == 1 {  // 1 表示"未听写"
            // 查找没有关联 wordResults 的单词
            predicates.append(NSPredicate(format: "wordResults.@count == 0"))
        }
        
        // 错误次数过滤
        if errorCountFilter > 0 {
            switch errorCountFilter {
            case 1:  // 1次错误
                predicates.append(NSPredicate(format: "SUBQUERY(wordResults, $result, $result.isCorrect == NO).@count == 1"))
            case 2:  // 2次错误
                predicates.append(NSPredicate(format: "SUBQUERY(wordResults, $result, $result.isCorrect == NO).@count == 2"))
            case 3:  // 3次错误
                predicates.append(NSPredicate(format: "SUBQUERY(wordResults, $result, $result.isCorrect == NO).@count == 3"))
            case 4:  // 3次以上错误
                predicates.append(NSPredicate(format: "SUBQUERY(wordResults, $result, $result.isCorrect == NO).@count > 3"))
            default:
                break
            }
        }
        
        // 组合所有条件
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
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