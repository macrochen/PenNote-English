import SwiftUI

struct PracticeCheckView: View {
    let words: [Word]
    let userAnswers: [String]
    let isBatchMode: Bool  // 添加模式标识
    @State private var results: [(isCorrect: Bool, errorTypes: Set<SpellingErrorType>)] = []
    @State private var currentIndex = 0
    @State private var userInputError = ""
    @State private var currentAnswer = ""  // 批量模式下用于输入答案
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PracticeViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // 单词信息卡片
            VStack(alignment: .leading, spacing: 12) {
                Text(words[currentIndex].english ?? "")
                    .font(.title2)
                    .bold()
                Text(words[currentIndex].chinese ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let example = words[currentIndex].example {
                    Text(example)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                if let memoryTips = words[currentIndex].memoryTips {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("记忆技巧：")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(memoryTips)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // 答案部分
            VStack(spacing: 12) {
                if isBatchMode {
                    TextField("输入单词", text: $currentAnswer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                } else {
                    Text("你的答案：\(userAnswers[currentIndex])")
                        .foregroundColor(results[safe: currentIndex]?.isCorrect ?? false ? .green : .red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if isBatchMode {
                // 批量模式下的正确/错误按钮
                HStack(spacing: 20) {
                    Button(action: {
                        checkAndProceed(isCorrect: true)
                    }) {
                        Text("正确")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(results[safe: currentIndex]?.isCorrect == true ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        checkAndProceed(isCorrect: false)
                    }) {
                        Text("错误")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(results[safe: currentIndex]?.isCorrect == false ? Color.red : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            
            if !(results[safe: currentIndex]?.isCorrect ?? true) {
                errorTypeSelector(for: currentIndex)
            }
            
            Spacer()
            
            if !isBatchMode {
                Button(action: nextWord) {
                    Text(currentIndex < words.count - 1 ? "下一个" : "完成")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("听写结果登记")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveResults()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            if isBatchMode {
                initializeResults()
            } else {
                checkAnswers()
            }
        }
    }
    
    private func checkAndProceed(isCorrect: Bool) {
        guard currentIndex < words.count else { return }
        
        if isCorrect {
            results[currentIndex] = (isCorrect: true, errorTypes: [])
        } else {
            results[currentIndex] = (isCorrect: false, errorTypes: [])
        }
        
        if currentIndex < words.count - 1 {
            currentIndex += 1
            currentAnswer = ""
        }
    }
    
    private func initializeResults() {
        results = Array(repeating: (isCorrect: false, errorTypes: Set<SpellingErrorType>()), count: words.count)
    }
    
    private func markAnswer(isCorrect: Bool) {
        guard currentIndex < results.count else { return }
        results[currentIndex].isCorrect = isCorrect
        if isCorrect {
            results[currentIndex].errorTypes.removeAll()
        }
    }
    
    private func nextWord() {
        if currentIndex < words.count - 1 {
            currentIndex += 1
            userInputError = ""
        } else {
            saveResults()
            dismiss()
        }
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
            
            if isBatchMode {
                TextField("输入错误拼写", text: $userInputError)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top)
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
