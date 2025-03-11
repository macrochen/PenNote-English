import SwiftUI

struct WordReviewListView: View {
    let words: [Word]
    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if currentIndex < words.count {
            WordDetailView(word: words[currentIndex])
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Text("\(currentIndex + 1)/\(words.count)")
                                .foregroundColor(.secondary)
                            
                            if currentIndex < words.count - 1 {
                                Button(action: {
                                    withAnimation {
                                        currentIndex += 1
                                    }
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { gesture in
                            if gesture.translation.width < 0 {
                                // 左滑：下一个
                                withAnimation {
                                    if currentIndex < words.count - 1 {
                                        currentIndex += 1
                                    }
                                }
                            } else {
                                // 右滑：上一个
                                withAnimation {
                                    if currentIndex > 0 {
                                        currentIndex -= 1
                                    }
                                }
                            }
                        }
                )
        } else {
            VStack(spacing: 20) {
                Text("复习完成！")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("已完成所有单词的复习，建议在充分理解和记忆后进行听写练习")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button("返回") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("开始听写") {
                        // TODO: 导航到听写界面
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}