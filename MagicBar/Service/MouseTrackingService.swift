//
//  MouseTrackingService.swift
//  MagicBar
//
//  Created by Brian Atiyeh on 5/27/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import IOBluetooth

public enum MouseState {
    case unpaired
    case disconnected
    case connected
    case unknown
}

public protocol MouseTrackingServicable {
    var magicMouse: Mouse? { get }
    func findDevice()
}

public class MouseTrackingService: MouseTrackingServicable {
    public var magicMouse: Mouse?
    private let defaults = UserDefaults.standard
    final let identifier = "Magic Mouse 2"
    
    public func findDevice() {
        if let savedDevice = getSavedDevice() {
            magicMouse = define(magicMouse: savedDevice)
        } else {
            getDeviceFromServiceName()
        }
    }
    
    func getDeviceFromServiceName() {
        guard let devices = IOBluetoothDevice.pairedDevices() else { return }
        
        for item in devices {
            if let device = item as? IOBluetoothDevice, let services = device.services {
                for service in services {
                    if let serviceRecord = service as? IOBluetoothSDPServiceRecord,
                        serviceRecord.getServiceName() == identifier {
                        saveAddress(device: device)
                        magicMouse = define(magicMouse: device)
                    }
                }
            }
        }
    }
    
    func saveAddress(device: IOBluetoothDevice) {
        defaults.set(device.addressString, forKey: "MagicMouse")
    }
    
    func getSavedDevice() -> IOBluetoothDevice? {
        let address = defaults.string(forKey: "MagicMouse")
        return IOBluetoothDevice(addressString: address)
    }
    
    
    private func define(magicMouse device: Device) -> Mouse {
        var mouse = Mouse(device: device, state: .unknown)
        
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
