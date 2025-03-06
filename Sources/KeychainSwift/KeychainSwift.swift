import Security
import Foundation

/**

A collection of helper functions for saving text and data in the keychain.

*/
open class KeychainSwift {
	
	var lastQueryParameters: [String: Any]? // Used by the unit tests
	
	/// Contains result code from the last operation. Value is noErr (0) for a successful result.
	open var lastResultCode: OSStatus = noErr
	
	var keyPrefix = "" // Can be useful in test.
	
	/**
	 
	 Specify an access group that will be used to access keychain items. Access groups can be used to share keychain items between applications. When access group value is nil all application access groups are being accessed. Access group name is used by all functions: set, get, delete and clear.
	 
	 */
	open var accessGroup: String?
	
	/**
	 
	 Specifies whether the items can be synchronized with other devices through iCloud. Setting this property to true will
	 add the item to other devices with the `set` method and obtain synchronizable items with the `get` command. Deleting synchronizable items will remove them from all devices. In order for keychain synchronization to work the user must enable "Keychain" in iCloud settings.
	 
	 */
	open var synchronizable: Bool = false
	
	/**
	 
	 Specifies a service name to be used for all passwords.
	 
	 */
	open var serviceName: String?
	
	/**
	 
	 Specify whether or not a file based keychain should be used. This is for compatibility reasons on macOS, the default is always `false`. If this is set it will override the `accessGroup` & `synchronizable` values, since those are not available for file keychains. `UseFileKeychain` is used by all functions: set, get, delete and clear.
	 
	 */
	open var useFileKeychain: Bool = false
	
	/**
	 Set a default accessOptions override for the keychain
	 */
	open var overrideAccessOption: KeychainSwiftAccessOptions = .defaultOption
	
	
	private let lock = NSLock()
	private let recurseMax: Int = 10

	
	/**
	 
	 - parameter keyPrefix: a prefix that is added before the key in get/set methods. Note that `clear` method still clears everything from the Keychain.
	 - parameter service: a value that is added as the service in get/set methods.

	 */
	public init(keyPrefix: String? = nil, service: String? = nil) {
		self.keyPrefix = keyPrefix ?? ""
		self.serviceName = service
	}
	
	
	//	MARK: - Get Methods
	
	/**
	 
	 Retrieves the text value from the keychain that corresponds to the given key.
	 
	 - parameter key: The key that is used to read the keychain item.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - returns: The text value from the keychain. Returns nil if unable to read the item.
	 
	 */
	open func get(_ key: String, service: String? = nil, label: String? = nil) -> String? {
		if let data = getData(key, service: service, label: label) {
			
			if let currentString = String(data: data, encoding: .utf8) {
				return currentString
			}
			
			lastResultCode = -67853 // errSecInvalidEncoding
		}
		
		return nil
	}
	
	/**
	 
	 Retrieves the data from the keychain that corresponds to the given key.
	 
	 - parameter key: The key that is used to read the keychain item.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - parameter asReference: If true, returns the data as reference (needed for things like NEVPNProtocol).
	 - returns: The text value from the keychain. Returns nil if unable to read the item.
	 
	 */
	open func getData(_ key: String,
					  service: String? = nil, label: String? = nil,
					  recurseCount: Int = 0,
					  asReference: Bool = false) -> Data? {

		guard recurseCount < recurseMax else {
			lock.unlock()
			return nil
		}

		// The lock prevents the code to be run simultaneously
		// from multiple threads which may result in crashing
		if recurseCount == 0 {
			lock.lock()
		}
		
		let prefixedKey = keyWithPrefix(key)
		
		var query: [String: Any] = [
			KeychainSwiftConstants.klass       : kSecClassGenericPassword,
			KeychainSwiftConstants.attrAccount : prefixedKey,
			KeychainSwiftConstants.matchLimit  : kSecMatchLimitOne
		]
		
		if asReference {
			query[KeychainSwiftConstants.returnReference] = kCFBooleanTrue
		} else {
			query[KeychainSwiftConstants.returnData] =  kCFBooleanTrue
		}
		
		query = addServiceName(query, override: service)
		query = addDataProtection(query)
		query = addAccessGroupWhenPresent(query)
		query = addSynchronizableIfRequired(query, addingItems: false)
		lastQueryParameters = query
		
		var result: AnyObject?
		
		lastResultCode = withUnsafeMutablePointer(to: &result) {
			SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
		}
		
		guard lastResultCode != errSecInteractionNotAllowed else {
			//	This allows the Security system to finish unlocking the keychain
			Thread.sleep(until: Date(timeIntervalSinceNow: 0.5))
			return getData(key, service: service, label: label, recurseCount: recurseCount + 1, asReference: asReference)
		}
		
		lock.unlock()
		return result as? Data
	}
	
