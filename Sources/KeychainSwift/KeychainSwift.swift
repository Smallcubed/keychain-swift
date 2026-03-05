import Security
import Foundation
import AppKit
import SCBaseKit
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
    
    private var lastResultErrorDescription: String {
        return SecCopyErrorMessageString(lastResultCode, nil) as? String ?? "Code \(lastResultCode)"
    }
    
    private let lock = NSRecursiveLock()
    private let recurseMax: Int = 10
    
    private static var _requestIdx_ : Int = 0
    /**
     
     - parameter keyPrefix: a prefix that is added before the key in get/set methods. Note that `clear` method still clears everything from the Keychain.
     - parameter service: a value that is added as the service in get/set methods.
     
     */
    public init(keyPrefix: String? = nil, service: String? = nil) {
        self.keyPrefix = keyPrefix ?? ""
        self.serviceName = service
    }
    
    open func log(string: String){
        SCLogger(forSubsystem: "Authorization")?.log(string: string)
    }
    
    //	MARK: - Get Methods
    
    /**
     
     Retrieves the text value from the keychain that corresponds to the given key.
     
     - parameter key: The key that is used to read the keychain item.
     - parameter service: The service name that is used to read the keychain item.
     - parameter label: The label that is used to read the keychain item.
     - returns: The text value from the keychain. Returns nil if unable to read the item.
     
     */
    
    open func get(_ keychainIdentifier: Data) -> SCKeychainItem? {
        
        
        lock.lock()
        defer { lock.unlock() }
        KeychainSwift._requestIdx_ += 1
               let requestIdx = KeychainSwift._requestIdx_
             
        let query: [String: Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            kSecValuePersistentRef as String : keychainIdentifier,
            KeychainSwiftConstants.returnReference : kCFBooleanTrue!,
            KeychainSwiftConstants.returnData : kCFBooleanTrue!,
            KeychainSwiftConstants.returnAttributes : kCFBooleanTrue!,
            KeychainSwiftConstants.matchLimit  : kSecMatchLimitOne
        ]
        
        lastQueryParameters = query
        
        var result: AnyObject?
        
        lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        var attemptCount = 1
        while (lastResultCode == errSecInteractionNotAllowed && attemptCount < recurseMax){
            log(string:"[KEYCHAIN-GET \(requestIdx)] ⚠️ Keychain is not yet available -- trying again in .5 seconds")
            Thread.sleep(until: Date(timeIntervalSinceNow: 0.5))
            lastResultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            attemptCount += 1
        }
        if  lastResultCode == noErr {
            if let rep = result as? Dictionary<String, Any>{
                let entry = SCKeychainItem(rep)
                return entry
            }
        }
        else{
            log(string:"[KEYCHAIN-GET \(requestIdx)] 🛑 Could not get keychain item with identifier \(keychainIdentifier.base64EncodedString()):  code:\(lastResultCode) msg:\(lastResultErrorDescription)")
        }
        
        return nil
    }
    
    open func get(_ key: String, service: String? = nil, label: String? = nil) -> String? {
        if let data = getData(key, service: service, label: label) {
            
            if let currentString = String(data: data, encoding: .utf8) {
                return currentString
            }
            
            lastResultCode = -67853 // errSecInvalidEncoding
        }
        
        return nil
    }
    
    open func fetchEntriesFor(_ account:String)-> [SCKeychainItem]?{
        lock.lock()
        defer { lock.unlock() }
        KeychainSwift._requestIdx_ += 1
        let requestIdx = KeychainSwift._requestIdx_
             
        let prefixedKey = keyWithPrefix(account)
        
        var query: [String: Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey,
            KeychainSwiftConstants.returnReference : kCFBooleanTrue!,
            KeychainSwiftConstants.returnData : kCFBooleanTrue!,
            KeychainSwiftConstants.returnAttributes : kCFBooleanTrue!,
            KeychainSwiftConstants.matchLimit  : kSecMatchLimitAll
        ]
        query = addDataProtection(query)
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: false)
        lastQueryParameters = query
        
        var result: AnyObject?
        
        var lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        var attemptCount = 1
        while (lastResultCode == errSecInteractionNotAllowed && attemptCount < recurseMax){
            log(string:"[KEYCHAIN-Fetch \(requestIdx) ] ⚠️ Keychain is not yet available -- trying again in .5 seconds")
            Thread.sleep(until: Date(timeIntervalSinceNow: 0.5))
            lastResultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            attemptCount += 1
        }
        
        if let reps = result as? NSArray{
            var entries = [SCKeychainItem]()
            
            for rep in reps{
                if let rep = rep as? [String: Any]{
                    let entry  = SCKeychainItem(rep)
                    entries.append(entry)
                }
            }
            return entries
        }
        
        log(string:"[KEYCHAIN-Fetch \(requestIdx) ] \(account) 🛑 Could not retrieve data")
        
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
   
    func getDataNoLock(_ key: String,
                  service: String? = nil,
                  label:String? = nil,
                  requestIndex requestIdx: Int,
                  asReference: Bool = false) -> Data?{
       
        var logKey = "\(key) "
        if let service {  logKey += " *️⃣\(service)"}
        if let label {  logKey += " #️⃣\(label)" }
        
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
//        query = addLabel(query, label: label) // this may be actually interfering with getting data.
        query = addServiceName(query, override: service)
        query = addDataProtection(query)
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: false)
        lastQueryParameters = query
        
        var result: AnyObject?
        
        var lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        var attemptCount = 1
        while (lastResultCode == errSecInteractionNotAllowed && attemptCount < recurseMax){
            log(string:"[KEYCHAIN-GET \(requestIdx)] ⚠️ Keychain is not yet available -- trying again in .5 seconds")
            Thread.sleep(until: Date(timeIntervalSinceNow: 0.5))
            lastResultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            attemptCount += 1
        }
        if !(result is NSData) {
            log(string:"[KEYCHAIN-GET \(requestIdx)] \(logKey) 🛑 Could not retrieve data")
        }
        return result as? Data
    }
	open func getData(_ key: String,
					  service: String? = nil, label: String? = nil,
					  recurseCount: Int = 0,
					  asReference: Bool = false) -> Data? {
        
        
        lock.lock()
        defer { lock.unlock() }
        KeychainSwift._requestIdx_ += 1
        let requestIdx = KeychainSwift._requestIdx_
    
        return getDataNoLock(key,service:service, label:label, requestIndex: requestIdx,asReference : asReference)
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
				  withAccess access: KeychainSwiftAccessOptions? = nil) -> SCKeychainItem? {
		
		if let value = value.data(using: String.Encoding.utf8) {
			return  set(value, forKey: key, service: service, label: label, withAccess: access)
		}
		
		return nil
	}
	
	/**
	 
	 Stores the data in the keychain item under the given key.
	 
	 - parameter key: Key under which the data is stored in the keychain.
	 - parameter value: Data to be written to the keychain.
	 - parameter service: The service name that is used to read the keychain item.
	 - parameter label: The label that is used to read the keychain item.
	 - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
	 
	 - returns: SCKeychainItem Identifier if successful
	 
	 */
	@discardableResult
	open func set(_ value: Data, forKey key: String,
				  service: String? = nil, label: String? = nil,
                  withAccess access: KeychainSwiftAccessOptions? = nil) -> SCKeychainItem? {
        
        // The lock prevents the code to be run simultaneously
        // from multiple threads which may result in crashing
        lock.lock()
        defer { lock.unlock() }
        
        var logKey = "\(key) "
        if let service {  logKey += " *️⃣\(service)"}
        if let label {  logKey += " #️⃣\(label)" }
        
        KeychainSwift._requestIdx_ += 1
        let requestIdx = KeychainSwift._requestIdx_
        
        
        let accessible = access?.value ?? overrideAccessOption.value
        
        let prefixedKey = keyWithPrefix(key)
        
        var query: [String : Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey,
            KeychainSwiftConstants.valueData   : value,
            KeychainSwiftConstants.accessible  : accessible,
            KeychainSwiftConstants.returnReference : kCFBooleanTrue!,
            KeychainSwiftConstants.returnData : kCFBooleanTrue!,
            KeychainSwiftConstants.returnAttributes : kCFBooleanTrue!,
            
        ]
        
        query = addLabel(query, label: label)
        query = addServiceName(query, override: service)
        query = addDataProtection(query)
        query = addAccessGroupWhenPresent(query)
        query = addSynchronizableIfRequired(query, addingItems: true)
        lastQueryParameters = query
        if let currentData = getDataNoLock(key,service: service, label:label, requestIndex:requestIdx){
            guard currentData != value else{
                log(string:"[KEYCHAIN-SET \(requestIdx)] \(logKey) ❗️ Data is unchanged! returning" )
                return nil
            }
            if !deleteNoLock(key, service: service, label: label,requestIndex: requestIdx) {
                if lastResultCode != errSecItemNotFound {
                    log(string:"[KEYCHAIN-SET \(requestIdx)] 🛑 Could not delete old key error: \(lastResultErrorDescription)" )
                }
            }
        }
       
        
        var result: AnyObject?
        
        let lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemAdd(query as CFDictionary, UnsafeMutablePointer($0))
        }
        var entry : SCKeychainItem?
        if (lastResultCode == noErr){
            if let rep = result as? [String: Any]{
                entry = SCKeychainItem(rep)
            }
            log(string:"[KEYCHAIN-SET \(requestIdx)] \(logKey) 🟢 \((value as NSData).privacyRepresentation)" )
            if let rereadData = getDataNoLock(key,service: service, label:label, requestIndex:requestIdx){
                if (value != rereadData){
                    log(string:"[KEYCHAIN-Valid \(requestIdx)] \(logKey) 🛑 readData (\((rereadData as NSData).privacyRepresentation)) does not match setData: \((value as NSData).privacyRepresentation)" )
                }
            }
            else{
                log(string:"[KEYCHAIN-Valid \(requestIdx)] \(logKey) 🛑 readData NIL does not match setData: \((value as NSData).privacyRepresentation)" )
            }
            
        }
        else{
            log(string:"[KEYCHAIN-SET \(requestIdx)] \(logKey) 🛑 Could not set data \((value as NSData).privacyRepresentation) error: \(lastResultErrorDescription)")
        }
        return entry
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
				  withAccess access: KeychainSwiftAccessOptions? = nil) -> SCKeychainItem? {
		
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
        KeychainSwift._requestIdx_ += 1
        let requestIdx = KeychainSwift._requestIdx_
      
		return deleteNoLock(key, service: service, label: label,requestIndex: requestIdx)
	}
	
    open func delete(_ keychainIdentifier: Data) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        KeychainSwift._requestIdx_ += 1
        let requestIdx = KeychainSwift._requestIdx_
        
        let query: [String: Any] = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            kSecValuePersistentRef as String : keychainIdentifier
        ]
        lastQueryParameters = query
        
        lastResultCode = SecItemDelete(query as CFDictionary)
        if (lastResultCode != noErr){
            log(string:"[KEYCHAIN-DELETE \(requestIdx)] 🛑 Could not delete entry for \(keychainIdentifier.base64EncodedString()) error: \(lastResultErrorDescription)" )
        }
        
        return lastResultCode == noErr
    }
	/**
	 
	 Same as `delete` but is only accessed internally, since it is not thread safe.
	 
	 - parameter key: The key that is used to delete the keychain item.
	 - parameter service: The service valeu that is used to delete the keychain item.
	 - returns: True if the item was successfully deleted.
	 
	 */
   
	@discardableResult
	func deleteNoLock(_ key: String,
                      service: String? = nil,
                      label: String? = nil,
                      requestIndex requestIdx: Int) -> Bool {
		let prefixedKey = keyWithPrefix(key)
		
        var logKey = "\(key) "
        if let service {  logKey += " *️⃣\(service)"}
        if let label {  logKey += " #️⃣\(label)" }
        
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
        if (lastResultCode != noErr){
            log(string:"[KEYCHAIN-DELETE \(requestIdx)] 🛑 Could not delete entry for \(logKey) error: \(lastResultErrorDescription)" )
        }
        
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
	open func migratePassword(_ key: String, service: String, label: String! = nil)  -> String? {
		let fileKeychain = KeychainSwift()
		fileKeychain.useFileKeychain = true
		let value = fileKeychain.get(key, service: service)
		if let pw = value, set(pw, forKey: key, service: service, label: label) != nil {
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
		if let pw = value, set(pw, forKey: key, service: service, label: label) != nil {
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
    
    public var allEntries: [SCKeychainItem] {
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
                SCKeychainItem($0)
            } ?? []
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


open class SCKeychainItem : NSObject {
    
    var rawDictionary : [String:Any]?
    
    @objc public
    var legacyIdentifier : String?
    
   
    
    @objc public
    var accountInfoPassword : String?
    
    @objc public
    func password() -> String? {
        if let passwordData = rawDictionary?[ kSecValueData as String] as? Data {
            return String(data: passwordData, encoding: .utf8)
        }
        return accountInfoPassword
    }
    
    @objc public
    var passwordPII : String? {
        if let nsData = rawDictionary?[kSecValueData as String] as? NSData {
            return nsData.privacyRepresentation
        }
        return "<PII: NIL>"
    }
    @objc public
    var identifier : String? {
        let data = rawDictionary?[kSecValuePersistentRef as String] as? Data
        return data?.base64EncodedString()
    }
    
    @objc public
    var service :  String? {
        return rawDictionary?[kSecAttrService as String] as? String
    }
    
    @objc public
    var label:  String? {
        return rawDictionary?[kSecAttrLabel as String] as? String
    }
    
    @objc public
    var account:  String? {
        return rawDictionary?[kSecAttrAccount as String] as? String
    }
    @objc public
    var isProvisional : Bool {
        return self.identifier == nil
    }
    @objc public
    var dictionaryRepresentation:  [String :Any]? {
        return rawDictionary
    }
    
    @objc init(_ rep : [String:Any]){
        self.rawDictionary = rep
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
        return super.description.appending("\(identifier) Account: \(acct) Service : \(srvc) Label: \(lbl)")
    }
}
