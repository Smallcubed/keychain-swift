//
//  KeychainSwift+Account.swift
//
//
//  Created by Scott Little on 11/09/2023.
//

import Foundation
import KeychainBase
import SCBaseKit

extension KeychainSwift {
	
	func password(account: KeychainAccount, service: String? = nil) -> String? {
		if let pw = get(account.keychainAccountName, service: service ?? account.keychainServiceName, label: account.keychainLabelName) {
            let logValue = (pw.data(using: .utf8) as? NSData)?.randomTruncatedSHAHash ?? ""
            
            log(string: "FOUND pw \(logValue) for \(account.keychainAccountName)")
			return pw
		}
      
		if let pw = migratePassword(account.keychainAccountName, service: service ?? account.keychainServiceName, label: account.keychainLabelName) {
            let logValue = (pw.data(using: .utf8) as? NSData)?.randomTruncatedSHAHash ?? ""
           
            log(string: "Migrated pw \(logValue) for \(account.keychainAccountName)")
			return pw
		}
        if let accountName = account.keychainLegacyAccountName, let label = account.keychainLegacyLabel ,
           let pw = get(accountName, service: service ?? account.keychainServiceName, label: label){
            // shoud we migrate this pw into the current format?
            let logValue = (pw.data(using: .utf8) as? NSData)?.randomTruncatedSHAHash ?? ""
            log(string: "FOUND LEGACY pw \(logValue) for \(account.keychainAccountName)")
            return pw
        }
        if (account.authenticationMethod != "XOAUTH2"){
            log(string: "🛑 NO pw for \(account.keychainAccountName)")
        }
		return nil
	}
	
	func data(account: KeychainAccount) -> Data? {
		guard let data = getData(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName) else {
            
			let migratedData =  migrateData(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
            let logValue = (migratedData as? NSData)?.randomTruncatedSHAHash ?? ""
           
            log(string: "MIGRATED data \(logValue) for \(account.keychainAccountName)")
            return migratedData
		}
        log(string: "FOUND data \((data as NSData).randomTruncatedSHAHash) for \(account.keychainAccountName) ")
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
		let result = set(passwordData, forKey: account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
		account.resetInternalPassword()
		store(account: account)
		return result
	}
	
	//	MARK: - All Account Info
	
	func retrieve(account: KeychainAccount) -> [String: Any]? {
		//	Use the getData method directly in order to override the service and label
		guard let data = getData(account.keychainAccountName, service: "\(AccountModel.serviceKey): \(account.keychainServiceName)", label: "\(account.keychainLabelName) (\(AccountModel.serviceKey))") else {
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
			return set(data, forKey: account.keychainAccountName, service: "\(AccountModel.serviceKey): \(account.keychainServiceName)", label: "\(account.keychainLabelName) (\(AccountModel.serviceKey))")
		}
		catch {
			print("Error encoding Accountmodel: \(error)")
		}
		return false
	}
	
	func deleteStore(account: KeychainAccount) -> Bool {
		return delete(account.keychainAccountName, service: "\(AccountModel.serviceKey): \(account.keychainServiceName)", label: "\(account.keychainLabelName) (\(AccountModel.serviceKey))")
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
