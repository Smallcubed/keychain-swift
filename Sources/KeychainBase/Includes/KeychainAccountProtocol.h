//
//  KeychainAccountProtocol.h
//  
//
//  Created by Scott Little on 12/09/2023.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol KeychainAccount <NSObject>

@property (strong, readonly) NSString * keychainPrefix;
@property (strong, readonly) NSString * keychainAccountName;
@property (strong, readonly) NSString * keychainServiceName;
@property (strong, readonly) NSString * keychainLabelName;

@property (strong, readonly, nullable) NSString * keychainLegacyLabel;
@property (strong, readonly, nullable) NSString * keychainLegacyAccountName;

@property (copy, readonly) NSString * hostname;
@property (readonly) NSInteger portNumber;
@property (readonly) BOOL ssl;
@property (copy, readonly) NSString * loginName;
@property (strong, readonly) NSString * loginPassword;
@property (strong, readonly) NSString * authenticationMethod;

- (void)resetInternalPassword;

@end

@protocol KeychainWithSMTPAccount <NSObject>
@property (strong, readonly, nullable) NSString * preferredSMTPAccountIdentifier;
@end

NS_ASSUME_NONNULL_END
