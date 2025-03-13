import SwiftUI

struct PracticeCheckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: PracticeViewModel
    let words: [Word]
    let userAnswers: [String]
    let isBatchMode: Bool
    
    @State private var results: [(isCorrect: Bool, errorTypes: Set<SpellingErrorType>)] = []
    @State private var currentIndex = 0
    @State private var userInputError = ""
    @State private var currentAnswer = ""
    @Environment(\.dismiss) private var dismiss
    @State private var isCompleted = false  // 添加完成状态标记
    // 添加新的状态变量
    @State private var showingStatistics = false
    @State private var sessionStats: SessionStats?  // 添加会话统计状态
    @State private var completionMessage = ""  // 添加完成消息状态
    
    init(words: [Word], userAnswers: [String], isBatchMode: Bool) {
        self.words = words
        self.userAnswers = userAnswers
        self.isBatchMode = isBatchMode
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeViewModel(viewContext: context))
    }
    
    @State private var isViewReady = false  // 添加视图准备状态
    
    var body: some View {
        VStack(spacing: 20) {
            WordInfoCard(word: words[currentIndex])
            
            if !isBatchMode {
               AnswerCard(
                    isBatchMode: isBatchMode,
                    currentAnswer: $currentAnswer,
                    userAnswer: isBatchMode ? currentAnswer : userAnswers[currentIndex],
                    isCorrect: results[safe: currentIndex]?.isCorrect ?? false
                )
            }
            
            if !(results[safe: currentIndex]?.isCorrect ?? true) {
                errorTypeSelector(for: currentIndex)
            }
            
            Spacer()
            
            NextButton(
                currentIndex: currentIndex,
                wordsCount: words.count,
                action: nextWord
            )
        }
        .padding()
        .navigationTitle("听写结果登记")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()  // 直接关闭，不保存结果
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            guard !isViewReady else { return }
            if isBatchMode {
                initializeResults()
            } else {
                checkAnswers()
            }
            isViewReady = true
        }
        .alert("听写完成", isPresented: $showingStatistics) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text(completionMessage)
        }
    }
    
    
    
    private func calculateErrorTypeStats() -> [ErrorTypeStat] {
        let errorTypeGroups = Dictionary(grouping: results.flatMap { $0.errorTypes }) { $0 }
        let incorrectCount = Double(results.filter { !$0.isCorrect }.count)
        
        return errorTypeGroups.map { (type, occurrences) in
            ErrorTypeStat(
                type: type,
                count: occurrences.count,
                percentage: incorrectCount > 0 ? Double(occurrences.count) / incorrectCount : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func createSessionStats() -> SessionStats {
        SessionStats(
            totalCount: words.count,
            correctCount: results.filter { $0.isCorrect }.count,
            errorTypes: calculateErrorTypeStats()
        )
    }
    
    private func nextWord() {
        // 检查非批量模式下的错误类型选择
        if !isBatchMode && !(results[currentIndex].isCorrect) && results[currentIndex].errorTypes.isEmpty {
            // 如果是错误答案但没有选择错误类型，不允许进入下一个
            return
        }
        
        if currentIndex < words.count - 1 {
            // 在批量模式下，如果没有选择错误类型，则标记为正确
            if isBatchMode && results[currentIndex].errorTypes.isEmpty {
                results[currentIndex].isCorrect = true
            }
            currentIndex += 1
            userInputError = ""
        } else {
            // 处理最后一个单词
            if isBatchMode && results[currentIndex].errorTypes.isEmpty {
                results[currentIndex].isCorrect = true
            }

            isCompleted = true
            let stats = createSessionStats()

            let correctRate = Double(stats.correctCount) / Double(stats.totalCount) * 100
            completionMessage = String(format: "总共 %d 个单词，正确 %d 个，正确率 %.1f%%", 
                stats.totalCount, 
                stats.correctCount,
                correctRate
            )

            saveResults()
            showingStatistics = true
        }
    }
    
    
    private func initializeResults() {
        results = Array(repeating: (isCorrect: false, errorTypes: Set<SpellingErrorType>()), count: words.count)
    }
    
    
    private func checkAnswers() {
        results = zip(words, userAnswers).map { word, answer in
            let isCorrect = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                          (word.english ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return (isCorrect, Set<SpellingErrorType>())
        }
    }
    
    private func toggleErrorType(_ errorType: SpellingErrorType, for index: Int) {
        guard var result = results[safe: index] else { return }
        
        if result.errorTypes.contains(errorType) {
            result.errorTypes.remove(errorType)
        } else {
            result.errorTypes.insert(errorType)
        }
        
        results[index] = result
    }
    
    private func saveResults() {
        for (index, word) in words.enumerated() {
            viewModel.saveWordResult(
                word: word,
                isCorrect: results[index].isCorrect,
                errorTypes: Array(results[index].errorTypes)
            )
        }
    }
    
    private func errorTypeSelector(for index: Int) -> some View {
        VStack(alignment: .leading) {
            Text("错误类型")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(SpellingErrorType.allCases, id: \.rawValue) { errorType in
                    Button(action: {
                        toggleErrorType(errorType, for: index)
                    }) {
                        Text(errorType.description)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(
                                results[safe: index]?.errorTypes.contains(errorType) ?? false
                                ? Color.blue
                                : Color.gray.opacity(0.1)
                            )
                            .foregroundColor(
                                results[safe: index]?.errorTypes.contains(errorType) ?? false
                                ? .white
                                : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
            
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// 单词信息卡片
private struct WordInfoCard: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word.english ?? "")
                .font(.title2)
                .bold()
            Text(word.chinese ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// 答案卡片
private struct AnswerCard: View {
    let isBatchMode: Bool
    @Binding var currentAnswer: String
    let userAnswer: String
    let isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if isBatchMode {
                TextField("输入单词", text: $currentAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.done)
            } else {
                Text("你的答案：\(userAnswer)")
                    .foregroundColor(isCorrect ? .green : .red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}


// 下一个按钮
private struct NextButton: View {
    let currentIndex: Int
    let wordsCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(currentIndex < wordsCount - 1 ? "下一个" : "完成")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// 关闭按钮
private struct CloseButton: View {
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isCompleted {
                action()
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(isCompleted ? .blue : .gray)
        }
        .disabled(!isCompleted)
    }
}
