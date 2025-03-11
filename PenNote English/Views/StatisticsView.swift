import SwiftUI

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("统计")
                    .font(.title)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    StatisticsView()
}