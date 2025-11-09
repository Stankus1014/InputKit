//
//  HorizontalDialPicker.swift
//  InputKit
//
//  Created by William Stankus on 11/1/25.
//
import SwiftUI

public struct HorizontalDialPicker<V>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
    
    @Binding var value: V
    var range: ClosedRange<V>
    var step: V
    var selectedTickColor: Color
    var tickLabelColor: Color
    var tickSpacing: CGFloat = 8.0
    var tickSegmentCount: Int = 10
    var showSegmentValueLabel: Bool = true
    var labelSignificantDigit: Int = 0
    
    @State private var scrollPosition: Int? = nil
    @State private var viewSize: CGSize? = nil
    @State private var initialized: Bool = false
    
    public init(
        value: Binding<V>,
        range: ClosedRange<V>,
        step: V,
        selectedTickColor: Color = .red,
        tickLabelColor: Color = .black,
        tickSpacing: CGFloat = 8.0,
        tickSegmentCount: Int = 10,
        showSegmentValueLabel: Bool = true,
        labelSignificantDigit: Int = 0,
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.selectedTickColor = selectedTickColor
        self.tickLabelColor = tickLabelColor
        self.tickSpacing = tickSpacing
        self.tickSegmentCount = tickSegmentCount
        self.showSegmentValueLabel = showSegmentValueLabel
        self.labelSignificantDigit = labelSignificantDigit
        
    }

    
    public var body: some View {
        ScrollView(.horizontal, content: {
            let totalTicks = Int((range.upperBound - range.lowerBound) / step) + 1
            
            LazyHStack(spacing: tickSpacing) {
                ForEach(0..<totalTicks, id: \.self) { index in
                    let isSegment = index % tickSegmentCount == 0
                    let isTarget = index == scrollPosition
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isTarget ? selectedTickColor : isSegment ? .black : .gray)
                        .frame(width: 3, height: 24)
                        .id(index)
                        .scaleEffect(x: isTarget ? 1.1 : 0.8, y: isTarget ? 1.2 : 0.7, anchor: .bottom)
                        .animation(.default.speed(1.2), value: isTarget)
                        .sensoryFeedback(.selection, trigger: isTarget && initialized)
                        .overlay(alignment: .bottom, content: {
                            if isSegment, self.showSegmentValueLabel {
                                let value = Double(range.lowerBound + V(index) * step)
                                Text("\(String(format: "%.\(labelSignificantDigit)f", value))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(self.tickLabelColor)
                                    .fontWeight(.semibold)
                                    .fixedSize() // required to avoid being cutoff horizontally
                                    .offset(y: 20)
                            }
                        })
                }
                
            }
            .padding(.vertical, 20) // to extend the scrollable area vertically
            .scrollTargetLayout()
            
        })
        .safeAreaPadding(.horizontal, (viewSize?.width ?? 0)/2 ) // so that the start and end ends at center
        .onChange(of: viewSize) { _, newSize in
            guard !initialized, let _ = newSize else { return }
            self.scrollPosition = Int((value - range.lowerBound) / step)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.initialized = true
            }
        }

        .onChange(of: value) {
            self.scrollPosition = Int((value - range.lowerBound) / step)
        }
        .modifier(ViewAlignedCenterBehavior())
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .defaultScrollAnchor(.center, for: .alignment)
        .defaultScrollAnchor(.center, for: .initialOffset)
        .defaultScrollAnchor(.center, for: .sizeChanges)
        .onChange(of: scrollPosition, {
            guard let scrollPosition = self.scrollPosition else { return }
            value = range.lowerBound + V(scrollPosition) * step
        })
        .overlay(content: {
            GeometryReader { geometry in
                if geometry.size != self.viewSize {
                    DispatchQueue.main.async {
                        self.viewSize = geometry.size
                    }
                }
                return Color.clear
            }
        })
    }
}

struct ViewAlignedCenterBehavior: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollTargetBehavior(.viewAligned(anchor: .center))
        } else {
            content.scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    HorizontalDialPicker(value: .constant(74), range: 70...234, step: 0.1)
}
