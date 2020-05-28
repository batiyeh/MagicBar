//
//  Mouse.swift
//  MagicBar
//
//  Created by Atiyeh, Brian (B.) on 5/11/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import IOBluetooth

public typealias Device = IOBluetoothDevice

public struct Mouse {
    let device: Device
    var state: MouseState
}
