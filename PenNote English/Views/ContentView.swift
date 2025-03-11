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
                Text("练习")
            }
            .tag(1)
            .tabItem {
                Label("练习", systemImage: "pencil")
            }
            
            NavigationStack {
                Text("统计")
            }
            .tag(2)
            .tabItem {
                Label("统计", systemImage: "chart.bar")
            }
            
            NavigationStack {
                Text("设置")
            }
            .tag(3)
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
    }
}