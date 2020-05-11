//
//  MagicMouseService.swift
//  MagicBar
//
//  Created by Brian Atiyeh on 5/8/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import IOBluetooth
import RxSwift

public protocol MagicMouseServicable {
    var magicMouse: MagicMouse? { get }
    func connect()
}

enum MagicMouseState {
    case unpaired
    case disconnected
    case connected
    case unknown
}

public class MagicMouseService: MagicMouseServicable {
    let identifier = "Magic Mouse 2"
    public var magicMouse: MagicMouse?
    
    init() {
        obtainDevice()
    }
    
    public func connect() {
        if let magicMouse = magicMouse {
            switch(magicMouse.state) {
            case .disconnected:
                magicMouse.device.openConnection()
            case .unpaired:
                pair()
            default:
                return
            }
        }
    }
    
    public func pair() {
        if let magicMouse = magicMouse, magicMouse.state == .unpaired {
            if let devicePair = IOBluetoothDevicePair(device: magicMouse.device) {
                devicePair.start()
            }
        }
    }
    
    func obtainDevice() {
        guard let devices = IOBluetoothDevice.pairedDevices() else { return }
        
        for item in devices {
            if let device = item as? IOBluetoothDevice, let services = device.services {
                for service in services {
                    if let serviceRecord = service as? IOBluetoothSDPServiceRecord,
                        serviceRecord.getServiceName() == identifier {
                        magicMouse = define(magicMouse: device)
                    }
                }
            }
        }
    }
    
    private func define(magicMouse device: Device) -> MagicMouse {
        var mouse = MagicMouse(device: device, state: .unknown)
        
        if device.isPaired() && device.isConnected() {
            mouse.state = .connected
        } else if device.isPaired() && !device.isConnected() {
            mouse.state = .disconnected
        } else if !device.isPaired() {
            mouse.state = .unpaired
        }
        
        return mouse
    }
}
