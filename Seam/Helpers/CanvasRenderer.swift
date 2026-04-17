import SwiftUI
import UIKit

// MARK: - Catmull-Rom smoothing

/// Converts raw touch points into a smooth cubic Bézier path.
/// For each segment P1→P2, control points are derived from neighbors P0 and P3:
///   cp1 = P1 + (P2 - P0) / 6
///   cp2 = P2 - (P3 - P1) / 6
func catmullRomPath(_ points: [CGPoint]) -> Path {
    guard points.count > 1 else {
        var p = Path()
        if let pt = points.first { p.move(to: pt) }
        return p
    }

    var path = Path()
    path.move(to: points[0])

    guard points.count > 2 else {
        path.addLine(to: points[1])
        return path
    }

    for i in 1 ..< points.count - 1 {
        let p0 = points[max(i - 1, 0)]
        let p1 = points[i]
        let p2 = points[i + 1]
        let p3 = points[min(i + 2, points.count - 1)]

        let cp1 = CGPoint(
            x: p1.x + (p2.x - p0.x) / 6,
            y: p1.y + (p2.y - p0.y) / 6
        )
        let cp2 = CGPoint(
            x: p2.x - (p3.x - p1.x) / 6,
            y: p2.y - (p3.y - p1.y) / 6
        )
        path.addCurve(to: p2, control1: cp1, control2: cp2)
    }

    return path
}

/// Same curve, but as UIBezierPath for use in UIGraphicsImageRenderer.
func catmullRomUIBezierPath(_ points: [CGPoint]) -> UIBezierPath {
    let path = UIBezierPath()
    guard points.count > 1 else {
        if let pt = points.first { path.move(to: pt) }
        return path
    }

    path.move(to: points[0])

    guard points.count > 2 else {
        path.addLine(to: points[1])
        return path
    }

    for i in 1 ..< points.count - 1 {
        let p0 = points[max(i - 1, 0)]
        let p1 = points[i]
        let p2 = points[i + 1]
        let p3 = points[min(i + 2, points.count - 1)]

        let cp1 = CGPoint(
            x: p1.x + (p2.x - p0.x) / 6,
            y: p1.y + (p2.y - p0.y) / 6
        )
        let cp2 = CGPoint(
            x: p2.x - (p3.x - p1.x) / 6,
            y: p2.y - (p3.y - p1.y) / 6
        )
        path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
    }

    return path
}

/// Raw polyline — NO smoothing. Preserves point-level jitter for crayon grain.
func rawPolylinePath(_ points: [CGPoint]) -> Path {
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: first)
    for pt in points.dropFirst() { path.addLine(to: pt) }
    return path
}

func rawUIBezierPolylinePath(_ points: [CGPoint]) -> UIBezierPath {
    let path = UIBezierPath()
    guard let first = points.first else { return path }
    path.move(to: first)
    for pt in points.dropFirst() { path.addLine(to: pt) }
    return path
}

// MARK: - Canvas Renderer

struct CanvasRenderer {
    static func renderStrokes(_ strokes: [Stroke], size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            for stroke in strokes {
                guard stroke.points.count > 0 else { continue }
                switch stroke.brushStyle {
                case .eraser:
                    let path = catmullRomUIBezierPath(stroke.points)
                    path.lineWidth = stroke.lineWidth
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    UIColor.white.setStroke()
                    path.stroke()
                case .micronPen:
                    let path = catmullRomUIBezierPath(stroke.points)
                    path.lineWidth = stroke.lineWidth
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    UIColor(stroke.color).setStroke()
                    path.stroke()
                case .crayon:
                    let basePath = catmullRomUIBezierPath(stroke.points)
                    basePath.lineWidth = stroke.lineWidth
                    basePath.lineCapStyle = .round
                    basePath.lineJoinStyle = .round
                    UIColor(stroke.color).withAlphaComponent(0.45).setStroke()
                    basePath.stroke()
                    let crayonConfigs: [(Double, CGFloat)] = [
                        (0.30, 0.90), (0.20, 1.10), (0.25, 0.75),
                        (0.15, 1.20), (0.20, 0.65), (0.12, 1.00)
                    ]
                    for (i, layer) in stroke.crayonLayers.enumerated() where !layer.isEmpty {
                        let (opacity, wMult) = crayonConfigs[min(i, crayonConfigs.count - 1)]
                        let offsetPath = rawUIBezierPolylinePath(layer)
                        offsetPath.lineWidth = stroke.lineWidth * wMult
                        offsetPath.lineCapStyle = .round
                        offsetPath.lineJoinStyle = .round
                        UIColor(stroke.color).withAlphaComponent(opacity).setStroke()
                        offsetPath.stroke()
                    }
                }
            }
        }
    }
}
