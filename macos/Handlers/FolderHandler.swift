import Cocoa

class FolderHandler {
    static let shared = FolderHandler()

    func openFolder(result: @escaping (Any?) -> Void) {
        let dialog = NSOpenPanel()
        dialog.title = "选择一个或多个文件夹"
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = true // 允许多选

        if dialog.runModal() == .OK {
            var selectedFoldersData: [[String: String]] = []
            for url in dialog.urls {
                do {
                    // 确保在 App Sandbox 中启用了 "User Selected File" 的读/写权限
                    let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    let bookmarkBase64 = bookmarkData.base64EncodedString()
                    NSLog("Swift: Generated bookmark for \(url.path)")
                    selectedFoldersData.append(["path": url.path, "bookmark": bookmarkBase64])
                } catch {
                    NSLog("Swift: Failed to create bookmark for \(url.path): \(error)")
                    // 可以选择将错误信息也传递给 Flutter，或者只跳过这个文件夹
                    // 为简单起见，这里我们跳过创建失败的书签
                }
            }
            if selectedFoldersData.isEmpty && !dialog.urls.isEmpty {
                 result(["error": "BOOKMARK_ERROR_ALL", "message": "所有选择的文件夹都无法生成书签"])
            } else if selectedFoldersData.isEmpty && dialog.urls.isEmpty {
                 result(nil) // 没有选择任何文件夹，或者选择的文件夹都无法访问
            }
            else {
                result(selectedFoldersData)
            }
        } else {
            result(nil) // 用户取消
        }
    }

}
