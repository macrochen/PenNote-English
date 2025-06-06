import SwiftUI

struct BatchDictationView: View {
    let words: [Word]
    @State private var userAnswers: [String] = []
    @Environment(\.dismiss) private var dismiss
    @State private var isNavigating = false 
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("听写练习")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text("本次听写单词（\(words.count)个）")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
                
                // 单词列表
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(words.indices, id: \.self) { index in
                        Text("\(index + 1). \(words[index].chinese ?? "")")
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Text("请在练习本上完成以上单词的听写，完成后点击下方按钮进行检查")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    isNavigating = true
                }) {
                    Text("开始检查")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
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
            .navigationDestination(isPresented: $isNavigating) {
                PracticeCheckView(words: words, userAnswers: [], isBatchMode: true)
            }
        }
    }
}