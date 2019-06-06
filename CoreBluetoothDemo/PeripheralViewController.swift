//
//  PeripheralViewController.swift
//  CoreBluetoothDemo
//
//  Created by Martônio Júnior on 05/06/19.
//  Copyright © 2019 martonio. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController, CBPeripheralManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var advertiserButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    var peripheralManager: CBPeripheralManager?
    var messageBuffer: String? {
        didSet {
            guard let messageBuffer = messageBuffer else { return }
            messageLabel.text = messageBuffer
        }
    }
    var counter = 0
    var service: CBMutableService?
    let serviceUUID = CBUUID(string: "7ec5ca98-8489-11e9-bc42-526af7764f64")
    var serviceCharacteristic: CBMutableCharacteristic?
    let characteristicUUID = CBUUID(string: "7ec5ce6c-8489-11e9-bc42-526af7764f64")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        service = CBMutableService(type: serviceUUID, primary: true)
        serviceCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read],
            value: nil,
            permissions: [.readable])
        service?.characteristics = [serviceCharacteristic!]
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            statusLabel.text = "Unknown"
        case .unsupported:
            statusLabel.text = "Unsupported"
        case .resetting:
            statusLabel.text = "Resetting"
        case .unauthorized:
            statusLabel.text = "Unauthorized"
        case .poweredOff:
            statusLabel.text = "Power OFF"
        case .poweredOn:
            statusLabel.text = "Power ON"
            guard let service = service else { return }
            peripheralManager?.add(service)
        @unknown default:
            print("State not found")
        }
    }

    @IBAction func toggleAdvertising(_ sender: UIButton) {
        guard let peripheralManager = self.peripheralManager, peripheralManager.state == .poweredOn else {return}
        let adData = [CBAdvertisementDataLocalNameKey: "Dente Smurf"]
        peripheralManager.isAdvertising ? peripheralManager.stopAdvertising() : peripheralManager.startAdvertising(adData)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        sendMessageButton.isEnabled = peripheral.isAdvertising
        advertiserButton.titleLabel?.text = peripheral.isAdvertising ? "Stop Advertising" : "Start Advertising"
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Request")
        guard let messageBuffer = self.messageBuffer else { return }
        request.value = messageBuffer.data(using: .utf8)
        peripheralManager?.respond(to: request, withResult: .success)
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        messageBuffer = "buttonPressed \(counter)"
        counter += 1
    }
}
