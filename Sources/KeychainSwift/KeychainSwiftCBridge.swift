import Security
import AppKit
import SCBaseKit
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
		
	//	MARK: - Pass-Thru Variables
	
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

	
	//	MARK: - Setting
	
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
	
	//	MARK: - Retrieval
	
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
	
	//	MARK: - Deletion
	
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
	
	
	//	MARK: - Legacy Management

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
	

	//	MARK: - Account extension
	
//	@objc(passwordForAccount:)
//	open func password(account: KeychainAccount) -> String? {
//		return keychain.password(account: account)
//	}
//	
//	@objc(dataForAccount:)
//	open func data(account: KeychainAccount) -> Data? {
//		return keychain.data(account: account)
//	}
//	
//	@objc(deletePasswordForAccount:)
//	@discardableResult
//	open func delete(account: KeychainAccount) -> Bool {
//		return keychain.deletePassword(account: account)
//	}
//	
//	@objc(deleteInfoForAccount:)
//	@discardableResult
//	open func deleteInfo(account: KeychainAccount) -> Bool {
//		return keychain.deleteStore(account: account)
//	}
//	
//	@objc(setPassword:forAccount:)
//	@discardableResult
//	open func set(_ value: String, forAccount account: KeychainAccount) -> SCKeychainItem? {
//		return keychain.set(value, account: account)
//	}
//	
//	@objc(setData:forAccount:)
//	@discardableResult
//	open func setData(_ value: Data, forAccount account: KeychainAccount) -> SCKeychainItem? {
//		return keychain.set(value, account: account)
//	}
	
	@objc(dataForAccount:)
	static public func data(account: KeychainAccount) -> Data? {
		//	Pick the correct keychain
		var keychain = NSApp.iCloudKeychain.keychain
		var shouldTryiCloudAsWell = false
		if !account.canSyncPassword {
			keychain = NSApp.fileKeychain.keychain
			if account.authenticationMethod == "XOAUTH2" {
				shouldTryiCloudAsWell = true
			}
		}
		let value = keychain.data(account: account)
		if let value {
			return value
		}
		if shouldTryiCloudAsWell {
			return NSApp.iCloudKeychain.keychain.data(account: account)
		}
		return nil
	}

	@discardableResult
	@objc(saveData:forAccount:)
	static public func save(data: Data, account: KeychainAccount) -> SCKeychainItem? {
		//	Pick the correct keychain
		let keychain = account.canSyncPassword ? NSApp.iCloudKeychain.keychain : NSApp.fileKeychain.keychain;
		return keychain.set(data, account: account)
	}
	
	//	MARK: - Class methods for acting on Keychain Items
	
	@objc(passwordKeychainItemWithAccount:)
	static public func passwordKeychainItem(account: KeychainAccount) -> SCKeychainItem? {
		//	Pick the correct keychain
		let keychain = account.canSyncPassword ? NSApp.iCloudKeychain.keychain : NSApp.fileKeychain.keychain;
		
		//	First try to get the item diretly using the identifier
		if let identifier = account.property(forKey: KeychainSwiftConstants.accountIdentifierKey) as? String, !identifier.isEmpty {
			keychain.log(string:"Requesting existing keychainItem for account: \(account) keychainIdentifier: \(identifier)")
			let item = keychain.get(identifier)
			if let item {
				keychain.log(string:"🟢 Returning existing keychainItem: \(String(describing: item)) (password: \(String(describing: item.passwordPII))")
				return SCKeychainAccountItem(account: account, keychainItem: item)
			}
			else {
				keychain.log(string:"🛑 [Keychain] No Keychain Item Found using Identifier: \(identifier)")
			}
		}
		
		//	Fallback to the standard method of getting the password for the account
		if let item = keychain.get(account: account) {
			let accountItem = SCKeychainAccountItem(account: account, keychainItem: item)
			keychain.log(string:"🟢 Found password \(item.passwordPII) in using accountName/service/label for account: \(account) returning item: \(accountItem)")
			return accountItem
		}

		//	Then search through all of the entries to find a match based on the identifier
		let entries = keychain.fetchEntriesFor(account.keychainAccountName)
		keychain.log(string: "🟢 Found \(entries.count) candidate keychainItems")
		for localEntry in entries {
			if localEntry.service == account.keychainServiceName {
				keychain.log(string:"🟢 Found candidate keychainItem: \(localEntry)")
				if let ident = localEntry.identifier {
					account.set(property: ident, forKey: KeychainSwiftConstants.accountIdentifierKey)
				}
				return localEntry
			}
		}
		
		//	Then search through the legacy service names
		for localEntry in entries {
			if localEntry.service == account.keychainLegacyServiceName {
				keychain.log(string:"🟢 Found legacy candidate keychainItem for account: \(account.displayName) : \(localEntry)")
				if let provisionalEntry = SCKeychainAccountItem(account, provisionalPassword: localEntry.password ?? "") {
					provisionalEntry.legacyIdentifier = localEntry.identifier
					keychain.log(string:"🟢 Provisional keychainItem made: \(provisionalEntry)")
					return provisionalEntry
				}
			}
		}
		
		return nil
	}
	
	@objc(saveItem:)
	static public func save(item: SCKeychainItem) -> SCKeychainItem? {
		//	Get the correct keychain
		let keychain = Self.keychain(for: item)
		
		//	Ensure that we actually have a non-empty password
		guard let pw = item.password, !pw.isEmpty else {
			keychain.log(string: "🛑 Keychain item does not have a password set: \(item)")
			return nil
		}
		
		//	Was in provisional state, try to persist it
		if item.isProvisional {
			
			//	If the keychain was changed, then delete the original before etting the new one,
			//	otherwise it ends up deleting the created one. (It seems the identifier is actually
			//	a has of the key, service and label)
			if let accountItem = item as? SCKeychainAccountItem,
			   accountItem.migrationDirection != .none {
				var kc = NSApp.iCloudKeychain.keychain
				//	Use the opposite keychain to delete, since we want to delete the old one
				switch accountItem.migrationDirection {
				case .toiCloud:
					kc = NSApp.fileKeychain.keychain
					
				case .none, .toFile:
					break
				@unknown default:
					break
				}
				
				//	First try to delete by the legacy identifier
				var deleted = false;
				if let prevKeychainIdentifier = accountItem.legacyIdentifier {
					deleted = kc.delete(NSData(fromBase64String: prevKeychainIdentifier) as Data)
				}
				if !deleted {
					deleted = kc.delete(item.accountName, service: item.service, label: item.label)
				}
				kc.log(string: "🗑️ Deleted migrated keychain item successfully \(deleted)")
			}

			
			keychain.log(string: "🟢 successfully authenticated with provisional password \(String(describing: item.passwordPII))!  Writing it to keychain")
			var savedItem = keychain.set(pw, forKey: item.accountName, service: item.service, label: item.label)
			if let acctItem = item as? SCKeychainAccountItem, let anItem = savedItem {
				savedItem = SCKeychainAccountItem(account: acctItem.account, keychainItem: anItem)
			}
			if let savedItem {
				keychain.log(string: "🟢 Saved new password to item with identifier \(String(describing: savedItem.identifier))")
				if pw == savedItem.password {
					keychain.log(string: "🟢 Provisional password appears to have been saved to keychain")
					if let legacyIdentifier = savedItem.legacyIdentifier, legacyIdentifier != savedItem.identifier,
					   let legacyIdentifierData = Data(base64Encoded: legacyIdentifier)
					{
						keychain.log(string: "🔄 Also deleting old keychain item with identifier \(legacyIdentifier)")
						_ = keychain.delete(legacyIdentifierData)
					}
					return savedItem
				}
				else {
					keychain.log(string: "🛑 Keychain password does not match provisional")
				}
			}
			else {
				keychain.log(string: "🛑 New password appears not to have been saved to keychain")
			}
		}
		//	Otherwise nothing to do, except return original item
		else {
			keychain.log(string: "🟢 Successfully authenticated with Keychain Item \(item) Using \(String(describing: item.passwordPII))")
			return item
		}
		return nil
	}
	
	@discardableResult
	@objc(deleteItem:)
	static public func delete(item: SCKeychainItem?) -> Bool {
		guard let item else { return false }
		//	Get the correct keychain
		let keychain = Self.keychain(for: item)
		
		//	Ensure that the various values are properly set on the item
		guard let identifier = item.identifier else {
			keychain.log(string: "🛑 Keychain item does not have values set: \(item)")
			return false
		}
		
		//	Delete by using the identifier
		let deleted = keychain.delete(NSData(fromBase64String: identifier) as Data)
		keychain.log(string: "The item \(item) was \(deleted ? "successfully" : "not successfully") deleted from the keychain")
		return deleted
	}

	@discardableResult
	@objc(deleteForIdentifier:)
	public func delete(identifier: String) -> Bool {
		//	Delete the account info
		let deleted = keychain.delete(NSData(fromBase64String: identifier) as Data)
		keychain.log(string: "The account info was \(deleted ? "successfully" : "not successfully") deleted for identifier \(identifier) from the keychain")
		return deleted
	}
	
	
	//	MARK: - Helpers
	
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
