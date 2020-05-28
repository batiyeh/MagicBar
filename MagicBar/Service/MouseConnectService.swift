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
    private let notificationService: NotificationServicable
    private let mouseTrackingService: MouseTrackingServicable
    
    init(mouseTrackingService: MouseTrackingServicable, notificationService: NotificationServicable) {
        self.mouseTrackingService = mouseTrackingService
        self.notificationService = notificationService
        self.notificationService.requestNotificationAccess()
    }
    
    convenience init() {
        self.init(mouseTrackingService: MouseTrackingService(), notificationService: NotificationService())
    }
    
    public func connect() {
        openConnection()
        
        if let mouse = mouseTrackingService.getDevice() {
            switch(mouse.state) {
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
        if let mouse = mouseTrackingService.getDevice() {
            let response = mouse.device.openConnection()
            handleConnectResponse(response: response, attemptPair: true)
        }
    }
    
    func pair() {
        if let mouse = mouseTrackingService.getDevice(), mouse.state == .unpaired {
            if let devicePair = IOBluetoothDevicePair(device: mouse.device) {
                let response = devicePair.start()
                handleConnectResponse(response: response)
            }
        }
    }
    
    func handleConnectResponse(response: IOReturn, attemptPair: Bool = false) {
        switch response {
        case kIOReturnSuccess:
            mouseTrackingService.findDevice()
            if let mouse = mouseTrackingService.getDevice(),
                mouse.device.isConnected() {
                return
            } else {
                pair()
            }
        case kIOReturnError:
            if attemptPair {
                pair()
            } else {
                notificationService.send(title: Strings.Notifications.failedToConnect,
                                         body: Strings.Notifications.pleaseTryAgain,
                                         caption: nil)
            }
        case kIOReturnBusy:
            notificationService.send(title: Strings.Notifications.failedToConnect,
                                     body: Strings.Notifications.deviceBusy,
                                     caption: nil)
        default:
            notificationService.send(title: Strings.Notifications.failedToConnect,
                                     body: Strings.Notifications.pleaseTryAgain,
                                     caption: nil)
        }
    }
}
