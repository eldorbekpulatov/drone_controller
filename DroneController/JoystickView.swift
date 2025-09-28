//
//  JoystickView.swift
//  DroneController
//
//  Created by Eldor Bekpulatov on 9/27/25.
//

import SwiftUI

struct JoystickView: View {
    var isLeft: Bool
    var tcpClient: TCPClient

    @Binding var xValue: Int8
    @Binding var yValue: Int8

    @State private var dragOffset = CGSize.zero
    @State private var lastSentX: Int8 = 0
    @State private var lastSentY: Int8 = 0

    private let joystickBaseRadius: CGFloat = 100
    private let knobSize: CGFloat = 60
    private let maxDrag: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: joystickBaseRadius * 2, height: joystickBaseRadius * 2)

            Circle()
                .fill(isLeft ? Color.green : Color.orange)
                .frame(width: knobSize, height: knobSize)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let clampedX = clamp(value.translation.width, to: -maxDrag...maxDrag)
                            let clampedY = clamp(value.translation.height, to: -maxDrag...maxDrag)
                            dragOffset = CGSize(width: clampedX, height: clampedY)

                            let normX = Int8((clampedX / maxDrag) * 127)
                            let normY = Int8((clampedY / maxDrag) * -127) // Inverted Y

                            xValue = normX
                            yValue = normY
                            // TCP client will take care of sending the joystick values
                        }
                        .onEnded { _ in
                            dragOffset = .zero
                            xValue = 0
                            yValue = 0
                            // TCP client will take care of sending the joystick values
                        }
                )
        }
        .frame(width: joystickBaseRadius * 2.5, height: joystickBaseRadius * 2.5)
    }

    func clamp<T: Comparable>(_ value: T, to limits: ClosedRange<T>) -> T {
        return min(max(value, limits.lowerBound), limits.upperBound)
    }
}
