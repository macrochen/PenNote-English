import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WordListView()
                .tabItem {
                    Label("单词", systemImage: "doc.text")
                }
            
            PracticeModeView()
                .tabItem {
                    Label("练习", systemImage: "pencil")
                }
            
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
}