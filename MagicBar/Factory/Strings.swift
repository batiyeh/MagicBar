//
//  Strings.swift
//  MagicBar
//
//  Created by Atiyeh, Brian (B.) on 5/12/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation

public struct Strings {
    public struct Notifications {
        public struct ConnectInfo {
            public struct Success {
                static let succeeded = "Connected"
                static let deviceConnected = "Your device has successfully connected."
            }
            
            public struct Error {
                static let failedToConnect = "Failed to Connect"
                static let pleaseTryAgain = "Please try resetting the device or disconnecting it from another machine before trying again."
                static let deviceBusy = "The device was busy. Please try again."
                static let deviceNotFound = "The device could not be found. Please turn it on and off before trying again."
            }
        }
    }
}
