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
    
    func getActiveWindow() -> pid_t {
        let frontmostAppPID = NSWorkspace.shared().frontmostApplication!.processIdentifier
        return frontmostAppPID;
        
    }
    
}


