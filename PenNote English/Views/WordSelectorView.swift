import SwiftUI

struct WordSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let grade: Int16
    let semester: Int16
    let unit: Int16
    @Binding var selectedWords: [Word]
    @StateObject private var viewModel: PracticeViewModel
    @State private var selection = Set<Word>()
    
    init(grade: Int16, semester: Int16, unit: Int16, selectedWords: Binding<[Word]>) {
        self.grade = grade
        self.semester = semester
        self.unit = unit
        self._selectedWords = selectedWords
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeViewModel(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.selectedWords, id: \.self, selection: $selection) { word in
                VStack(alignment: .leading) {
                    Text(word.english ?? "")
                        .font(.headline)
                    Text(word.chinese ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("选择单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        selectedWords = Array(selection)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchWordsForCurrentSelection(grade: grade, semester: semester, unit: unit)
            // 如果已经有选中的单词，恢复选中状态
            selection = Set(selectedWords)
        }
    }
}

struct WordSelectorRow: View {
    let word: Word
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                VStack(alignment: .leading) {
                    Text(word.english ?? "")
                        .foregroundColor(.primary)
                    Text(word.chinese ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}