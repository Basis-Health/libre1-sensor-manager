import Foundation
import Combine
import LibreTools // https://github.com/ivalkou/LibreTools

/*
 The unlocking command is `0xA4`.
 The locking command is `0xA2`.
 The password for libre1 is `Data([0xc2, 0xad, 0x75, 0x21])`.
 The password for libreProH is `Data([0xc2, 0xad, 0x00, 0x90])`.
 */

protocol Libre1SensorManagerLogic: AnyObject {
    func readSensorData(completionHandler: @escaping (Result<(SensorState, SensorData), Error>) -> Void)
    func activateSensor(completionHandler: @escaping () -> Void)
}

class Libre1SensorManager: Libre1SensorManagerLogic {
    static let shared = Libre1SensorManager()
    
    var nfcManager: BaseNFCManager
    
    var readSensorDataCancellable: AnyCancellable?
    var activateSensorCancellable: AnyCancellable?
    
    init() {
        self.nfcManager = BaseNFCManager(unlockCode: 0xA4, password: Data([0xc2, 0xad, 0x75, 0x21]))
    }
    
    // First check the sensor state. If it is `new`, then activate the sensor.
    func readSensorData(completionHandler: @escaping (Result<(SensorState, SensorData), Error>) -> Void) {
        self.readSensorDataCancellable = self.nfcManager.perform(.readHistory).receive(on: DispatchQueue.main).sink { reading in
            if let state = reading.sensorState, let data = reading.sensorData {
                completionHandler(Result.success((state, data)))
            } else {
                completionHandler(Result.failure(NSError(domain: Bundle.main.bundleIdentifier ?? String(), code: NSUserCancelledError, userInfo: nil)))
            }
        }
    }
    
    func activateSensor(completionHandler: @escaping () -> Void) {
        self.activateSensorCancellable = self.nfcManager.perform(.activate).receive(on: DispatchQueue.main).sink { reading in
            completionHandler()
        }
    }
}
