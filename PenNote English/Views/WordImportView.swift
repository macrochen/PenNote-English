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
                
                guard columns.count >= 2 else { continue }  // 至少需要英文和中文
                
                let word = Word(context: viewContext)
                word.id = UUID()
                let now = Date()
                word.createdAt = now
                word.updatedAt = now
                word.status = 0
                word.errorCount = 0
                
                // 处理英文和音标
                let englishWithPhonetic = columns[0]
                let components = englishWithPhonetic.components(separatedBy: "[")
                word.english = components[0].trimmingCharacters(in: .whitespaces)
                if components.count > 1, let phoneticText = components[1].split(separator: "]").first {
                    word.phonetic = String(phoneticText)  // 修改：确保转换为 String
                } else {
                    word.phonetic = ""  // 修改：设置默认值
                }
                
                // 处理其他字段
                word.chinese = columns[1]
                
                // 修改：添加空值检查
                if columns.count > 2 && !columns[2].isEmpty {
                    word.etymology = columns[2]
                }
                
                if columns.count > 3 && !columns[3].isEmpty {
                    word.structure = columns[3]
                }
                
                // 处理例句和翻译
                if columns.count > 4 && !columns[4].isEmpty {
                    let parts = columns[4].components(separatedBy: "（")
                    word.example = parts[0].trimmingCharacters(in: .whitespaces)
                    if parts.count > 1 {
                        word.exampleTranslation = parts[1].replacingOccurrences(of: "）", with: "")
                    }
                }
                
                if columns.count > 5 && !columns[5].isEmpty {
                    word.memoryTips = columns[5]
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