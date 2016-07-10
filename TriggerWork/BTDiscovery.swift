//
//  BTDiscovery.swift
//  TriggerWork
//
//  Created by Owen L Brown on 9/24/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//
//  Modified by Phil Henson on 3/9/16.
//  Copyright © 2016 Lost Nation R & D. All rights reserved.
//

import Foundation
import CoreBluetooth

let btDiscoverySharedInstance = BTDiscovery();

class BTDiscovery: NSObject, CBCentralManagerDelegate {
  
  private var centralManager: CBCentralManager?
  private var peripheralBLE: CBPeripheral?
    
  override init() {
    super.init()
    
    let centralQueue = dispatch_queue_create("com.lostnationrd", DISPATCH_QUEUE_SERIAL)
    centralManager = CBCentralManager(delegate: self, queue: centralQueue)
  }
  
  func startScanning() {
    self.sendBTDiscoveryNotificationWithScanStatus(BLEScanStatus.Started)
    // Start timer to cancel scan if no devices are found in 8 seconds
    
    let _ = Timeout(Constants.BLETimeout) {
      dispatch_async(dispatch_get_main_queue(), { 
        self.scanTimeout()
      })
    }
    if let central = centralManager {
      central.scanForPeripheralsWithServices([UUID.BLEServiceUUID], options: nil)
    }
  }
  
  func stopScanning() {
    self.sendBTDiscoveryNotificationWithScanStatus(BLEScanStatus.Stopped)
    if let central = centralManager {
      central.stopScan()
    }
  }
  
  func scanTimeout() {
    self.sendBTDiscoveryNotificationWithScanStatus(BLEScanStatus.TimedOut)
    self.stopScanning()
  }
  
  var peripheralName: String? {
    get {
      return peripheralBLE?.name
    }
  }
  
  func isConnectedToPeripheral() -> Bool {
    return (peripheralBLE != nil)
  }
  
  var bleService: BTService? {
    didSet {
      if let service = self.bleService {
        service.startDiscoveringServices()
      }
    }
  }
  
  // MARK: - CBCentralManagerDelegate
  
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    // Be sure to retain the peripheral or it will fail during connection.
    
    // Validate peripheral information
    if ((peripheral.name == nil) || (peripheral.name == "")) {
      return
    }
    
    // If not already connected to a peripheral, then connect to this one
    if ((self.peripheralBLE == nil) || (self.peripheralBLE?.state == CBPeripheralState.Disconnected)) {
      // Retain the peripheral before trying to connect
      self.peripheralBLE = peripheral
      
      // Reset service
      self.bleService = nil
      
      // Connect to peripheral
      central.connectPeripheral(peripheral, options: nil)
    }
  }
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    
    // Create new service class
    if (peripheral == self.peripheralBLE) {
      self.bleService = BTService(initWithPeripheral: peripheral)
    }
    
    // Stop scanning for new devices
    self.stopScanning()
  }
  
  func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    
    // See if it was our peripheral that disconnected
    if (peripheral == self.peripheralBLE) {
      self.bleService = nil;
      self.peripheralBLE = nil;
    }
    
    // Start scanning for new devices
    self.startScanning()
  }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Alert user that peripheral has failed to connect
    }
  
  // MARK: - Private
  
  func clearDevices() {
    self.bleService = nil
    self.peripheralBLE = nil
  }
  
  func centralManagerDidUpdateState(central: CBCentralManager) {
    switch (central.state) {
    case CBCentralManagerState.PoweredOff:
      print("Bluetooth powered off")
      self.clearDevices()
      
    case CBCentralManagerState.Unauthorized:
      // Indicate to user that the iOS device does not support BLE.
      print("Bluetooth access unauthorized");
      break
      
    case CBCentralManagerState.Unknown:
      // Wait for another event
      print("Bluetooth state unknown")
      break
      
    case CBCentralManagerState.PoweredOn:
      print("Bluetooth powered on")
      self.stopScanning()
      self.startScanning()
      
    case CBCentralManagerState.Resetting:
      print("Bluetooth resetting")
      self.clearDevices()
      
    case CBCentralManagerState.Unsupported:
      print("Bluetooth not supported by device")
      break
    }
  }
  
  func sendBTDiscoveryNotificationWithScanStatus(scanStatus: String) {
    let scanDetails = [scanStatus: true]
    NSNotificationCenter.defaultCenter().postNotificationName(Constants.BLEServiceScanStatusNotification, object: self, userInfo: scanDetails)
  }

}
