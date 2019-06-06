//
//  CentralViewController.swift
//  CoreBluetoothDemo
//
//  Created by Martônio Júnior on 05/06/19.
//  Copyright © 2019 martonio. All rights reserved.
//

import UIKit
import CoreBluetooth

class CentralViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var deviceTableView: UITableView!
    
    var connectedDevice: CBPeripheral?
    var devices: [CBPeripheral] = []
    var centralManager: CBCentralManager?
    let serviceUUID = CBUUID(string: "7ec5ca98-8489-11e9-bc42-526af7764f64")
    let characteristicUUID = CBUUID(string: "7ec5ce6c-8489-11e9-bc42-526af7764f64")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disconnectButton.isEnabled = false
        messageLabel.text = "Waiting to connect..."
        deviceTableView.delegate = self
        deviceTableView.dataSource = self
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        print("Service UUID: \(serviceUUID)")
    }
    
    @IBAction func disconnectBluetoothDevice(_ sender: UIButton) {
        disconnectButton.isEnabled = false
        resetDeviceLabels()
        guard let connectedDevice = self.connectedDevice else { return }
        self.centralManager?.cancelPeripheralConnection(connectedDevice)
        self.connectedDevice = nil
    }
    
    func resetDeviceLabels() {
        deviceLabel.text = "Device"
        messageLabel.text = ""
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            statusLabel.text = "Unknown"
        case .unsupported:
            statusLabel.text = "Unsupported"
        case .resetting:
            statusLabel.text = "Resetting"
        case .unauthorized:
            statusLabel.text = "Unauthorized"
        case .poweredOff:
            statusLabel.text = "Powered OFF"
        case .poweredOn:
            statusLabel.text = "Powered ON"
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        @unknown default:
            print("State not found")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let peripheralName = peripheral.name else {
            print("ERROR getting peripheral name")
            return
        }
        if devices.first(where: { (s1) -> Bool in
            return s1.name == peripheralName
        }) == nil {
            devices.insert(peripheral, at: 0)
            deviceTableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let peripheralName = peripheral.name else { return }
        devices.removeAll { (d) -> Bool in
            return d.name == peripheralName
        }
        deviceLabel.text = peripheralName
        messageLabel.text = ""
        disconnectButton.isEnabled = true
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        resetDeviceLabels()
        deviceTableView.reloadData()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (t) in
                    self.connectedDevice?.readValue(for: characteristic)
                }
            } else if characteristic.properties.contains(.notify) {
                
            } else if characteristic.properties.contains(.write) {
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let dataValue = characteristic.value else { return }
        switch characteristic.uuid {
        case characteristicUUID:
            let message = String(bytes: dataValue, encoding: .utf8)
            self.messageLabel.text = message
            break
        default:
            break
        }
    }
}

extension CentralViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Devices available"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "device") else { return UITableViewCell(style: .default, reuseIdentifier: "device")}
        guard let deviceName = devices[indexPath.row].name else { return cell }
        cell.textLabel?.text = deviceName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.connectedDevice = devices[indexPath.row]
        self.connectedDevice?.delegate = self
        self.centralManager?.connect(connectedDevice!, options: nil)
        deviceLabel.text = self.connectedDevice!.name
        self.centralManager?.stopScan()
    }
    
}
