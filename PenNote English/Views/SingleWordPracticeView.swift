import SwiftUI

struct SingleWordPracticeView: View {
    let words: [Word]
    @State private var currentIndex = 0
    @State private var userAnswers: [String] = []
    @State private var currentInput = ""
    @State private var showingCheck = false
    @State private var hasCompletedPractice = false
    @Environment(\.dismiss) private var dismiss
    @State private var isNavigating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 进度指示器
                ProgressView(value: Double(currentIndex), total: Double(words.count))
                    .padding(.horizontal)
                
                Text("\(currentIndex + 1) / \(words.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // 当前单词的中文释义
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(words[currentIndex].chinese ?? "")
                            .font(.title2)
                        
                        Spacer()
                        
                        Button(action: speakWord) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let partOfSpeech = words[currentIndex].partOfSpeech {
                        Text(partOfSpeech)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 输入框
                TextField("请输入单词", text: $currentInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                // 导航按钮
                HStack(spacing: 15) {
                    // 上一个按钮
                    Button(action: previousWord) {
                        Text("上一个")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentIndex > 0 ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(currentIndex == 0)
                    
                    // 下一个/完成按钮
                    Button(action: nextWord) {
                        Text(currentIndex < words.count - 1 ? "下一个" : "完成")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                userAnswers = Array(repeating: "", count: words.count)
            }
            .navigationDestination(isPresented: $isNavigating) {  // 使用新的状态变量
                PracticeCheckView(words: words, userAnswers: userAnswers, isBatchMode: false)
            }
        }
    }
    
    private func previousWord() {
        // 保存当前输入
        userAnswers[currentIndex] = currentInput
        
        // 返回上一个单词
        if currentIndex > 0 {
            currentIndex -= 1
            // 恢复上一个单词的输入
            currentInput = userAnswers[currentIndex]
        }
    }
    
    private func nextWord() {
        userAnswers[currentIndex] = currentInput
        
        if currentIndex < words.count - 1 {
            currentIndex += 1
            currentInput = ""
        } else {
            isNavigating = true  // 使用新的状态变量
        }
    }
    
    private func speakWord() {
        if let english = words[currentIndex].english {
            SpeechService.shared.speak(english)
        }
    }
}