	/**
	 
	 Retrieves the boolean value from the keychain that corresponds to the given key.
	 
	 - parameter key: The key that is used to read the keychain item.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - returns: The boolean value from the keychain. Returns nil if unable to read the item.
	 
	 */
	open func getBool(_ key: String,
					  service: String? = nil, label: String? = nil) -> Bool? {
		guard let data = getData(key, service: service, label: label) else { return nil }
		guard let firstBit = data.first else { return nil }
		return firstBit == 1
	}
	
	
	//	MARK: - Set Methods
	
	/**
	 
	 Stores the text value in the keychain item under the given key.
	 
	 - parameter key: Key under which the text value is stored in the keychain.
	 - parameter value: Text string to be written to the keychain.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	 
	 - returns: True if the text was successfully written to the keychain.
	 
	 */
	@discardableResult
	open func set(_ value: String, forKey key: String,
				  service: String? = nil, label: String? = nil,
				  withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
		
		if let value = value.data(using: String.Encoding.utf8) {
			return set(value, forKey: key, service: service, label: label, withAccess: access)
		}
		
		return false
	}
	
	/**
	 
	 Stores the data in the keychain item under the given key.
	 
	 - parameter key: Key under which the data is stored in the keychain.
	 - parameter value: Data to be written to the keychain.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	 
	 - returns: True if the text was successfully written to the keychain.
	 
	 */
	@discardableResult
	open func set(_ value: Data, forKey key: String,
				  service: String? = nil, label: String? = nil,
				  withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
		
		// The lock prevents the code to be run simultaneously
		// from multiple threads which may result in crashing
		lock.lock()
		defer { lock.unlock() }
		
		deleteNoLock(key, service: service, label: label) // Delete any existing key before saving it
		
		let accessible = access?.value ?? overrideAccessOption.value
		
		let prefixedKey = keyWithPrefix(key)
		
		var query: [String : Any] = [
			KeychainSwiftConstants.klass       : kSecClassGenericPassword,
			KeychainSwiftConstants.attrAccount : prefixedKey,
			KeychainSwiftConstants.valueData   : value,
			KeychainSwiftConstants.accessible  : accessible
		]
		
		query = addLabel(query, label: label)
		query = addServiceName(query, override: service)
		query = addDataProtection(query)
		query = addAccessGroupWhenPresent(query)
		query = addSynchronizableIfRequired(query, addingItems: true)
		lastQueryParameters = query
		
		lastResultCode = SecItemAdd(query as CFDictionary, nil)
		
		return lastResultCode == noErr
	}
	
	/**
	 
	 Stores the boolean value in the keychain item under the given key.
	 
	 - parameter key: Key under which the value is stored in the keychain.
	 - parameter value: Boolean to be written to the keychain.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - parameter withAccess: Value that indicates when your app needs access to the value in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	 
	 - returns: True if the value was successfully written to the keychain.
	 
	 */
	@discardableResult
	open func set(_ value: Bool, forKey key: String,
				  service: String? = nil, label: String? = nil,
				  withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
		
		let bytes: [UInt8] = value ? [1] : [0]
		let data = Data(bytes)
		
		return set(data, forKey: key, service: service, label: label, withAccess: access)
	}
	

	//	MARK: - Deletion Methods
	
