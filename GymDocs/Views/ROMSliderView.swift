import SwiftUI
import UIKit

struct ROMSliderView: View {
    @Binding var value: RangeOfMotion
    let disabled: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let cases = RangeOfMotion.allCases  // normal, concentric, eccentric, full
    
    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let segmentWidth = totalWidth / CGFloat(cases.count - 1)
            let currentX = CGFloat(value.sliderIndex) * segmentWidth
            let clampedX = isDragging ? dragOffset.clamped(to: 0...totalWidth) : currentX
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 6)
                
                // Active track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "FFD52E"))
                    .frame(width: clampedX + 10, height: 6)
                
                // Tick marks + labels
                ForEach(Array(cases.enumerated()), id: \.offset) { index, rom in
                    let x = CGFloat(index) * segmentWidth
                    VStack(spacing: 4) {
                        Circle()
                            .fill(rom == value ? Color(hex: "FFD52E") : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                        Text(rom.displayName)
                            .font(.system(size: 9, weight: rom == value ? .bold : .regular))
                            .foregroundStyle(rom == value ? .primary : .secondary)
                            .fixedSize()
                    }
                    .offset(x: x - 4, y: -18)
                }
                
                // Thumb
                Circle()
                    .fill(Color(hex: "FFD52E"))
                    .frame(width: 22, height: 22)
                    .shadow(radius: 2)
                    .offset(x: clampedX - 11)
                    .gesture(
                        disabled ? nil : DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                isDragging = true
                                dragOffset = g.location.x.clamped(to: 0...totalWidth)
                            }
                            .onEnded { g in
                                isDragging = false
                                let x = g.location.x.clamped(to: 0...totalWidth)
                                let idx = Int((x / segmentWidth).rounded())
                                    .clamped(to: 0...(cases.count - 1))
                                value = RangeOfMotion.fromSliderIndex(idx)
                            }
                    )
            }
            .frame(height: 6)
            .padding(.top, 28) // room for labels above
        }
        .frame(height: 50)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Main View
