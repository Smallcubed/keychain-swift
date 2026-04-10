import Security
import AppKit
import KeychainBase

/**
 
 This file can be used in your ObjC project if you want to use KeychainSwift Swift library.
 Extend this file to add other functionality for your app.
 
 How to use
 ----------
 
 1. Import swift code in your ObjC file:
 
 #import "YOUR_PRODUCT_MODULE_NAME-Swift.h"
 
 2. Use KeychainSwift in your ObjC code:
 
 - (void)viewDidLoad {
 [super viewDidLoad];
 
 KeychainSwiftCBridge *keychain = [[KeychainSwiftCBridge alloc] init];
 [keychain set:@"Hello World" forKey:@"my key"];
 NSString *value = [keychain get:@"my key"];
 
 3. You might need to remove `import KeychainSwift` import from this file in your project.
 
*/
@objc(KeychainSwift)
public class KeychainSwiftCBridge: NSObject {
	let keychain = KeychainSwift()
		
	@objc
	open var lastResultCode: OSStatus {
		get { return keychain.lastResultCode }
	}
	
	@objc
	open var keyPrefix: String {
		set { keychain.keyPrefix = newValue }
		get { return keychain.keyPrefix }
	}
	
	@objc
	open var accessGroup: String? {
		set { keychain.accessGroup = newValue }
		get { return keychain.accessGroup }
	}
	
	@objc
	open var synchronizable: Bool {
		set { keychain.synchronizable = newValue }
		get { return keychain.synchronizable }
	}
	
	@objc
	open var useFileKeychain: Bool {
		set { keychain.useFileKeychain = newValue }
		get { return keychain.useFileKeychain }
	}
	
	@objc
	open var overrideAccessOption: KeychainSwiftAccessOptions {
		set { keychain.overrideAccessOption = newValue }
		get { return keychain.overrideAccessOption }
	}

	
	@objc(setPassword:forKey:)
	@discardableResult
	open func set(_ value: String, forKey key: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key)
	}
	
	@objc(setPassword:forKey:service:)
	@discardableResult
	open func set(_ value: String, forKey key: String, service: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key, service: service)
	}
	
	@objc(setPassword:forKey:service:label:)
	@discardableResult
	open func set(_ value: String, forKey key: String, service: String, label: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key, service: service, label: label)
	}
	
	@objc(setData:forKey:)
	@discardableResult
	open func setData(_ value: Data, forKey key: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key)
	}
	
	@objc(setData:forKey:service:)
	@discardableResult
	open func setData(_ value: Data, forKey key: String, service: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key, service: service)
	}
	
	@objc(setData:forKey:service:label:)
	@discardableResult
	open func setData(_ value: Data, forKey key: String, service: String, label: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key, service: service, label: label)
	}
	
	@objc(setBool:forKey:)
	@discardableResult
	open func setBool(_ value: Bool, forKey key: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key)
	}
	
	@objc(setBool:forKey:service:)
	@discardableResult
	open func setBool(_ value: Bool, forKey key: String, service: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key, service: service)
	}
	
	@objc(setBool:forKey:service:label:)
	@discardableResult
	open func setBool(_ value: Bool, forKey key: String, service: String, label: String) -> SCKeychainItem? {
		return keychain.set(value, forKey: key, service: service, label: label)
	}
	
	@objc(passwordForKey:)
	open func get(_ key: String) -> String? {
		return keychain.get(key)
	}
	
	@objc(passwordForKey:service:)
	open func get(_ key: String, service: String) -> String? {
		return keychain.get(key, service: service)
	}
	
	@objc(passwordForKey:service:label:)
	open func get(_ key: String, service: String, label: String) -> String? {
		return keychain.get(key, service: service, label: label)
	}
	
	@objc(dataForKey:)
	open func getData(_ key: String) -> Data? {
		return keychain.getData(key)
	}
	
	@objc(dataForKey:service:)
	open func getData(_ key: String, service: String) -> Data? {
		return keychain.getData(key, service: service)
	}
	
	@objc(dataForKey:service:label:)
	open func getData(_ key: String, service: String, label: String) -> Data? {
		return keychain.getData(key, service: service, label: label)
	}

	@objc(boolForKey:)
	open func getBool(_ key: String) -> Bool {
		return keychain.getBool(key) ?? false
	}
	
	@objc(boolForKey:service:)
	open func getBool(_ key: String, service: String) -> Bool {
		return keychain.getBool(key, service: service) ?? false
	}
	
	@objc(boolForKey:service:label:)
	open func getBool(_ key: String, service: String, label: String) -> Bool {
		return keychain.getBool(key, service: service, label: label) ?? false
	}
	
	@objc(deleteForKey:)
	@discardableResult
	open func delete(_ key: String) -> Bool {
		return keychain.delete(key);
	}
	
	@objc(deleteForKey:service:)
	@discardableResult
	open func delete(_ key: String, service: String) -> Bool {
		return keychain.delete(key, service: service);
	}
	
	@objc(deleteForKey:service:label:)
	@discardableResult
	open func delete(_ key: String, service: String, label: String) -> Bool {
		return keychain.delete(key, service: service, label: label);
	}
	
	@discardableResult
	open func clear() -> Bool {
		return keychain.clear()
	}
	
	
	//	MARK: Legacy Management

	@objc(migratePasswordForKey:service:)
	@discardableResult
	open func migratePassword(_ key: String, service: String) -> String? {
		return keychain.migratePassword(key, service: service)
	}
	
	@objc(migratePasswordForKey:service:label:)
	@discardableResult
	open func migratePassword(_ key: String, service: String, label: String) -> String? {
		return keychain.migratePassword(key, service: service, label: label)
	}

	@objc(migrateDataForKey:service:)
	@discardableResult
	open func migrateData(_ key: String, service: String) -> Data? {
		return keychain.migrateData(key, service: service)
	}
	
	@objc(migrateDataForKey:service:label:)
	@discardableResult
	open func migrateData(_ key: String, service: String, label: String) -> Data? {
		return keychain.migrateData(key, service: service, label: label)
	}
	

	//	MARK: Account extension
	
	@objc(passwordForAccount:)
	open func password(account: KeychainAccount) -> String? {
		return keychain.password(account: account)
	}
	
	@objc(dataForAccount:)
	open func data(account: KeychainAccount) -> Data? {
		return keychain.data(account: account)
	}
	
	@objc(deletePasswordForAccount:)
	@discardableResult
	open func delete(account: KeychainAccount) -> Bool {
		return keychain.deletePassword(account: account)
	}
	
	@objc(deleteInfoForAccount:)
	@discardableResult
	open func deleteInfo(account: KeychainAccount) -> Bool {
		return keychain.deleteStore(account: account)
	}
	
	@objc(setPassword:forAccount:)
	@discardableResult
	open func set(_ value: String, forAccount account: KeychainAccount) -> SCKeychainItem? {
		return keychain.set(value, account: account)
	}
	
	@objc(setData:forAccount:)
	@discardableResult
	open func setData(_ value: Data, forAccount account: KeychainAccount) -> SCKeychainItem? {
		return keychain.set(value, account: account)
	}
	
	
	
	
