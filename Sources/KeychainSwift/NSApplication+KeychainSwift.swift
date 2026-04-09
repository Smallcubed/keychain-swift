//
//  NSApplication+KeychainSwift.swift
//  KeychainSwift
//
//  Created by Scott Little on 06/04/2026.
//

import AppKit;

private struct AssociatedKeys {
	static var iCloudKeychain: UInt8 = 0
	static var fileKeychain: UInt8 = 1
}

extension NSApplication {
	@objc
	public var iCloudKeychain: KeychainSwiftCBridge {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.iCloudKeychain) as! KeychainSwiftCBridge
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.iCloudKeychain, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	@objc
	public var fileKeychain: KeychainSwiftCBridge {
		get {
			return objc_getAssociatedObject(self, &AssociatedKeys.fileKeychain) as! KeychainSwiftCBridge
		}
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.fileKeychain, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
}
