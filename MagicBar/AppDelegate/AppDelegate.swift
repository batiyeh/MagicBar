//
//  AppDelegate.swift
//  MagicBar
//
//  Created by Brian Atiyeh on 5/8/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Cocoa
import HotKey

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu?
    let mouseTrackingService: MouseTrackingServicable
    let mouseConnectService: MouseConnectServicable
    
    let connectHotkey = HotKey(keyCombo: KeyCombo(key: .m, modifiers: [.command, .shift]))
    let disconnectHotkey = HotKey(keyCombo: KeyCombo(key: .m, modifiers: [.command, .shift, .option]))
    
    override init() {
        mouseTrackingService = MouseTrackingService()
        mouseConnectService = MouseConnectService(mouseTrackingService: mouseTrackingService,
                                                      notificationService: NotificationService())
        super.init()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createApp()
        createMenu()
        assignHotkey()
        let _ = mouseTrackingService.findDevice()
    }
    
    func createApp() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "MagicBarMenuIcon")
            button.action = #selector(menuItemClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    func createMenu() {
        let menu = NSMenu()
        
//        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Issues", action: #selector(openIssues(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Buy Me A Coffee", action: #selector(openBuyMeCoffee(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MagicBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        
        statusBarMenu = menu
    }
    
    func assignHotkey() {
        connectHotkey.keyDownHandler = { [weak self] in
            self?.connectToMouse()
        }
        
        disconnectHotkey.keyDownHandler = { [weak self] in
            self?.disconnectFromMouse()
        }
    }
    
    @objc func menuItemClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp,
            let menu = statusBarMenu {
            statusBarItem.menu = menu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        } else {
            connectToMouse()
        }
    }
    
    func connectToMouse() {
        mouseConnectService.connect()
    }
    
    func disconnectFromMouse() {
        mouseConnectService.disconnect()
    }
    
    @objc func openSettings(_ sender: AnyObject?) {
        print("Settings")
    }
    
    @objc func openBuyMeCoffee(_ sender: AnyObject?) {
        if let url = URL(string: "https://www.buymeacoffee.com/batiyeh") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openIssues(_ sender: AnyObject?) {
        if let url = URL(string: "https://github.com/batiyeh/MagicBar/issues") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func menuDidClose(_ menu: NSMenu) {
        statusBarItem.menu = nil
    }
}
