import Foundation

extension Word {
    // 这里添加自定义的辅助方法
    func updateStatus(_ newStatus: Int16) {
        self.status = newStatus
        self.updatedAt = Date()
    }
    
    func incrementErrorCount() {
        self.errorCount += 1
        self.updatedAt = Date()
    }
}