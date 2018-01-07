//
//  Windows.swift
//  Photon
//
//  Created by Karan Singhal on 1/6/18.
//  Copyright © 2018 Anish Athalye. All rights reserved.
//

import Foundation

import AppKit


@objc class WindowTracker : NSObject {
    override init() {
        super.init()
    }
    
    func getActiveWindow() -> String {
        let frontmostAppPID = NSWorkspace.shared().frontmostApplication!.processIdentifier
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
        
        for window in windows {
            if let windowOwnerPID = (window[kCGWindowOwnerPID as String] ?? 0) as? Int {
                if windowOwnerPID != Int(frontmostAppPID) {
                    continue
                }
            } else {
                continue
            }
            
            // Skip transparent windows, like with Chrome
            if (window[kCGWindowAlpha as String] as! Double) == 0 {
                continue
            }
            
            let bounds = CGRect(dictionaryRepresentation: window[kCGWindowBounds as String] as! CFDictionary)!
            
            // Skip tiny windows, like the Chrome link hover statusbar
            let minWinSize: CGFloat = 50
            if bounds.width < minWinSize || bounds.height < minWinSize {
                continue
            }
            
            return window[kCGWindowOwnerName as String] as! String
        }
        
        return ""
        
    }
    
}


