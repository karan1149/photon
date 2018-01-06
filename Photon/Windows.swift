//
//  Windows.swift
//  Photon
//
//  Created by Karan Singhal on 1/6/18.
//  Copyright © 2018 Anish Athalye. All rights reserved.
//

import Foundation

import AppKit


func getActiveWindow() throws -> String {
    let frontmostAppPID = NSWorkspace.shared.frontmostApplication!.processIdentifier
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
    
    for window in windows {
        let windowOwnerPID = window[kCGWindowOwnerPID as String] as! Int
        
        if windowOwnerPID != frontmostAppPID {
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
        
        let appPid = window[kCGWindowOwnerPID as String] as! pid_t
        
        // This can't fail as we're only dealing with apps
        let app = NSRunningApplication(processIdentifier: appPid)!
        
//        let dict: [String: Any] = [
//            "title": window[kCGWindowName as String] as! String,
//            "id": window[kCGWindowNumber as String] as! Int,
//            "bounds": [
//                "x": bounds.origin.x,
//                "y": bounds.origin.y,
//                "width": bounds.width,
//                "height": bounds.height
//            ],
//            "owner": [
//                "name": window[kCGWindowOwnerName as String] as! String,
//                "processId": appPid,
//                "bundleId": app.bundleIdentifier!,
//                "path": app.bundleURL!.path
//            ],
//            "memoryUsage": window[kCGWindowMemoryUsage as String] as! Int
//        ]
        
        return window[kCGWindowOwnerName as String] as! String
    }
    
}

