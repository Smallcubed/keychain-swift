//
//  SCKeychainItem.swift
//  KeychainSwift
//
//  Created by Scott Little on 08/04/2026.
//

import AppKit
import KeychainBase
import SCBaseKit

public class SCKeychainItem : NSObject {
	
	@objc public var accountName: String
	@objc public var service: String
	@objc public var label: String
	@objc public var keychainType: KeychainType

	@objc public var migrationDirection: KeychainMigrationDirection = .none
	@objc public var legacyIdentifier: String?

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
		return nil
	}
	
	@objc public
	var isProvisional: Bool {
		return self.identifier == nil
	}
	
	@objc init?(_ rep: [String:Any]) {
		guard let account = rep[KeychainSwiftConstants.attrAccount] as? String,
			  let service = rep[KeychainSwiftConstants.attrService] as? String
		else {
			SCLogger(forSubsystem: "Authorization")?.log(string: "Either account or service was missing from the dictionary. Non valid KeychainItem")
			return nil
		}

		self._id = rep[KeychainSwiftConstants.valuePersistentRef] as? Data
		self._pw = rep[KeychainSwiftConstants.valueData] as? Data
		self.accountName = account
		self.service = service
		self.label = rep[KeychainSwiftConstants.attrLabel] as? String ?? ""
		self.keychainType = rep[KeychainSwiftConstants.keychainTypeKey] as? KeychainType ?? .typeiCloud
		if let raw = [KeychainSwiftConstants.keychainTypeKey] as? Int {
			self.keychainType = KeychainType(rawValue: raw) ?? .typeiCloud
		}
	}
	
	@objc public override var description:  String {
		var identifier = identifier ?? ""
		if identifier.count > 0 {
			identifier = "ID: \(identifier)"
		}
		else {
			identifier = "❗️PROVISIONAL"
		}
		let acct = accountName
		let srvc = service
		let lbl = label
		let keychain = keychainType == .typeiCloud ? "iCloud" : "File"
		let migration = migrationDirection == .toFile ? " -> File" : (migrationDirection == .toiCloud ? " -> iCloud" : "none")
		return "\(Self.className()): \(identifier) [legacy:\(legacyIdentifier ?? "-")]\nAccount: '\(acct)' Service: '\(srvc)' Label: '\(lbl)'\nKeychain: \(keychain) [migration:\(migration)]\nValue: \(passwordPII)"
	}
	
}


public class SCKeychainAccountItem: SCKeychainItem, KeychainAccountInfo {
	
	public var account: KeychainAccount {
		_account!
	}
	public var displayName: String {
		_account!.displayName
	}
	public var loginName: String {
		_account!.loginName
	}
	public var hostname: String {
		_account!.hostname
	}
	public var authenticationMethod: String {
		_account!.authenticationMethod
	}
	public var portNumber: Int {
		_account!.portNumber
	}
	public var ssl: Bool {
		_account!.ssl
	}
	public var keychainHostName: String {
		_account!.keychainHostName
	}
	
	//	Created as optional to create a weak reference
	private var _account: KeychainAccount?
	
	public override var legacyIdentifier: String? {
		get {
			self._account?.migrationPreviousIdentifier ?? super.legacyIdentifier
		}
		set {
			super.legacyIdentifier = newValue
		}
	}

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
		self.migrationDirection = account.migDirection
		self.legacyIdentifier = account.migrationPreviousIdentifier
	}
	
	public init(account: KeychainAccount, keychainItem: SCKeychainItem) {
		var rep : [String : Any] = [:]
		if let pw = keychainItem.password?.data(using: .utf8) {
			rep[KeychainSwiftConstants.valueData] = pw
		}
		if let ident = keychainItem.identifier {
			rep[KeychainSwiftConstants.valuePersistentRef] = NSData(fromBase64String: ident)
		}
		rep[KeychainSwiftConstants.attrLabel] = keychainItem.label
		rep[KeychainSwiftConstants.attrAccount] = keychainItem.accountName
		rep[KeychainSwiftConstants.attrService] = keychainItem.service
		rep[KeychainSwiftConstants.keychainTypeKey] = account.canSyncPassword ? KeychainType.typeiCloud : KeychainType.typeFile
		self._account = account
		super.init(rep)!
		self.migrationDirection = account.migDirection
		self.legacyIdentifier = account.migrationPreviousIdentifier
	}
	
	@objc public override var description:  String {
		return super.description.appending("\nAccount Info — Name: '\(displayName)' Login Name: '\(loginName)' Host: '\(hostname)'\nAuth: \(authenticationMethod) Port: \(portNumber) SSL: \(ssl)\nKeychain Host: '\(keychainHostName)'")
	}
}
