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
    var mouse: BehaviorSubject<Mouse?> { get }
    
    func getDevice() -> Observable<Mouse>
    func findDevice() -> Mouse?
    func update(state: MouseState)
}

public class MouseTrackingService: MouseTrackingServicable {
    private final let identifier = "Magic Mouse 2"
    private let defaults: UserDefaults
    
    public let mouse: BehaviorSubject<Mouse?> = BehaviorSubject(value: nil)
    
    public init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }
    
    public func getDevice() -> Observable<Mouse> {
        return Observable.create { [weak self] observer in
            if let mouse = self?.findDevice() {
                observer.onNext(mouse)
            } else {
                observer.onError(ConnectError.notFound)
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    public func findDevice() -> Mouse? {
        if let mouse = getSavedDevice() {
            let device = define(magicMouse: mouse)
            self.mouse.onNext(device)
            return device
        } else {
            return getDeviceFromServiceName()
        }
    }
    
    func getDeviceFromServiceName() -> Mouse? {
        guard let devices = IOBluetoothDevice.pairedDevices() else { return nil }
        
        for item in devices {
            if let device = item as? IOBluetoothDevice, let services = device.services {
                for service in services {
                    if let serviceRecord = service as? IOBluetoothSDPServiceRecord,
                        serviceRecord.getServiceName() == identifier {
                        save(device: device)
                        let device = define(magicMouse: device)
                        self.mouse.onNext(device)
                        return device
                    }
                }
            }
        }
        
        return nil
    }
    
    func define(magicMouse device: Device) -> Mouse {
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
    public func update(state: MouseState) {
        do {
            if var mouse = try self.mouse.value() {
                mouse.state = state
                self.mouse.onNext(mouse)
            }
        } catch {
            return
        }
    }
    
    func save(device: IOBluetoothDevice) {
        defaults.set(device.addressString, forKey: "Mouse")
    }
    
    func getSavedDevice() -> IOBluetoothDevice? {
        let address = defaults.string(forKey: "Mouse")
        return IOBluetoothDevice(addressString: address)
    }
}
