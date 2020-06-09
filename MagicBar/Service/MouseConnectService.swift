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
    var connectObservable: Disposable?
    
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
        if connectObservable != nil { cancelSubscription() }

        connectObservable = openConnection()
            .delay(.seconds(2), scheduler: MainScheduler.instance)
            .concatMap({ [unowned self] response -> Observable<Mouse> in
                return self.checkStatus()
            })
            .concatMap({ [unowned self] mouse -> Observable<IOReturn> in
                guard mouse.state != .connected else { return Observable.just(kIOReturnSuccess) }
                if mouse.state == .disconnected || mouse.state == .unknown {
                    throw ConnectError.failed
                }
                
                return self.pair(mouse: mouse)
            })
            .retry(3)
            .subscribe(onNext: { [weak self] response in
                self?.mouseTrackingService.update(state: .connected)
            }, onError: { [weak self] error in
                if let error = error as? ConnectError {
                    self?.notify(error: error)
                }
            })
        connectObservable?.disposed(by: disposeBag)
    }
    
    func openConnection() -> Observable<IOReturn> {
        return Observable.create { [weak self] observer in
            if let mouse = self?.mouseTrackingService.getDevice() {
                let response = mouse.device.openConnection()
                self?.handleResponse(observer: observer, response: response)
            } else {
                observer.onError(ConnectError.notFound)
            }
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func checkStatus() -> Observable<Mouse> {
        return Observable.create { [weak self] observer in
            self?.mouseTrackingService.findDevice()
            if let mouse = self?.mouseTrackingService.getDevice() {
                observer.onNext(mouse)
            } else {
                observer.onError(ConnectError.notFound)
            }
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
    
    func cancelSubscription() {
        if connectObservable != nil {
            connectObservable?.dispose()
            connectObservable = nil
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
    
    func notify(error: ConnectError) {
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
    }
}

public enum ConnectError: Error {
    case failed
    case notFound
    case busy
    case offline
}

