//
//  MouseTrackingService.swift
//  MagicBar
//
//  Created by Brian Atiyeh on 5/27/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import IOBluetooth
import RxSwift

public enum MouseState {
    case unpaired
    case disconnected
    case connected
    case unknown
}

public protocol MouseTrackingServicable {
    func getDevice() -> Mouse?
    func findDevice()
}

public class MouseTrackingService: MouseTrackingServicable {
    private final let identifier = "Magic Mouse 2"
    private var mouse: Mouse?
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }
    
    public func getDevice() -> Mouse? {
        return mouse
    }
    
    public func findDevice() {
        if let mouse = getSavedDevice() {
            let device = define(magicMouse: mouse)
            set(mouse: device)
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
                        save(device: device)
                        set(mouse: define(magicMouse: device))
                    }
                }
            }
        }
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

// MARK: - Setters / Getters
extension MouseTrackingService {
    func set(mouse: Mouse) {
        self.mouse = mouse
    }
    
    func save(device: IOBluetoothDevice) {
        defaults.set(device.addressString, forKey: "Mouse")
    }
    
    func getSavedDevice() -> IOBluetoothDevice? {
        let address = defaults.string(forKey: "Mouse")
        return IOBluetoothDevice(addressString: address)
    }
}
