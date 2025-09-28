//
//  ContentView.swift
//  DroneController
//
//  Created by Eldor Bekpulatov on 9/27/25.
//

import SwiftUI
import Network

struct ContentView: View {
    @State private var ipAddress: String = "192.168.12.48"
    @StateObject var tcpClient = TCPClient(host: "192.168.12.48", port: 80)
    
    // All joystick values
    @State private var leftX: Int8 = 0
    @State private var leftY: Int8 = 0
    @State private var rightX: Int8 = 0
    @State private var rightY: Int8 = 0

    // For avoiding duplicates
    @State private var lastSentValues: (Int8, Int8, Int8, Int8) = (0, 0, 0, 0)

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    HStack {
                        TextField("Enter ESP32 IP Address", text: $ipAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: 250)
                            .cornerRadius(10)
                            
                        
                        Button("Connect") {
                            tcpClient.connect(toHost: ipAddress)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Text("Connection: \(String(describing: tcpClient.connectionState))")
                        .foregroundColor(tcpClient.connectionState == .ready ? .green : .red)
                }
                .padding(.top, 30)
                .border(Color.red)  // helps see the VStack’s bounds
                
                Spacer()

                // 🕹️ Two Joysticks
                HStack(spacing: 40) {
                    JoystickView(
                        isLeft: true,
                        tcpClient: tcpClient,
                        xValue: $leftX,
                        yValue: $leftY
                    )

                    JoystickView(
                        isLeft: false,
                        tcpClient: tcpClient,
                        xValue: $rightX,
                        yValue: $rightY
                    )
                }
                .frame(maxHeight: 300)
                
                Spacer()
                
                // Small box showing joystick values in center
                VStack(spacing: 6) {
                    Text("Left Joystick: x=\(leftX), y=\(leftY)")
                    Text("Right Joystick: x=\(rightX), y=\(rightY)")
                }
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.75))
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: 250)
                .padding(.bottom, 0)
                .border(Color.red)  // helps see the VStack’s bounds

            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            
        }
        .onAppear {
            // 🔁 Start combined joystick update loop
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                let current = (leftX, leftY, rightX, rightY)
                if current != lastSentValues {
                    tcpClient.sendBothJoysticks(
                        leftX: leftX, leftY: leftY,
                        rightX: rightX, rightY: rightY
                    )
                    lastSentValues = current
                }
            }
        }
    }
}


