//
//  TCPClient.swift
//  DroneController
//
//  Created by Eldor Bekpulatov on 9/27/25.
//

import Foundation
import Network
import Combine

class TCPClient: ObservableObject {
    @Published var connectionState: NWConnection.State = .cancelled
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "TCPClientQueue")

    private var host: String
    private var port: UInt16

    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
        startConnection(host: host, port: port)
        
    }

    /// Dynamically reconnect to a new host
    func connect(toHost newHost: String) {
        // If same host and port, ignore connect call
//        if newHost == host && connectionState == .ready {
//            print("Already connected to \(host):\(port), skipping reconnect")
//            return
//        }
        print("🔌 Reconnecting to \(newHost):\(port)")
        self.host = newHost
        connection?.cancel()
        startConnection(host: newHost, port: port)
    }

    private func startConnection(host: String, port: UInt16) {
        // ✅ 1. Create TCP options and disable Nagle's algorithm
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true  // 👈 THIS DISABLES NAGLE

        // ✅ 2. Create custom parameters and inject TCP options
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.allowLocalEndpointReuse = true
        
        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            print("❌ Invalid port: \(port)")
            return
        }
        
        // ✅ 3. Create the connection using the custom parameters
        connection = NWConnection(host: nwHost, port: nwPort, using: parameters)

        connection?.stateUpdateHandler = { newState in
            print("TCP State: \(newState)")
            DispatchQueue.main.async {
                self.connectionState = newState // TODO: too much detail gets shown with this
            }
        }
        connection?.start(queue: queue)
    }

    /// Send four-byte combined joystick data
    func sendBothJoysticks(leftX: Int8, leftY: Int8, rightX: Int8, rightY: Int8) {
        let payload = [
            UInt8(bitPattern: leftX),
            UInt8(bitPattern: leftY),
            UInt8(bitPattern: rightX),
            UInt8(bitPattern: rightY)
        ]
        send(data: payload)
    }

    private func send(data: [UInt8]) {
        let dataToSend = Data(data)
        connection?.send(content: dataToSend, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Send error: \(error)")
            }
        })
    }
}