	/**
	 
	 Deletes the single keychain item specified by the key.
	 
	 - parameter key: The key that is used to delete the keychain item.
	 - parameter service: The service valeu that is used to delete the keychain item.
	 - returns: True if the item was successfully deleted.
	 
	 */
	@discardableResult
	open func delete(_ key: String, service: String? = nil, label: String? = nil) -> Bool {
		// The lock prevents the code to be run simultaneously
		// from multiple threads which may result in crashing
		lock.lock()
		defer { lock.unlock() }
		
		return deleteNoLock(key, service: service, label: label)
	}
	
	/**
	 
	 Same as `delete` but is only accessed internally, since it is not thread safe.
	 
	 - parameter key: The key that is used to delete the keychain item.
	 - parameter service: The service valeu that is used to delete the keychain item.
	 - returns: True if the item was successfully deleted.
	 
	 */
	@discardableResult
	func deleteNoLock(_ key: String, service: String? = nil, label: String? = nil) -> Bool {
		let prefixedKey = keyWithPrefix(key)
		
		var query: [String: Any] = [
			KeychainSwiftConstants.klass       : kSecClassGenericPassword,
			KeychainSwiftConstants.attrAccount : prefixedKey
		]
		
		query = addLabel(query, label: label)
		query = addServiceName(query, override: service)
		query = addDataProtection(query)
		query = addAccessGroupWhenPresent(query)
		query = addSynchronizableIfRequired(query, addingItems: false)
		lastQueryParameters = query
		
		lastResultCode = SecItemDelete(query as CFDictionary)
		
		return lastResultCode == noErr
	}
	
	/**
	 
	 Deletes all Keychain items used by the app. Note that this method deletes all items regardless of the prefix settings used for initializing the class.
	 
	 - returns: True if the keychain items were successfully deleted.
	 
	 */
	@discardableResult
	open func clear() -> Bool {
		// The lock prevents the code to be run simultaneously
		// from multiple threads which may result in crashing
		lock.lock()
		defer { lock.unlock() }
		
		var query: [String: Any] = [ kSecClass as String : kSecClassGenericPassword ]
		query = addServiceName(query, override: nil)
		query = addDataProtection(query)
		query = addAccessGroupWhenPresent(query)
		query = addSynchronizableIfRequired(query, addingItems: false)
		lastQueryParameters = query
		
		lastResultCode = SecItemDelete(query as CFDictionary)
		
		return lastResultCode == noErr
	}
	
	
	//	MARK: - Legacy Migration Code
	
	/**
	 
	 Migrates a password from a file keychain if needed to iCloud keychain and returns the string.
	 
	 - parameter key: The key that is used to read the keychain item.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The new label that would be added for the migrated password.
	 - returns: The text value from the keychain. Returns nil if unable to read the item.
	 
	 */
	open func migratePassword(_ key: String, service: String, label: String! = nil) -> String? {
		let fileKeychain = KeychainSwift()
		fileKeychain.useFileKeychain = true
		let value = fileKeychain.get(key, service: service)
		if let pw = value, set(pw, forKey: key, service: service, label: label) {
			fileKeychain.delete(key, service: service, label: label)
		}
		return value
	}
	
	/**
	 
	 Migrates data from a file keychain if needed to iCloud keychain and returns the data.
	 
	 - parameter key: The key that is used to read the keychain item.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The new label that would be added for the migrated password.
	 - returns: The Data value from the keychain. Returns nil if unable to read the item.
	 
	 */
	open func migrateData(_ key: String, service: String, label: String! = nil) -> Data? {
		let fileKeychain = KeychainSwift()
		fileKeychain.useFileKeychain = true
		let value = fileKeychain.getData(key, service: service)
		if let pw = value, set(pw, forKey: key, service: service, label: label) {
			fileKeychain.delete(key, service: service, label: label)
		}
		return value
	}

	
	//	MARK: - Helper Functions
	
