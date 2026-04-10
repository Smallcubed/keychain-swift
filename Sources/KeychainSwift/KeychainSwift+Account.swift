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
        let service = service ?? account.keychainServiceName
		if let pw = get(account.keychainAccountName, service: service, label: account.keychainLabelName) {
            let logValue = (pw.data(using: .utf8) as? NSData)?.privacyRepresentation ?? ""
            
            log(string: "[Keychain] FOUND pw \(logValue) for Name: \(account.keychainAccountName) s:\(service) l:\(account.keychainLabelName) account:\(account)")
			return pw
		}
      
		if let pw = migratePassword(account.keychainAccountName, service: service, label: account.keychainLabelName) {
            let logValue = (pw.data(using: .utf8) as? NSData)?.privacyRepresentation ?? ""
           
            log(string: "[Keychain] Migrated pw \(logValue) for \(account.keychainAccountName) s:\(service) l:\(account.keychainLabelName) account: \(account)")
			return pw
		}
        // legacy account identifiers for smtp account
        // for a time period smtp accounts used associated incoming (IMAP) account name and label for
        // accessing keychain data.
        // This is incorrect and should be updated.
        
        let legacyService = account.keychainLegacyServiceName
        if let legacyName = account.keychainLegacyAccountName,
           let legacyLabel = account.keychainLegacyLabel ,
           let pw = get(legacyName, service: legacyService, label: legacyLabel){
            // shoud we migrate this pw into the current format?
            
            let logValue = (pw.data(using: .utf8) as? NSData)?.privacyRepresentation ?? ""
            
            log(string: "[Keychain] FOUND pw \(logValue) for LEGACYNAME \(legacyName) s:\(service) l:\(legacyLabel) account: \(account)")
            set(pw, forKey: account.keychainAccountName, service: service, label: account.keychainLabelName)
            if let rereadPw = get(account.keychainAccountName, service: service, label: account.keychainLabelName){
                
                if (rereadPw == pw){
                    log(string: "[Keychain] Migrated pw \(logValue) to \(account.keychainAccountName) s:\(service) l:\(account.keychainLabelName) account: \(account)")
                    return rereadPw
                }
            }
            return pw
        }
        if (account.authenticationMethod != "XOAUTH2"){
            log(string: "[Keychain] 🛑 NO pw for \(account.keychainAccountName)")
        }
		return nil
	}
	
	func data(account: KeychainAccount) -> Data? {
        if let data = getData(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName) {
            let logValue = (data as NSData).privacyRepresentation
            log(string: "[Keychain] FOUND data \(logValue) for \(account.keychainAccountName) s:\(account.keychainServiceName) l:\(account.keychainLabelName)")
            
            return data
        }
        if let data =  migrateData(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName) {
            let logValue = (data as NSData).privacyRepresentation
            log(string: "[Keychain] Migrated data \(logValue) for \(account.keychainAccountName) s:\(account.keychainServiceName) l:\(account.keychainLabelName)")
    
            return data
		}
        if let accountName = account.keychainLegacyAccountName, let label = account.keychainLegacyLabel ,
           let data = getData(accountName, service: account.keychainServiceName, label: label){
            // shoud we migrate this pw into the current format?
            let logValue = (data as NSData).privacyRepresentation
            log(string: "[Keychain] FOUND data \(logValue) for LEGACY \(accountName) s:\(account.keychainServiceName) l:\(label)")
      
            return data
        }
        if (account.authenticationMethod == "XOAUTH2"){
            log(string: "[Keychain] 🛑 NO data for \(account.keychainAccountName)")
        }
      	return nil
	}
	
	func deletePassword(account: KeychainAccount) -> Bool {
		return delete(account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
	}
	
	func set(_ password: String, account: KeychainAccount) -> SCKeychainItem? {
		if let value = password.data(using: String.Encoding.utf8) {
			return set(value, account: account)
		}
		return nil
	}
	
	func set(_ passwordData: Data, account: KeychainAccount) -> SCKeychainItem? {
		let result = set(passwordData, forKey: account.keychainAccountName, service: account.keychainServiceName, label: account.keychainLabelName)
//		account.resetInternalPassword()
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
            account.currentAccountInfoHash = (data as NSData).sha256String()
			return model.dict()
		}
		catch {
			print("Error decoding Accountmodel: \(error)")
		}
		return nil
	}
	
	@discardableResult
	func store(account: KeychainAccount) -> SCKeychainItem? {
        if (account.currentAccountInfoHash == nil) {
            let _ = retrieve(account: account)
        }
		guard let passwordData = account.loginPassword?.data(using: String.Encoding.utf8) else {
			return nil
		}
		var smtpIdent: String? = nil
		if let acct = account as? KeychainWithSMTPAccount,
           let acctSmtpIdent = acct.preferredSMTPAccountIdentifier,
           acctSmtpIdent.count>0{
			smtpIdent = acctSmtpIdent
		}
		let model = AccountModel(passwordData: passwordData, 
                                 host: account.keychainHostName,
                                 port: account.portNumber,
                                 ssl: account.ssl,
                                 login: account.loginName,
                                 smtpIdent: smtpIdent)
		do {
			let encoder = JSONEncoder()
			let data: Data = try encoder.encode(model)
            let hash = (data as NSData).sha256String()
            if (hash != account.currentAccountInfoHash){
                account.currentAccountInfoHash = hash
                return set(data, forKey: account.keychainAccountName, service: "\(AccountModel.serviceKey): \(account.keychainServiceName)", label: "\(account.keychainLabelName) (\(AccountModel.serviceKey))")
            }
		}
		catch {
			print("Error encoding Accountmodel: \(error)")
		}
		return nil
	}
	
	func deleteStore(account: KeychainAccount) -> Bool {
		guard let item = SCKeychainAccountItem(account, provisionalPassword: "") else {
			return false
		}
		return deleteStore(item: item)
	}
	
	func deleteStore(item: SCKeychainItem) -> Bool {
		return delete(item.account, service: "\(AccountModel.serviceKey): \(item.service)", label: "\(item.label) (\(AccountModel.serviceKey))")
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
            "version" : 1,
			"password": password,
			"host": host,
			"login": login,
			"port": port,
			"ssl": ssl,
		]
        if let smtpIdent,
           smtpIdent.count>0{
			res["smtpIdent"] = smtpIdent
		}
		return res
	}
}


