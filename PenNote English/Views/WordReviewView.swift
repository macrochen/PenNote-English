import SwiftUI
import CoreData

struct WordReviewView: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    @State private var showAnswer = false
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 中文提示
            Text(word.chinese ?? "")
                .font(.title2)
                .padding()
            
            Spacer()
            
            if showAnswer {
                // 显示答案
                VStack(spacing: 12) {
                    Text(word.english ?? "")
                        .font(.title)
                    if let phonetic = word.phonetic {
                        Text(phonetic)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        if let english = word.english {
                            SpeechService.shared.speak(english)
                        }
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            if !showAnswer {
                // 显示答案按钮
                Button(action: { showAnswer = true }) {
                    Text("显示答案")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            } else if !showResult {
                // 判断按钮
                HStack(spacing: 20) {
                    Button(action: {
                        word.updateReviewStatus(correct: false)
                        showResult = true
                    }) {
                        Text("不认识")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        word.updateReviewStatus(correct: true)
                        showResult = true
                    }) {
                        Text("认识")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            } else {
                // 继续按钮
                Button(action: { dismiss() }) {
                    Text("继续")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}