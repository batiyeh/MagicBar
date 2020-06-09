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
    func disconnect()
}

public class MouseConnectService: MouseConnectServicable {
    private let notificationService: NotificationServicable
    private let mouseTrackingService: MouseTrackingServicable
    private let disposeBag = DisposeBag()
    
    init(mouseTrackingService: MouseTrackingServicable, notificationService: NotificationServicable) {
        self.mouseTrackingService = mouseTrackingService
        self.notificationService = notificationService
        self.notificationService.requestNotificationAccess()
    }
    
    convenience init() {
        self.init(mouseTrackingService: MouseTrackingService(), notificationService: NotificationService())
    }
    
    public func connect() {
        self.mouseTrackingService.getDevice()
            .filter({ (mouse) -> Bool in
                return mouse.state != .connected
            })
            .concatMap(openConnection)
            .delay(.seconds(2), scheduler: MainScheduler.instance)
            .concatMap({ [unowned self] response -> Observable<Mouse> in
                return self.mouseTrackingService.getDevice()
            })
            .concatMap({ [unowned self] mouse -> Observable<IOReturn> in
                guard mouse.state != .connected else { return Observable.just(kIOReturnSuccess) }
                if mouse.state == .disconnected || mouse.state == .unknown {
                    throw ConnectError.failed
                }
                
                return self.pair(mouse: mouse)
            })
            .retry(1)
            .timeout(.seconds(12), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                self?.mouseTrackingService.update(state: .connected)
            }, onError: { [weak self] error in
                self?.notify(error: error)
            }).disposed(by: disposeBag)
    }
    
    public func disconnect() {
        self.mouseTrackingService.getDevice()
            .concatMap(closeConnection)
            .subscribe(onNext: { [weak self] response in
                self?.mouseTrackingService.update(state: .disconnected)
            }, onError: { [weak self] error in
                self?.notify(error: error)
            }).disposed(by: disposeBag)
    }
    
    func openConnection(mouse: Mouse) -> Observable<IOReturn> {
        return Observable.create { [weak self] observer in
            let response = mouse.device.openConnection()
            self?.handleResponse(observer: observer, response: response)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func closeConnection(mouse: Mouse) -> Observable<IOReturn> {
        return Observable.create { [weak self] observer in
            let response = mouse.device.closeConnection()
            self?.handleResponse(observer: observer, response: response)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func pair(mouse: Mouse) -> Observable<IOReturn> {
        return Observable.create { [weak self] observer in
            if let devicePair = IOBluetoothDevicePair(device: mouse.device) {
                let response = devicePair.start()
                self?.handleResponse(observer: observer, response: response)
            } else {
                observer.onError(ConnectError.failed)
            }
            
            observer.onCompleted()
            return Disposables.create()
        }
    }
}


// MARK: - Error Handling
extension MouseConnectService {
    func handleResponse(observer: AnyObserver<IOReturn>, response: IOReturn) {
        switch response {
        case kIOReturnSuccess:
            observer.onNext(response)
        case kIOReturnError:
            observer.onError(ConnectError.failed)
        case kIOReturnBusy:
            observer.onError(ConnectError.busy)
        case kIOReturnNoDevice:
            observer.onError(ConnectError.notFound)
        case kIOReturnOffline:
            observer.onError(ConnectError.offline)
        default:
            observer.onError(ConnectError.failed)
        }
    }
    
    func notify(error: Error) {
        if let error = error as? ConnectError {
            switch error {
            case .busy:
                notificationService.send(title: Strings.Notifications.ConnectInfo.Error.failedToConnect,
                                        body: Strings.Notifications.ConnectInfo.Error.deviceBusy,
                                        caption: nil)
            default:
                notificationService.send(title: Strings.Notifications.ConnectInfo.Error.failedToConnect,
                                         body: Strings.Notifications.ConnectInfo.Error.pleaseTryAgain,
                                         caption: nil)
            }
        } else {
            notificationService.send(title: Strings.Notifications.ConnectInfo.Error.failedToConnect,
                                     body: Strings.Notifications.ConnectInfo.Error.pleaseTryAgain,
                                     caption: nil)
        }
    }
}

public enum ConnectError: Error {
    case failed
    case notFound
    case busy
    case offline
}

