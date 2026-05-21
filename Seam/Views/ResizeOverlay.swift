import SwiftUI

enum ResizeHandle: CaseIterable, Hashable {
    case topLeft, topCenter, topRight
    case middleLeft, middleRight
    case bottomLeft, bottomCenter, bottomRight
}

struct ResizeOverlay: View {
    @Binding var rect: CGRect
    @State private var activeDrag: (handle: ResizeHandle, startRect: CGRect)? = nil

    private let handleSize: CGFloat = 22
    private let minSize: CGFloat = 40

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle())

            Rectangle()
                .stroke(Color.antiqueTeal.opacity(0.8),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

            ForEach(ResizeHandle.allCases, id: \.self) { handle in
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.antiqueTeal, lineWidth: 1.5))
                    .frame(width: handleSize, height: handleSize)
                    .position(point(for: handle))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if activeDrag == nil {
                                    activeDrag = (handle, rect)
                                }
                                guard let drag = activeDrag, drag.handle == handle else { return }
                                rect = adjusted(drag.startRect, handle: handle, by: value.translation)
                            }
                            .onEnded { _ in activeDrag = nil }
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func point(for handle: ResizeHandle) -> CGPoint {
        switch handle {
        case .topLeft:      return CGPoint(x: rect.minX, y: rect.minY)
        case .topCenter:    return CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:     return CGPoint(x: rect.maxX, y: rect.minY)
        case .middleLeft:   return CGPoint(x: rect.minX, y: rect.midY)
        case .middleRight:  return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomLeft:   return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomCenter: return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomRight:  return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    private func adjusted(_ s: CGRect, handle: ResizeHandle, by t: CGSize) -> CGRect {
        let dx = t.width, dy = t.height
        switch handle {
        case .topLeft:
            let x = min(s.minX + dx, s.maxX - minSize)
            let y = min(s.minY + dy, s.maxY - minSize)
            return CGRect(x: x, y: y, width: s.maxX - x, height: s.maxY - y)
        case .topCenter:
            let y = min(s.minY + dy, s.maxY - minSize)
            return CGRect(x: s.minX, y: y, width: s.width, height: s.maxY - y)
        case .topRight:
            let y = min(s.minY + dy, s.maxY - minSize)
            return CGRect(x: s.minX, y: y, width: max(s.width + dx, minSize), height: s.maxY - y)
        case .middleLeft:
            let x = min(s.minX + dx, s.maxX - minSize)
            return CGRect(x: x, y: s.minY, width: s.maxX - x, height: s.height)
        case .middleRight:
            return CGRect(x: s.minX, y: s.minY, width: max(s.width + dx, minSize), height: s.height)
        case .bottomLeft:
            let x = min(s.minX + dx, s.maxX - minSize)
            return CGRect(x: x, y: s.minY, width: s.maxX - x, height: max(s.height + dy, minSize))
        case .bottomCenter:
            return CGRect(x: s.minX, y: s.minY, width: s.width, height: max(s.height + dy, minSize))
        case .bottomRight:
            return CGRect(x: s.minX, y: s.minY, width: max(s.width + dx, minSize), height: max(s.height + dy, minSize))
        }
    }
}
