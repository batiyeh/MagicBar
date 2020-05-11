//
//  BluetoothService.swift
//  MagicBar
//
//  Created by Brian Atiyeh on 5/8/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import IOBluetooth
import RxSwift

public typealias MagicMouse = IOBluetoothDevice

public protocol BluetoothServicable {
    func connect()
    func getMagicMouse() -> MagicMouse?
}

public class BluetoothService: BluetoothServicable {
    let identifier = "Magic Mouse 2"
    
    init() {
    }
    
    public func connect() {
        if let magicMouse = getMagicMouse(),
            !magicMouse.isConnected() {
            magicMouse.openConnection()
        }
    }
    
    public func getMagicMouse() -> MagicMouse? {
        guard let devices = IOBluetoothDevice.pairedDevices() else { return nil }
        
        var magicMouse: MagicMouse? = nil
        for item in devices {
            if let device = item as? IOBluetoothDevice, let services = device.services {
                for service in services {
                    if let serviceRecord = service as? IOBluetoothSDPServiceRecord,
                        serviceRecord.getServiceName() == identifier {
                        magicMouse = device
                    }
                }
            }
        }
        
        return magicMouse
    }
}
