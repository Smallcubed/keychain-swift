//
//  KeychainAccountProtocol.h
//  
//
//  Created by Scott Little on 12/09/2023.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol KeychainAccountInfo <NSObject>

@property (copy, readonly) NSString * hostname;
@property (copy, readonly) NSString * keychainHostName;
@property (readonly) NSInteger portNumber;
@property (readonly) BOOL ssl;
@property (copy, readonly) NSString * loginName;
@property (strong, readonly, nullable) NSString * loginPassword;
@property (strong, readonly) NSString * authenticationMethod;
@property (readonly) NSString * displayName; // the user facing name of the account

@end

@protocol KeychainAccount <NSObject, KeychainAccountInfo>
@property (strong, readonly) NSString * keychainPrefix;
@property (strong, readonly) NSString * keychainAccountName;
@property (strong, readonly) NSString * keychainServiceName;
@property (strong, readonly) NSString * keychainLabelName;

@property (strong, readonly, nullable) NSString * keychainLegacyLabel;
@property (strong, readonly, nullable) NSString * keychainLegacyAccountName;
@property (strong, readonly, nullable) NSString * keychainLegacyServiceName;
@property (strong, nullable) NSString * currentAccountInfoHash;

@property (readonly) BOOL canSyncPassword;

@property (strong) NSDictionary * accountProperties;
- (id)accountPropertyForKey:(NSString *)key NS_SWIFT_NAME(property(forKey:));
- (void)setAccountProperty:(id _Nullable)property forKey:(NSString *)key NS_SWIFT_NAME(set(property:forKey:));
@end

@protocol KeychainWithSMTPAccount <NSObject>
@property (strong, readonly, nullable) NSString * preferredSMTPAccountIdentifier;
@end

@protocol KeychainLogger
- (void)logString:(nonnull NSString *)string NS_SWIFT_NAME(log(string:));
@end

typedef NS_ENUM(NSInteger, KeychainType) {
	KeychainTypeiCloud = 0,
	KeychainTypeFile = 1,
};

typedef NS_ENUM(NSInteger, KeychainMigrationDirection) {
	KeychainMigrationDirectionNone = 0,
	KeychainMigrationDirectionToiCloud = 1,
	KeychainMigrationDirectionToFile = 2,
};

NS_ASSUME_NONNULL_END
