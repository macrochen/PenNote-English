import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 10) {
                        StatCard(value: "\(viewModel.totalWords)", label: "总单词", color: .blue)
                        StatCard(value: "\(viewModel.practiceWords)", label: "已听写", color: .green)
                        StatCard(value: "\(viewModel.errorWords)", label: "错误", color: .orange)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                }
                
                Section {
                    HStack(spacing: 10) {
                        StatCard(value: String(format: "%.1f%%", viewModel.totalAccuracy * 100), label: "正确率", color: .purple)
                        StatCard(value: "\(viewModel.consecutiveDays)天", label: "连续学习", color: .red)
                        StatCard(value: "\(viewModel.todayPracticeCount)", label: "今日听写", color: .blue)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                }
                
                Section("学习趋势") {
                    WeeklyProgressCard(progress: viewModel.weeklyProgress)
                }
                
                Section("易错词Top5") {
                    ForEach(viewModel.difficultWords) { word in
                        DifficultWordCard(word: word)
                    }
                }
                
                Section("错误分析") {
                    ErrorTypeAnalysisCard(errorTypes: viewModel.errorTypeStats)
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)  // 添加这行来避免大标题
        }
        .onAppear {
            print("StatsView appeared")
            DispatchQueue.main.async {
                viewModel.loadStats()
            }
        }
        .onDisappear {
            print("StatsView disappeared")
        }
    }
}


struct WeeklyProgressCard: View {
    let progress: [Double]
    let days = ["一", "二", "三", "四", "五", "六", "日"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("本周学习情况")
                .font(.headline)
                .padding(.bottom, 10)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { index in
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(height: 150 * progress[index])
                        Text(days[index])
                            .font(.caption2)
                            .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct DifficultWordCard: View {
    let word: DifficultWord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.english)
                    .font(.headline)
                Text(word.chinese)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("错误率: \(Int(word.errorRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ErrorTypeAnalysisCard: View {
    let errorTypes: [ErrorTypeStat]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("错误类型分析")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(errorTypes) { stat in
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(height: 120 * stat.percentage)
                        Text(stat.type.description)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}