//	@objc(entryWithIdentifier:)
//	open func entry(identifier:String) -> SCKeychainItem? {
//		let identifierData = NSData(fromBase64String: identifier) as Data
//		return keychain.get(identifierData)
//	}
//
//	@objc(deleteEntryWithIdentifier:)
//	@discardableResult
//	open func deleteEntryWithIdentifer(_ identifier:String?)-> Bool{
//		guard let identifier else {
//			return false
//		}
//		return keychain.delete(NSData(fromBase64String: identifier) as Data)
//	}
//	@objc(deleteEntry:)
//	@discardableResult
//	open func delete(entry:SCKeychainItem?)-> Bool{
//		if let entry,
//		   let identifier = entry.identifier{
//			return keychain.delete(NSData(fromBase64String: identifier) as Data)
//		}
//		return false
//	}
//	
//	@objc(retrieveInfoForAccount:)
//	open func retrieve(_ account: KeychainAccount) -> [String: Any]? {
//		return keychain.retrieve(account: account)
//	}
//	
//    @objc(fetchEntriesForAccount:)
//    open func fetch(_ account: KeychainAccount) -> [SCKeychainItem] {
//        return keychain.fetchEntriesFor(account.keychainAccountName)
//    }
//	
//    @objc
//    open func allEntriesByIdentifier() -> [String:SCKeychainItem] {
//        var  keysById: [String : SCKeychainItem] = [:]
//        for entry in keychain.allEntries {
//            if let identifier = entry.identifier {
//                keysById[identifier] = entry
//            }
//        }
//        return keysById
//    }
	
	@objc(passwordKeychainItemWithAccount:logger:)
	static public func passwordKeychainItem(account: KeychainAccount, logger: KeychainLogger) -> SCKeychainItem? {
		//	Pick the correct keychain
		let keychain = account.canSyncPassword ? NSApp.iCloudKeychain.keychain : NSApp.fileKeychain.keychain;
		
		//	First try to get the item diretly using the identifier
		if let identifier = account.property(forKey: KeychainSwiftConstants.accountIdentifierKey) as? String, !identifier.isEmpty {
			logger.log(string:"Requesting existing keychainItem for account: \(account) keychainIdentifier: \(identifier)")
			let entry = keychain.get(identifier)
			if entry == nil {
				logger.log(string:"🛑 [Keychain] No Keychain Item Found using Identifier: \(identifier)")
			}
			else {
				logger.log(string:"🟢 Returning existing keychainItem: \(String(describing: entry)) (password: \(String(describing: entry?.passwordPII))")
				return entry
			}
		}
		
		//	Then search through all of the entries to find a match based on the identifier
		let entries = keychain.fetchEntriesFor(account.keychainAccountName)
		for localEntry in entries {
			if localEntry.service == account.keychainServiceName {
				logger.log(string:"🟢 Found candidate keychainItem: \(localEntry)")
				if let ident = localEntry.identifier {
					account.set(property: ident, forKey: KeychainSwiftConstants.accountIdentifierKey)
				}
				return localEntry
			}
		}
		
		//	Then search through the legacy service names
		for localEntry in entries {
			if localEntry.service == account.keychainLegacyServiceName {
				logger.log(string:"🟢 Found candidate keychainItem for account: \(account.displayName) : \(localEntry)")
				if let ident = localEntry.identifier {
					account.set(property: ident, forKey: KeychainSwiftConstants.accountIdentifierKey)
				}
				if let provisionalEntry = SCKeychainAccountItem(account, provisionalPassword: localEntry.password ?? "") {
					provisionalEntry.legacyIdentifier = localEntry.identifier
					return provisionalEntry
				}
			}
		}
		
		//	Fallback to the standard method of getting the keychain info for the account
		//	Why is this provisional though if it was retreived from the keychain?
		if let info = keychain.retrieve(account: account),
		   let infoPassword = info[KeychainSwiftConstants.valueData] as? String {
			if let provisionalEntry = SCKeychainAccountItem(account, provisionalPassword: infoPassword) {
				logger.log(string:"🟢 Found password \(String(describing: infoPassword.privacyRepresentation)) in account info for account: \(account) returning provisional item: \(provisionalEntry)")
				return provisionalEntry
			}
		}
		return nil
	}
	
	@objc(saveItem:logger:)
	static public func save(item: SCKeychainItem, logger: KeychainLogger) -> SCKeychainItem? {
		//	Ensure that the various values are properly set on the item
		guard let pw = item.password, !pw.isEmpty else {
			logger.log(string: "🛑 Keychain item does not have a password set: \(item)")
			return nil
		}
		
		//	Get the correct keychain
		let keychain = Self.keychain(for: item)

		//	Was in provisional state, try to persist it
		if item.isProvisional {
			logger.log(string: "🟢 successfully authenticated with provisional password \(String(describing: item.passwordPII))!  Writing it to keychain")
			let savedItem = keychain.set(pw, forKey: item.account, service: item.service, label: item.label)
			if let savedItem {
//				keychain.store(item: savedItem)
				logger.log(string: "🟢 Saved new password to item with identifier \(String(describing: savedItem.identifier))")
				if pw == savedItem.password {
					logger.log(string: "🟢 Provisional password appears to have been saved to keychain")
					return savedItem
				}
			} else {
				logger.log(string: "🛑 New password appears not to have been saved to keychain")
			}
		}
		//	Otherwise nothing to do, except return original item
		else {
			logger.log(string: "🟢 Successfully authenticated with Keychain Item \(item) Using \(String(describing: item.passwordPII))")
			return item
		}
		
		return nil
	}
	
	@discardableResult
	@objc(deleteItem:logger:)
	static public func delete(item: SCKeychainItem, logger: KeychainLogger) -> Bool {
		//	Ensure that the various values are properly set on the item
		guard let identifier = item.identifier else {
			logger.log(string: "🛑 Keychain item does not have values set: \(item)")
			return false
		}
		
		//	Get the correct keychain
		let keychain = Self.keychain(for: item)

		//	Delete by using the identifier
		let deleted = keychain.delete(NSData(fromBase64String: identifier) as Data)
		logger.log(string: "The item \(item) was \(deleted ? "successfully" : "not successfully") deleted from the keychain")
		
		//	Returns true if EITHER happened
		return deleted
	}

	@discardableResult
	@objc(deleteInfoForItem:logger:)
	static public func deleteInfo(item: SCKeychainItem, logger: KeychainLogger) -> Bool {
		//	Get the correct keychain
		let keychain = Self.keychain(for: item)
		
		//	Delete the account info
		let deleted = keychain.deleteStore(item: item)
		logger.log(string: "The account info was \(deleted ? "successfully" : "not successfully") deleted for \(item) from the keychain")
		
		//	Returns true if EITHER happened
		return deleted
	}
	
	static func keychain(for item: SCKeychainItem) -> KeychainSwift {
		var keychain = NSApp.iCloudKeychain.keychain
		switch (item.keychainType) {
		case .typeFile:
			keychain = NSApp.fileKeychain.keychain
			
		case .typeiCloud:
			break
			
		default:
			break
		}
		return keychain
	}
	
}
