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

enum MagicMouseState {
    case unpaired
    case disconnected
    case connected
    case unknown
}

public protocol MagicMouseServicable {
    var magicMouse: MagicMouse? { get }
    func connect()
    func findDevice()
}

public class MagicMouseService: MagicMouseServicable {
    public var magicMouse: MagicMouse?
    private let notificationService: NotificationService
    private let defaults = UserDefaults.standard
    
    final let identifier = "Magic Mouse 2"
    
    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
        self.notificationService.requestNotificationAccess()
        findDevice()
    }
    
    public func findDevice() {
        if let savedDevice = getSavedDevice() {
            magicMouse = define(magicMouse: savedDevice)
            print(magicMouse)
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

// MARK: Device Connection
extension MagicMouseService {
    public func connect() {
        openConnection()
        if let magicMouse = magicMouse {
            switch(magicMouse.state) {
            case .disconnected:
                openConnection()
            case .unpaired:
                pair()
            default:
                return
            }
        } else {
            notificationService.send(title: Strings.Notifications.failedToConnect, body: Strings.Notifications.deviceNotFound)
        }
    }
    
    func openConnection() {
        if let magicMouse = magicMouse {
            let response = magicMouse.device.openConnection()
            handleConnectResponse(response: response, attemptPair: true)
        }
    }
    
    func pair() {
        if let magicMouse = magicMouse, magicMouse.state == .unpaired {
            if let devicePair = IOBluetoothDevicePair(device: magicMouse.device) {
                let response = devicePair.start()
                handleConnectResponse(response: response)
            }
        }
    }
    
    func handleConnectResponse(response: IOReturn, attemptPair: Bool = false) {
        switch response {
        case kIOReturnSuccess:
            return
        case kIOReturnError:
            if attemptPair {
                pair()
            } else {
                notificationService.send(title: Strings.Notifications.failedToConnect, body: Strings.Notifications.failedToConnect)
            }
        case kIOReturnBusy:
            notificationService.send(title: Strings.Notifications.failedToConnect, body: Strings.Notifications.deviceBusy)
        default:
            notificationService.send(title: Strings.Notifications.failedToConnect, body: Strings.Notifications.failedToConnect)
        }
    }
}
