//
//  KeyChain.swift
//  SimpleXChat
//
//  Created by Evgeny on 04/09/2022.
//  Copyright © 2022 SimpleX Chat. All rights reserved.
//

import Foundation
import Security

private let ACCESS_POLICY: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
// nil when the Info.plist value is missing/unresolved/invalid: every Keychain operation then fails closed.
#if targetEnvironment(simulator)
private let ACCESS_GROUP: String? = fastChatConfigValue(FastChatConfigKey.keychainAccessGroup)
#else
private let ACCESS_GROUP: String? = fastChatConfigValue(FastChatConfigKey.keychainAccessGroup, requireTeamPrefix: true)
#endif
private let DATABASE_PASSWORD_ITEM: String = "databasePassword"
private let APP_PASSWORD_ITEM: String = "appPassword"
private let SELF_DESTRUCT_PASSWORD_ITEM: String = "selfDestructPassword"

public let kcDatabasePassword = KeyChainItem(forKey: DATABASE_PASSWORD_ITEM)

public let kcAppPassword = KeyChainItem(forKey: APP_PASSWORD_ITEM)

public let kcSelfDestructPassword = KeyChainItem(forKey: SELF_DESTRUCT_PASSWORD_ITEM)

public struct KeyChainItem {
    var forKey: String

    public func get() -> String? {
        getItemString(forKey: forKey)
    }

    public func set(_ value: String) -> Bool {
        setItemString(value, forKey: forKey)
    }

    public func remove() -> Bool {
        deleteItem(forKey: forKey)
    }
}

func randomDatabasePassword() -> String {
    var keyData = Data(count: 32)
    let status = keyData.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
    }
    if status == errSecSuccess {
        return keyData.base64EncodedString()
    } else {
        logger.error("randomDatabasePassword: error \(status)")
        return ""
    }
}

private func getItemData(forKey key: String) -> Data? {
    guard ACCESS_GROUP != nil else {
        logger.error("getItemData: keychain access group is not configured, refusing to read '\(key)'")
        return nil
    }
    var query = baseItemQuery(forKey: key)
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = true as AnyObject?

    var dataRef: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
    if status != errSecSuccess && status != errSecItemNotFound {
        logger.error("getItemData: error getting data for key '\(key)', error: \(status)")
    }
    return dataRef as? Data
}

private func getItemString(forKey key: String) -> String? {
    if let data = getItemData(forKey: key) {
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
    }
    return nil
}

private func setItemData(_ data: Data, forKey key: String) -> Bool {
    guard ACCESS_GROUP != nil else {
        logger.error("setItemData: keychain access group is not configured, refusing to store '\(key)'")
        return false
    }
    var query = baseItemQuery(forKey: key)
    var update = [NSString : AnyObject]()
    update[kSecValueData] = data as AnyObject?
    update[kSecAttrAccessible] = ACCESS_POLICY
    var status: OSStatus
    if getItemData(forKey: key) == nil {
        for (key, value) in update { query[key] = value }
        status = SecItemAdd(query as CFDictionary, nil)
    } else {
        status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
    }
    if status != errSecSuccess {
        logger.error("setItemData: error setting data for key '\(key)', error: \(status)")
        return false
    }
    return true
}

private func setItemString(_ s: String, forKey key: String) -> Bool {
    if let data = s.data(using: .utf8) {
        return setItemData(data, forKey: key)
    }
    return false
}

private func deleteItem(forKey key: String) -> Bool {
    guard ACCESS_GROUP != nil else {
        logger.error("deleteItem: keychain access group is not configured, refusing to delete '\(key)'")
        return false
    }
    let query = baseItemQuery(forKey: key)
    if getItemData(forKey: key) != nil {
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            logger.error("deleteItem: error deleting data for key '\(key)', error: \(status)")
            return false
        }
    }
    return true
}

private func baseItemQuery(forKey key: String) -> [NSString : AnyObject] {
    var query = [NSString : AnyObject]()
    query[kSecClass] = kSecClassGenericPassword
    query[kSecAttrAccount] = key as AnyObject?
    #if TARGET_OS_IOS && !TARGET_OS_SIMULATOR
        query[kSecAttrAccessGroup] = ACCESS_GROUP as AnyObject?
    #endif
    return query
}
