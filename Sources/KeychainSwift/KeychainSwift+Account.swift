//
//  KeychainSwift+Account.swift
//
//
//  Created by Scott Little on 11/09/2023.
//

import Foundation
import KeychainBase

extension KeychainSwift {
	
	func password(account: KeychainAccount, service: String? = nil) -> String? {
		if let pw = get(account.keychainAccountName, service: service ?? account.keychainServiceName, label: account.keychainLabelName) {
			return pw
		}
		if let pw = migratePassword(account.keychainAccountName, service: service ?? account.keychainServiceName, label: account.keychainLabelName) {
			return pw
		}
		if let label = account.keychainLegacyName {
			return get(account.keychainAccountName, service: service ?? account.keychainServiceName, label: label)
		}
		return nil
	}
	
	func data(account: KeychainAccount) -> Data? {
		guard let data = getData(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName) else {
			return migrateData(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
		}
		return data
	}
	
	func deletePassword(account: KeychainAccount) -> Bool {
		return delete(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
	}
	
	func set(_ password: String, account: KeychainAccount) -> Bool {
		if let value = password.data(using: String.Encoding.utf8) {
			return set(value, account: account)
		}
		return false
	}
	
	func set(_ passwordData: Data, account: KeychainAccount) -> Bool {
		store(account: account)
		return set(passwordData, forKey: account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
	}
	
	//	MARK: - All Account Info
	
	func retrieve(account: KeychainAccount) -> [String: Any]? {
		guard let data = data(account: account) else {
			return nil
		}
		do {
			let decoder = JSONDecoder()
			let model = try decoder.decode(AccountModel.self, from: data)
			return model.dict()
		}
		catch {
			print("Error decoding Accountmodel: \(error)")
		}
		return nil
	}
	
	@discardableResult
	func store(account: KeychainAccount) -> Bool {
		guard let passwordData = account.loginPassword.data(using: String.Encoding.utf8) else {
			return false
		}
		var smtpIdent: String? = nil
		if let acct = account as? KeychainWithSMTPAccount {
			smtpIdent = acct.preferredSMTPAccountIdentifier
		}
		let model = AccountModel(passwordData: passwordData, host: account.hostname, port: account.portNumber, ssl: account.ssl, login: account.loginName, smtpIdent: smtpIdent)
		do {
			let encoder = JSONEncoder()
			let data: Data = try encoder.encode(model)
			return set(data, forKey: account.keychainAccountName, service: "\(AccountModel.serviceKey): \(account.keychainServiceName)", label: account.keychainLabelName)
		}
		catch {
			print("Error encoding Accountmodel: \(error)")
		}
		return false
	}
	
}

struct AccountModel: Codable {
	static let serviceKey = "AccountInfo"
	
	var passwordData: Data
	var host: String
	var port: Int
	var ssl: Bool
	var login: String
	var smtpIdent: String?

	func dict() -> [String: Any]? {
		guard let password = String(data: passwordData, encoding: .utf8) else {
			return nil
		}
		var res: [String: Any] = [
			"password": password,
			"host": host,
			"login": login,
			"port": port,
			"ssl": ssl,
		]
		if let smtpIdent {
			res["smtpIdent"] = smtpIdent
		}
		return res
	}
}
