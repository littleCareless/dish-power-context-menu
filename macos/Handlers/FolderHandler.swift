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
            var selectedFoldersData: [[String: Any]] = []
            for url in dialog.urls {
                do {
                    // 确保在 App Sandbox 中启用了 "User Selected File" 的读/写权限
                    let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    let bookmarkBase64 = bookmarkData.base64EncodedString()
                    NSLog("Swift: Generated bookmark for \(url.path)")
                    
                    // 立即保存到授权目录
                    let saveSuccess = SecurityBookmarkManager.shared.addAuthorizedDirectory(path: url.path, displayName: nil)
                    
                    var folderData: [String: Any] = [
                        "path": url.path,
                        "bookmark": bookmarkBase64,
                        "saved": saveSuccess
                    ]
                    
                    if saveSuccess {
                        NSLog("Swift: Successfully saved authorized directory: \(url.path)")
                    } else {
                        NSLog("Swift: Failed to save authorized directory: \(url.path)")
                        folderData["error"] = "保存授权目录失败"
                    }
                    
                    selectedFoldersData.append(folderData)
                } catch {
                    NSLog("Swift: Failed to create bookmark for \(url.path): \(error)")
                    // 书签生成失败，添加错误信息但继续处理其他文件夹
                    let folderData: [String: Any] = [
                        "path": url.path,
                        "bookmark": "",
                        "saved": false,
                        "error": "生成书签失败: \(error.localizedDescription)"
                    ]
                    selectedFoldersData.append(folderData)
                }
            }
            
            if selectedFoldersData.isEmpty && !dialog.urls.isEmpty {
                 result(["error": "BOOKMARK_ERROR_ALL", "message": "所有选择的文件夹都无法生成书签"])
            } else if selectedFoldersData.isEmpty && dialog.urls.isEmpty {
                 result(nil) // 没有选择任何文件夹，或者选择的文件夹都无法访问
            } else {
                // 统计成功保存的文件夹数量
                let savedCount = selectedFoldersData.filter { ($0["saved"] as? Bool) == true }.count
                NSLog("Swift: Successfully processed \(selectedFoldersData.count) folders, \(savedCount) saved to authorized directories")
                result(selectedFoldersData)
            }
        } else {
            result(nil) // 用户取消
        }
    }

}
