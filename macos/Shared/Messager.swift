//
//  Messager.swift
//  R-Finder Menu
//
//  Created by AI Assistant on 2025/1/27.
//

import AppKit
import Foundation
import os.log

enum ActionType: String, CaseIterable {
    case open = "open"
    case create = "create"
    case copy = "copy"
    case delete = "delete"
    case openApp = "openApp"
    case copyPath = "copyPath"
    case openInTerminal = "openInTerminal"
    case createNewFile = "createNewFile"
    case menuUpdate = "menuUpdate"
}

struct MessagePayload: Codable {
    var action: String = ""
    var target: [String] = []
    var rid: String = ""
    var trigger: String = "" // ctx-items ctx-container ctx-sidebar toolbar
    var bundleId: String = ""
    var fileType: String = ""
    var itemData: [String: String] = [:]
    var menuItems: [[String: Any]]? = nil
    
    // 自定义编码器处理 menuItems
    enum CodingKeys: String, CodingKey {
        case action, target, rid, trigger, bundleId, fileType, itemData, menuItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decodeIfPresent(String.self, forKey: .action) ?? ""
        target = try container.decodeIfPresent([String].self, forKey: .target) ?? []
        rid = try container.decodeIfPresent(String.self, forKey: .rid) ?? ""
        trigger = try container.decodeIfPresent(String.self, forKey: .trigger) ?? ""
        bundleId = try container.decodeIfPresent(String.self, forKey: .bundleId) ?? ""
        fileType = try container.decodeIfPresent(String.self, forKey: .fileType) ?? ""
        itemData = try container.decodeIfPresent([String: String].self, forKey: .itemData) ?? [:]
        
        // 处理 menuItems - 由于包含 Any 类型，需要特殊处理
        if let menuItemsData = try container.decodeIfPresent(Data.self, forKey: .menuItems) {
            menuItems = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSDictionary.self, NSString.self, NSNumber.self], from: menuItemsData) as? [[String: Any]]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(target, forKey: .target)
        try container.encode(rid, forKey: .rid)
        try container.encode(trigger, forKey: .trigger)
        try container.encode(bundleId, forKey: .bundleId)
        try container.encode(fileType, forKey: .fileType)
        try container.encode(itemData, forKey: .itemData)
        
        // 处理 menuItems 编码
        if let menuItems = menuItems {
            let menuItemsData = try? NSKeyedArchiver.archivedData(withRootObject: menuItems, requiringSecureCoding: false)
            try container.encodeIfPresent(menuItemsData, forKey: .menuItems)
        }
    }
    
    init() {}
    
    init(action: String, target: [String] = [], rid: String = UUID().uuidString, trigger: String = "", bundleId: String = "", fileType: String = "", itemData: [String: String] = [:], menuItems: [[String: Any]]? = nil) {
        self.action = action
        self.target = target
        self.rid = rid
        self.trigger = trigger
        self.bundleId = bundleId
        self.fileType = fileType
        self.itemData = itemData
        self.menuItems = menuItems
    }
    
    public var description: String {
        return "MessagePayload(action: \(action), target: \(target), rid: \(rid), trigger: \(trigger), bundleId: \(bundleId), fileType: \(fileType), itemData: \(itemData))"
    }
}

class Messager {
    static let shared = Messager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.flutter_application_1", category: "Messager")
    
    let center: DistributedNotificationCenter = .default()
    var bus: [String: (_ payload: MessagePayload) -> Void] = [:]
    
    // 通知名称常量
    struct NotificationNames {
        static let finderToMain = "com.rfinder.finder-to-main"
        static let mainToFinder = "com.rfinder.main-to-finder"
        static let menuUpdate = "com.rfinder.menu-update"
    }
    
    private init() {
        logger.info("Messager 初始化完成")
    }
    
    func sendMessage(name: String, data: MessagePayload) {
        let message: String = createMessageData(messagePayload: data)
        logger.info("发送消息到 \(name, privacy: .public): \(data.description, privacy: .public)")
        center.postNotificationName(NSNotification.Name(name), object: message, userInfo: nil, deliverImmediately: true)
    }
    
    func createMessageData(messagePayload: MessagePayload) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(messagePayload)
            let messagePayloadString = String(data: data, encoding: .utf8) ?? ""
            return messagePayloadString
        } catch {
            logger.error("编码消息失败: \(error.localizedDescription, privacy: .public)")
            return ""
        }
    }
    
    func reconstructEntry(messagePayload: String) -> MessagePayload {
        guard let jsonData = messagePayload.data(using: .utf8) else {
            logger.warning("无法将消息字符串转换为数据")
            return MessagePayload()
        }
        
        do {
            let messagePayloadEntry = try JSONDecoder().decode(MessagePayload.self, from: jsonData)
            return messagePayloadEntry
        } catch {
            logger.warning("解码 MessagePayload 失败: \(error.localizedDescription, privacy: .public)，原始数据: \(messagePayload, privacy: .public)")
            return MessagePayload() // 返回默认实例以优雅处理错误
        }
    }
    
    func on(name: String, handler: @escaping (MessagePayload) -> Void) {
        center.addObserver(self, selector: #selector(receivedMessage(_:)), name: NSNotification.Name(name), object: nil)
        bus.updateValue(handler, forKey: name)
        logger.info("注册消息处理器: \(name, privacy: .public)")
    }
    
    @objc func receivedMessage(_ notification: NSNotification) {
        guard let messageString = notification.object as? String else {
            logger.warning("收到的通知对象不是字符串类型")
            return
        }
        
        let payload = reconstructEntry(messagePayload: messageString)
        logger.info("收到消息: \(notification.name.rawValue, privacy: .public) - \(payload.description, privacy: .public)")
        
        if let handler = bus[notification.name.rawValue] {
            handler(payload)
        } else {
            logger.warning("没有找到处理器: \(notification.name.rawValue, privacy: .public)")
        }
    }
    
    func removeObserver(name: String) {
        center.removeObserver(self, name: NSNotification.Name(name), object: nil)
        bus.removeValue(forKey: name)
        logger.info("移除消息处理器: \(name, privacy: .public)")
    }
    
    deinit {
        center.removeObserver(self)
        logger.info("Messager 已销毁")
    }
}

// MARK: - 便捷方法扩展
extension Messager {
    
    // Finder 扩展发送消息到主应用
    func sendToMainApp(action: ActionType, target: [String] = [], bundleId: String = "", fileType: String = "", itemData: [String: String] = [:]) {
        let payload = MessagePayload(
            action: action.rawValue,
            target: target,
            trigger: "finder-extension",
            bundleId: bundleId,
            fileType: fileType,
            itemData: itemData
        )
        sendMessage(name: NotificationNames.finderToMain, data: payload)
    }
    
    // 主应用发送消息到 Finder 扩展
    func sendToFinderExtension(action: ActionType, target: [String] = [], menuItems: [[String: Any]]? = nil) {
        let payload = MessagePayload(
            action: action.rawValue,
            target: target,
            trigger: "main-app",
            menuItems: menuItems
        )
        sendMessage(name: NotificationNames.mainToFinder, data: payload)
    }
    
    // 发送菜单更新
    func sendMenuUpdate(menuItems: [[String: Any]]) {
        let payload = MessagePayload(
            action: ActionType.menuUpdate.rawValue,
            trigger: "main-app",
            menuItems: menuItems
        )
        sendMessage(name: NotificationNames.menuUpdate, data: payload)
    }
}