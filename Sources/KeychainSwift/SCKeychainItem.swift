//
//  SCKeychainItem.swift
//  KeychainSwift
//
//  Created by Scott Little on 08/04/2026.
//

import AppKit
import KeychainBase

open class SCKeychainItem : NSObject {
	
	var rawDictionary : [String:Any]
	
	@objc public var legacyIdentifier: String?
	@objc public var accountInfoPassword: String?
	@objc public var migrationDirection: KeychainMigrationDirection = .none
	
	@objc public
	var passwordPII: String? {
		if let nsData = rawDictionary[KeychainSwiftConstants.valueData] as? NSData {
			return nsData.privacyRepresentation
		}
		return "<PII: NIL>"
	}
	
	@objc public
	var identifier: String? {
		let data = rawDictionary[KeychainSwiftConstants.returnReference] as? Data
		return data?.base64EncodedString()
	}
	
	@objc public
	var keychainType: KeychainType {
		let type = rawDictionary[KeychainSwiftConstants.keychainTypeKey] as? KeychainType
		return type ?? .typeiCloud
	}
	
	@objc public
	var service: String? {
		return rawDictionary[KeychainSwiftConstants.attrService] as? String
	}
	
	@objc public
	var label: String? {
		return rawDictionary[KeychainSwiftConstants.attrLabel] as? String
	}
	
	@objc public
	var account: String? {
		return rawDictionary[KeychainSwiftConstants.attrAccount] as? String
	}
	
	@objc public
	var isProvisional: Bool {
		return self.identifier == nil
	}
	
	@objc public
	var dictionaryRepresentation: [String :Any]? {
		return rawDictionary
	}
	
	@objc init(_ rep: [String:Any]) {
		self.rawDictionary = rep
	}
	
	@objc public
	func password() -> String? {
		if let passwordData = rawDictionary[KeychainSwiftConstants.valueData] as? Data {
			return String(data: passwordData, encoding: .utf8)
		}
		return accountInfoPassword
	}
	
	@objc public override var description:  String {
		var identifier = identifier ?? ""
		if identifier.count > 0 {
			identifier = " ID: \(identifier)"
		}
		else{
			identifier = "❗️PROVISIONAL"
		}
		let acct = account ?? "-"
		let srvc = service ?? "-"
		let lbl = label ?? "-"
		let keychain = keychainType == .typeiCloud ? "iCloud" : "File"
		let migration = migrationDirection == .toFile ? " -> File" : (migrationDirection == .toiCloud ? " -> iCloud" : "none")
		return super.description.appending("\(identifier) Account: \(acct) Service : \(srvc) Label: \(lbl)\nKeychain: \(keychain) [migration:\(migration)]")
	}
	
}
