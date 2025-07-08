import Cocoa

class FinderActionHandler {
    static let shared = FinderActionHandler()

    // MARK: - Finder Action Handlers

   func performOpenWithApp(filePath: String, appPath: String, appType: String) {
       NSLog("Finder动作处理器: 收到打开请求。文件路径: '\(filePath)', 应用路径: '\(appPath)', 应用类型: '\(appType)'")

       // 检查是否为终端应用（基于 Bundle ID 判断）
       let terminalBundleIds = ["com.apple.Terminal", "dev.warp.Warp-Stable", "com.googlecode.iterm2"]
       let isTerminalApp = terminalBundleIds.contains(appType)
       
       var urlToOpen = URL(fileURLWithPath: filePath)

       if isTerminalApp {
           var isDirectory: ObjCBool = false
           if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) {
               if !isDirectory.boolValue {
                   // If it's a file, get its parent directory
                   urlToOpen = urlToOpen.deletingLastPathComponent()
               }
           } else {
               NSLog("Finder动作处理器: 文件或目录不存在: \(filePath)")
               return
           }
       }

       var finalAppURL: URL?

       // 优先使用提供的应用路径
       if !appPath.isEmpty && FileManager.default.fileExists(atPath: appPath) {
           finalAppURL = URL(fileURLWithPath: appPath)
       } else {
           // 直接使用 appType 作为 Bundle ID 来查找应用
           finalAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appType)
           if finalAppURL == nil {
               NSLog("Finder动作处理器: 无法找到 Bundle ID '\(appType)' 对应的应用")
           }
       }

       guard let appURL = finalAppURL else {
           NSLog("Finder动作处理器: 找不到应用 URL。应用路径: '\(appPath)', 应用类型: '\(appType)'.")
           // Optionally, show an alert to the user.
           return
       }

       let configuration = NSWorkspace.OpenConfiguration()
       NSWorkspace.shared.open([urlToOpen], withApplicationAt: appURL, configuration: configuration) { (runningApplication, error) in
           if let error = error {
               NSLog("Finder动作处理器: 使用 \(appURL.path) 打开 \(urlToOpen.path) 失败: \(error.localizedDescription)")
           } else {
               NSLog("Finder动作处理器: 成功请求使用 \(appURL.path) 打开 \(urlToOpen.path)。")
           }
       }
   }

    func performCreateFile(targetDirectoryPath: String, fileType: String?, params: [String: String]) {
        NSLog("Finder动作处理器: 收到创建文件/文件夹请求。目标目录: \(targetDirectoryPath), 文件类型: \(fileType ?? "nil"), 参数: \(params)")
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: targetDirectoryPath, isDirectory: nil) else {
            NSLog("Finder动作处理器: 目标路径 \(targetDirectoryPath) 不存在。")
            return
        }

        if fileType == "folder" {
            // Handle folder creation
            let folderName = params["fileName"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "New Folder"
            var fullPath = URL(fileURLWithPath: targetDirectoryPath).appendingPathComponent(folderName).path
            var counter = 1
            while fileManager.fileExists(atPath: fullPath) {
                fullPath = URL(fileURLWithPath: targetDirectoryPath).appendingPathComponent("\(folderName) \(counter)").path
                counter += 1
            }
            do {
                try fileManager.createDirectory(atPath: fullPath, withIntermediateDirectories: true, attributes: nil)
                NSLog("Finder动作处理器: 成功在 \(fullPath) 创建文件夹")
            } catch {
                NSLog("Finder动作处理器: 在 \(fullPath) 创建文件夹失败: \(error.localizedDescription)")
            }
            return
        }

        // Handle file creation
        let targetURL = URL(fileURLWithPath: targetDirectoryPath)
        var baseName = params["fileName"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
        baseName = baseName.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        if baseName.isEmpty { baseName = "Untitled" }

        // 处理文件扩展名：统一处理不同的文件类型格式
        var sanitizedFileType: String? = nil
        if let ft = fileType?.trimmingCharacters(in: .whitespacesAndNewlines), !ft.isEmpty {
            var actualExtension = ft
            
            // 处理 Flutter UI 中的 'newFile:.ext' 格式
            if ft.hasPrefix("newFile:") {
                actualExtension = String(ft.dropFirst(8)) // 移除 "newFile:" 前缀
            }
            
            // 移除开头的点号（如果有的话），然后清理其他非法字符
            let cleanExtension = actualExtension.hasPrefix(".") ? String(actualExtension.dropFirst()) : actualExtension
            sanitizedFileType = cleanExtension.replacingOccurrences(of: "/", with: "").replacingOccurrences(of: ":", with: "")
        }
        
        var fileNameWithExtension: String
        if let ft = sanitizedFileType, !ft.isEmpty {
            fileNameWithExtension = "\(baseName).\(ft)"
        } else {
            fileNameWithExtension = baseName
        }

        var finalFileName = fileNameWithExtension
        var fullPath = targetURL.appendingPathComponent(finalFileName).path
        var counter = 1
        let conflictSanitizedBaseName = baseName.replacingOccurrences(of: "[\\\\/:*?\"<>|]", with: "_", options: .regularExpression)

        while fileManager.fileExists(atPath: fullPath) {
            if let ft = sanitizedFileType, !ft.isEmpty {
                finalFileName = "\(conflictSanitizedBaseName)-\(counter).\(ft)"
            } else {
                finalFileName = "\(conflictSanitizedBaseName)-\(counter)"
            }
            fullPath = targetURL.appendingPathComponent(finalFileName).path
            counter += 1
            if counter > 1000 {
                NSLog("Finder动作处理器: 尝试查找唯一文件名超过1000次。正在中止。")
                return
            }
        }

        if fileManager.createFile(atPath: fullPath, contents: nil, attributes: nil) {
            NSLog("Finder动作处理器: 成功在 \(fullPath) 创建文件")
        } else {
            NSLog("Finder动作处理器: 在 \(fullPath) 创建文件失败。")
        }
    }
    func performCopyPath(filePath: String) {
        NSLog("Finder动作处理器: 收到路径拷贝请求: \(filePath)")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(filePath, forType: .string)
        NSLog("Finder动作处理器: 成功将路径拷贝到剪贴板: \(filePath)")
    }
}
