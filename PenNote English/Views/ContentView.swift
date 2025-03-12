import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WordListView()
            }
            .tag(0)
            .tabItem {
                Label("单词", systemImage: "doc.text")
            }
            
            NavigationStack {
                PracticeModeView()  // 替换为实际的练习视图
            }
            .tag(1)
            .tabItem {
                Label("练习", systemImage: "pencil")
            }
            
            NavigationStack {
                StatsView()  // 替换为实际的统计视图
            }
            .tag(2)
            .tabItem {
                Label("统计", systemImage: "chart.bar")
            }
            
            NavigationStack {
                SettingsView()  // 替换为实际的设置视图
            }
            .tag(3)
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
    }
}