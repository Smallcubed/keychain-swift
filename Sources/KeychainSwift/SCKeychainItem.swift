//
//  SCKeychainItem.swift
//  KeychainSwift
//
//  Created by Scott Little on 08/04/2026.
//

import AppKit
import KeychainBase

public class SCKeychainItem : NSObject {
	
	@objc public var account: String
	@objc public var service: String
	@objc public var label: String
	@objc public var keychainType: KeychainType
	@objc public var legacyIdentifier: String?

	@objc public var accountInfoPassword: String?
	@objc public var migrationDirection: KeychainMigrationDirection = .none

	private var _id: Data?
	private var _pw: Data?

	@objc public
	var passwordPII: String {
		if let nsData = self._pw as? NSData {
			return nsData.privacyRepresentation
		}
		return "<PII: NIL>"
	}
	
	@objc public
	var identifier: String? {
		return self._id?.base64EncodedString()
	}
	
	@objc public
	var password: String? {
		if let passwordData = self._pw {
			return String(data: passwordData, encoding: .utf8)
		}
		return accountInfoPassword
	}
	
	@objc public
	var isProvisional: Bool {
		return self.identifier == nil
	}
	
	@objc init?(_ rep: [String:Any]) {
		guard let account = rep[KeychainSwiftConstants.attrAccount] as? String else {
			fatalError("KeychainItem must contain an 'account' key")
		}
		guard let service = rep[KeychainSwiftConstants.attrService] as? String else {
			fatalError("KeychainItem must contain a 'service' key")
		}
		guard let label = rep[KeychainSwiftConstants.attrLabel] as? String else {
			fatalError("KeychainItem must contain a 'label' key")
		}
		self.account = account
		self.service = service
		self.label = label
		self.legacyIdentifier = rep[KeychainSwiftConstants.attrService] as? String
		self.accountInfoPassword = rep[KeychainSwiftConstants.valueData] as? String
		self.keychainType = .typeiCloud
		if let raw = [KeychainSwiftConstants.keychainTypeKey] as? Int {
			self.keychainType = KeychainType(rawValue: raw) ?? .typeiCloud
		}
	}
	
	@objc public override var description:  String {
		var identifier = identifier ?? ""
		if identifier.count > 0 {
			identifier = " ID: \(identifier)"
		}
		else {
			identifier = "❗️PROVISIONAL"
		}
		let acct = account
		let srvc = service
		let lbl = label
		let keychain = keychainType == .typeiCloud ? "iCloud" : "File"
		let migration = migrationDirection == .toFile ? " -> File" : (migrationDirection == .toiCloud ? " -> iCloud" : "none")
		return super.description.appending("\(identifier) Account: \(acct) Service : \(srvc) Label: \(lbl)\nKeychain: \(keychain) [migration:\(migration)]\nValue: \(passwordPII)")
	}
	
}


public class SCKeychainAccountItem: SCKeychainItem, KeychainAccountInfo {
	
	public var hostname: String {
		_account.hostname
	}
	public var keychainHostName: String {
		_account.keychainHostName
	}
	public var portNumber: Int {
		_account.portNumber
	}
	public var ssl: Bool {
		_account.ssl
	}
	public var loginName: String {
		_account.loginName
	}
	public var loginPassword: String? {
		self.password
	}
	public var authenticationMethod: String {
		_account.authenticationMethod
	}
	public var displayName: String {
		_account.displayName
	}
	
	private var _account: KeychainAccount

	@objc(initWithAccount:provisionalPassword:)
	public init?(_ account: KeychainAccount, provisionalPassword: String) {
		var rep : [String : Any] = [:]
		rep[KeychainSwiftConstants.valueData] = provisionalPassword.data(using: .utf8)
		rep[KeychainSwiftConstants.attrLabel] = account.keychainLabelName
		rep[KeychainSwiftConstants.attrAccount] = account.keychainAccountName
		rep[KeychainSwiftConstants.attrService] = account.keychainServiceName
		rep[KeychainSwiftConstants.keychainTypeKey] = account.canSyncPassword ? KeychainType.typeiCloud : KeychainType.typeFile
		self._account = account
		super.init(rep)
	}
	
	public init?(_ account: KeychainAccount, accountInfoPassword: String) {
		var rep : [String : Any] = [:]
		rep[KeychainSwiftConstants.attrLabel] = account.keychainLabelName
		rep[KeychainSwiftConstants.attrAccount] = account.keychainAccountName
		rep[KeychainSwiftConstants.attrService] = account.keychainServiceName
		rep[KeychainSwiftConstants.keychainTypeKey] = account.canSyncPassword ? KeychainType.typeiCloud : KeychainType.typeFile
		self._account = account
		super.init(rep)
		self.accountInfoPassword = accountInfoPassword
	}
	
}
