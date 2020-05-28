//
//  MouseConnectService.swift
//  MagicBar
//
//  Created by Brian Atiyeh on 5/8/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import IOBluetooth
import RxSwift

public protocol MouseConnectServicable {
    func connect()
}

public class MouseConnectService: MouseConnectServicable {
    public var magicMouse: Mouse?
    private let notificationService: NotificationServicable
    
    init(mouseTrackingService: MouseTrackingServicable, notificationService: NotificationServicable) {
        self.notificationService = notificationService
        self.notificationService.requestNotificationAccess()
    }
    
    convenience init() {
        self.init(mouseTrackingService: MouseTrackingService(), notificationService: NotificationService())
    }
    
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
            notificationService.send(title: Strings.Notifications.failedToConnect,
                                     body: Strings.Notifications.deviceNotFound,
                                     caption: nil)
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
                notificationService.send(title: Strings.Notifications.failedToConnect,
                                         body: Strings.Notifications.failedToConnect,
                                         caption: nil)
            }
        case kIOReturnBusy:
            notificationService.send(title: Strings.Notifications.failedToConnect,
                                     body: Strings.Notifications.deviceBusy,
                                     caption: nil)
        default:
            notificationService.send(title: Strings.Notifications.failedToConnect,
                                     body: Strings.Notifications.failedToConnect,
                                     caption: nil)
        }
    }
}
