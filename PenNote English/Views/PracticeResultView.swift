import SwiftUI

struct PracticeResultView: View {
    let words: [Word]
    @Binding var results: [String: Bool]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("练习结果")
                        .font(.title)
                        .padding(.top)
                    
                    ForEach(words.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(index + 1). \(words[index].english ?? "")")
                                .font(.headline)
                            Text(words[index].chinese ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("结果：")
                                Button(action: {
                                    results[words[index].english ?? ""] = true
                                }) {
                                    Image(systemName: results[words[index].english ?? ""] == true ? "checkmark.circle.fill" : "checkmark.circle")
                                        .foregroundColor(.green)
                                }
                                Button(action: {
                                    results[words[index].english ?? ""] = false
                                }) {
                                    Image(systemName: results[words[index].english ?? ""] == false ? "xmark.circle.fill" : "xmark.circle")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("保存结果")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}