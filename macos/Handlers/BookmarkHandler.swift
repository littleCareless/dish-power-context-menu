import Cocoa

class BookmarkHandler {
    static let shared = BookmarkHandler()

    func resolveBookmarks(bookmarksBase64: [String], finderMenuItems: [[String: Any]], result: @escaping (Any?) -> Void) {
        NSLog("Swift: Received \(bookmarksBase64.count) bookmarks to resolve.")
        var successfulPaths: [String] = []
        var failedBookmarksIndices: [Int] = [] // 存储解析失败的书签的索引

        for (index, bookmarkBase64) in bookmarksBase64.enumerated() {
            guard let bookmarkData = Data(base64Encoded: bookmarkBase64) else {
                NSLog("Swift: Invalid bookmark data (not base64) for bookmark at index \(index)")
                failedBookmarksIndices.append(index)
                continue
            }

            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], bookmarkDataIsStale: &isStale)
                
                if isStale {
                    NSLog("Swift: Bookmark for \(url.path) (index \(index)) is stale. Attempting to refresh.")
                    // 尝试刷新或标记为需要用户操作
                }

                if url.startAccessingSecurityScopedResource() {
                    NSLog("Swift: Successfully accessed security scoped resource: \(url.path) (index \(index))")
                    successfulPaths.append(url.path)
                    // 注意: 何时调用 url.stopAccessingSecurityScopedResource() 取决于应用逻辑
                } else {
                    NSLog("Swift: Failed to start accessing security scoped resource for \(url.path) (index \(index))")
                    failedBookmarksIndices.append(index)
                }
            } catch {
                NSLog("Swift: Failed to resolve bookmark at index \(index): \(error)")
                failedBookmarksIndices.append(index)
            }
        }
        
        NSLog("Swift: Resolved \(successfulPaths.count) paths successfully. Failed to resolve \(failedBookmarksIndices.count) bookmarks.")
        // 返回一个包含成功路径和失败书签索引（或原始书签）的字典
        // 为了让 Flutter 端更容易匹配，可以返回原始书签列表中的失败书签
        var failedOriginalBookmarks: [String] = []
        for index in failedBookmarksIndices {
            if index < bookmarksBase64.count { // 安全检查
                failedOriginalBookmarks.append(bookmarksBase64[index])
            }
        }

        result([
            "successfulPaths": successfulPaths,
            "failedBookmarks": failedOriginalBookmarks // 或者 failedBookmarksIndices
        ])
        
        // 发送通知给 FinderSync 扩展
        // The object must be a property list object, in this case, an array of dictionaries.
        let userInfo = ["items": finderMenuItems]
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("FinderMenuItemsUpdate"),
            object: nil,
            userInfo: userInfo
        )
        NSLog("BookmarkHandler: Posted FinderMenuItemsUpdate notification.")
    }
}