	/**
	 Return all keys from keychain
	 
	 - returns: An string array with all keys from the keychain.
	 
	 */
	public var allKeys: [String] {
		var query: [String: Any] = [
			KeychainSwiftConstants.klass : kSecClassGenericPassword,
			KeychainSwiftConstants.returnData : true,
			KeychainSwiftConstants.returnAttributes: true,
			KeychainSwiftConstants.returnReference: true,
			KeychainSwiftConstants.matchLimit: KeychainSwiftConstants.secMatchLimitAll
		]
		
		query = addServiceName(query, override: nil)
		query = addDataProtection(query)
		query = addAccessGroupWhenPresent(query)
		query = addSynchronizableIfRequired(query, addingItems: false)
		
		var result: AnyObject?
		
		let lastResultCode = withUnsafeMutablePointer(to: &result) {
			SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
		}
		
		if lastResultCode == noErr {
			return (result as? [[String: Any]])?.compactMap {
				$0[KeychainSwiftConstants.attrAccount] as? String } ?? []
		}
		
		return []
	}
	
	/// Returns the key with currently set prefix.
	func keyWithPrefix(_ key: String) -> String {
		return "\(keyPrefix)\(key)"
	}
	
	func addAccessGroupWhenPresent(_ items: [String: Any]) -> [String: Any] {
		guard !useFileKeychain, let accessGroup = accessGroup else {
			return items
		}
		
		var result: [String: Any] = items
		result[KeychainSwiftConstants.accessGroup] = accessGroup
		return result
	}
	
	/**
	 
	 Adds `kSecAttrSynchronizable: kSecAttrSynchronizableAny` item to the dictionary when the `synchronizable` property is true.
	 
	 - parameter items: The dictionary where the kSecAttrSynchronizable items will be added when requested.
	 - parameter addingItems: Use `true` when the dictionary will be used with `SecItemAdd` method (adding a keychain item). For getting and deleting items, use `false`.
	 
	 - returns: the dictionary with kSecAttrSynchronizable item added if it was requested. Otherwise, it returns the original dictionary.
	 
	 */
	func addSynchronizableIfRequired(_ items: [String: Any], addingItems: Bool) -> [String: Any] {
		guard synchronizable && !useFileKeychain else {
			return items;
		}
		var result: [String: Any] = items
		//	When we are adding items, set to yes, otherwise get any
		result[KeychainSwiftConstants.attrSynchronizable] = addingItems ? true : kSecAttrSynchronizableAny
		return result
	}
	
	/**
	 
	 Adds `kSecUseDataProtectionKeychain` item to the dictionary based on the `useFileKeychain` property.
	 
	 - parameter items: The dictionary where the kSecUseDataProtectionKeychain items will be added when requested.
	 
	 - returns: the dictionary with kSecUseDataProtectionKeychain item added.
	 
	 */
	func addDataProtection(_ items: [String: Any]) -> [String: Any] {
		var result: [String: Any] = items
		result[KeychainSwiftConstants.attrUseDataProtection] = !useFileKeychain
		return result
	}
	
	/**
	 
	 Adds `kSecAttrService` item to the dictionary when a serviceName is designated.
	 
	 - parameter items: The dictionary where the kSecAttrSynchronizable items will be added when requested.
	 - parameter override: This value always takes precendence over the instance variable.
	 
	 - returns: the dictionary with kSecAttrService item added if it was requested. Otherwise, it returns the original dictionary.
	 
	 */
	func addServiceName(_ items: [String: Any], override: String?) -> [String: Any] {
		guard let service = override ?? self.serviceName else {
			return items;
		}
		var result: [String: Any] = items
		result[KeychainSwiftConstants.attrService] = service
		return result
	}
	
	/**
	 
	 Adds `kSecAttrLabel` item to the dictionary when a serviceName is designated.
	 
	 - parameter items: The dictionary where the kSecAttrSynchronizable items will be added when requested.
	 - parameter label: The label value to add.
	 
	 - returns: the dictionary with kSecAttrLabel item added if it was requested. Otherwise, it returns the original dictionary.
	 
	 */
	func addLabel(_ items: [String: Any], label: String?) -> [String: Any] {
		guard let theLabel = label else {
			return items;
		}
		var result: [String: Any] = items
		result[KeychainSwiftConstants.attrLabel] = theLabel
		return result
	}
	
}
