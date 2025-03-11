import SwiftUI

struct MainView: View {
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
            
            // ... 其他 tab 保持不变 ...
        }
    }
}