import SwiftUI
import UniformTypeIdentifiers

struct WordImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL] = []
    @State private var isShowingFilePicker = false
    @State private var importedFileURL: URL?
    @State private var importStatus = ""
    @State private var isImporting = false
    
    var body: some View {
        VStack(spacing: 20) {
            List {
                Section(header: Text("导入说明")) {
                    Text("支持的文件格式：")
                        .font(.headline)
                    Text("• Markdown文件（.md）")
                    
                    Text("文件要求：")
                        .font(.headline)
                        .padding(.top)
                    Text("• 第一行为表头")
                    Text("• 必需列：英文、中文释义")
                    Text("• 可选列：词根词缀、单词结构、例句、记忆技巧")
                }
                
                Section(header: Text("本地文件")) {
                    ForEach(files, id: \.self) { file in
                        Button(action: {
                            importWords(from: file)
                        }) {
                            Text(file.lastPathComponent)
                        }
                    }
                }
            }
            
            Button(action: {
                isShowingFilePicker = true
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("选择文件")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .disabled(isImporting)
            
            if !importStatus.isEmpty {
                Text(importStatus)
                    .foregroundColor(importStatus.contains("成功") ? .green : .red)
                    .padding()
            }
            
            if isImporting {
                ProgressView("导入中...")
            }
        }
        .navigationTitle("导入单词")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            files = FileManager.default.getFiles()
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.text, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let fileURL = files.first {
                    importedFileURL = fileURL
                    importWords(from: fileURL)
                }
            case .failure(let error):
                importStatus = "导入失败：\(error.localizedDescription)"
            }
        }
    }
    
    private func importWords(from fileURL: URL) {
        isImporting = true
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            importStatus = "无法访问文件，请重试"
            isImporting = false
            return
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            guard lines.count >= 2 else {
                importStatus = "文件格式错误：文件内容不足"
                isImporting = false
                return
            }
            
            // 验证表头
            let headers = lines[0].components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            guard headers.count >= 2 else {
                importStatus = "文件格式错误：表头格式不正确"
                isImporting = false
                return
            }
            
            var words: [Word] = []
            for (index, line) in lines.enumerated() {
                if index <= 1 { continue }  // 跳过表头和分隔行
                
                let columns = line.components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                guard columns.count >= 4 else { continue }  // 至少需要英文、音标、词性和中文
                
                let word = Word(context: viewContext)
                word.id = UUID()
                let now = Date()
                word.createdAt = now
                word.updatedAt = now
                
                // 处理英文（第1列）
                word.english = columns[0].trimmingCharacters(in: .whitespaces)
                
                // 处理音标（第2列）
                word.phonetic = columns[1].trimmingCharacters(in: .whitespaces)
                
                // 处理词性（第3列）
                word.partOfSpeech = columns[2].trimmingCharacters(in: .whitespaces)
                
                // 处理中文释义（第4列）
                word.chinese = columns[3].trimmingCharacters(in: .whitespaces)
                
                // 处理重要性（第5列）
                if columns.count > 4 {
                    word.importance = columns[4] == "重点" ? 1 : 0
                }
                
                // 处理年级（第6列）
                if columns.count > 5, let grade = Int16(columns[5]) {
                    word.grade = grade
                }
                
                // 处理学期（第7列）
                if columns.count > 6, let semester = Int16(columns[6]) {
                    word.semester = semester
                }
                
                // 处理单元（第8列）
                if columns.count > 7, let unit = Int16(columns[7]) {
                    word.unit = unit
                }
                
                // 处理例句（第9列）
                if columns.count > 8 {
                    word.example = columns[8].trimmingCharacters(in: .whitespaces)
                }
                
                // 处理例句翻译（第10列）
                if columns.count > 9 {
                    word.exampleTranslation = columns[9].trimmingCharacters(in: .whitespaces)
                }
                
                // 处理词形结构分析（第11列）
                if columns.count > 10 {
                    word.etymology = columns[10].trimmingCharacters(in: .whitespaces)
                }
                
                // 处理记忆技巧（第12列）
                if columns.count > 11 {
                    word.memoryTips = columns[11].trimmingCharacters(in: .whitespaces)
                }
                words.append(word)
            }
            
            if words.isEmpty {
                importStatus = "没有找到有效的单词数据"
                isImporting = false
                return
            }
            
            try viewContext.save()
            importStatus = "导入成功：已添加\(words.count)个单词"
            isImporting = false
            dismiss()
            
        } catch {
            print("Import error: \(error)")
            importStatus = "读取文件失败：\(error.localizedDescription)"
            isImporting = false
        }
    }
}

extension FileManager {
    func getFiles() -> [URL] {
        guard let documentsURL = urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        do {
            let fileURLs = try contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "md" }
        } catch {
            print("Error getting files: \(error)")
            return []
        }
    }
}