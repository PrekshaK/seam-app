import SwiftUI
import SwiftData

enum BrushStyle { case micronPen, crayon, eraser }

struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool
    var brushStyle: BrushStyle
    var crayonLayers: [[CGPoint]]

    init(points: [CGPoint], color: Color, lineWidth: CGFloat, brushStyle: BrushStyle) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.brushStyle = brushStyle
        self.isEraser = brushStyle == .eraser
        if brushStyle == .crayon {
            // 6 layers with large random spread — gives rough, waxy crayon edges
            self.crayonLayers = (0..<6).map { _ in
                let spread = CGFloat.random(in: 4.0...8.0)
                return points.map {
                    CGPoint(x: $0.x + CGFloat.random(in: -spread...spread),
                            y: $0.y + CGFloat.random(in: -spread...spread))
                }
            }
        } else {
            self.crayonLayers = []
        }
    }
}

struct DrawView: View {
    enum Tool { case micronPen, crayon, eraser, move }
    enum Size: CGFloat, CaseIterable {
        case small = 3, medium = 6, large = 12, extraLarge = 20

        var displaySize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            case .extraLarge: return 20
            }
        }
    }

    @State private var strokes: [Stroke] = []
    @State private var redoStack: [Stroke] = []
    @State private var currentPoints: [CGPoint] = []
    @State private var selectedTool: Tool = .micronPen
    @State private var selectedColor: Color = .black
    @State private var selectedSize: Size = .medium
    @Binding var selectedTab: Int
    @State private var canvasSize: CGSize = .zero
    @State private var showSaveSheet = false

    init(selectedTab: Binding<Int> = .constant(1)) {
        self._selectedTab = selectedTab
    }

    // Endpoint dot — last stroke's terminal point, shown until the next stroke starts nearby
    @State private var endpointDot: CGPoint? = nil
    @State private var endpointDotOpacity: Double = 1.0

    // Zoom / pan state
    @State private var pointerLocation: CGPoint? = nil

    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    @Environment(\.dismiss) var dismiss

    let drawingColors: [Color] = [
        .black, .gray, Color(red: 0.4, green: 0.2, blue: 0.1),
        Color.teal, Color.yellow, Color.pink,
        .red, .orange, .green, .blue, .purple
    ]

    // Convert a point from the gesture overlay's coordinate space to canvas-local space.
    // The canvas is scaled around its center then offset, so we invert that transform.
    private func toCanvasLocal(_ point: CGPoint) -> CGPoint {
        let cx = canvasSize.width / 2
        let cy = canvasSize.height / 2
        return CGPoint(
            x: (point.x - canvasOffset.width - cx) / canvasScale + cx,
            y: (point.y - canvasOffset.height - cy) / canvasScale + cy
        )
    }

    private var isZoomed: Bool { canvasScale != 1.0 || canvasOffset != .zero }

    private let snapRadius: CGFloat = 30

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    // Returns the closest endpoint among all existing strokes, if within snapRadius.
    private func snapTarget(for point: CGPoint) -> CGPoint? {
        var best: CGPoint? = nil
        var bestDist = snapRadius
        for stroke in strokes {
            if let last = stroke.points.last {
                let d = distance(point, last)
                if d < bestDist { bestDist = d; best = last }
            }
            if let first = stroke.points.first {
                let d = distance(point, first)
                if d < bestDist { bestDist = d; best = first }
            }
        }
        return best
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Cancel")
                            .font(.custom("PatrickHand-Regular", size: 20))
                    }
                    .foregroundColor(.primary)
                }

                Spacer()

                // Zoom level indicator + reset
                if isZoomed {
                    Button(action: resetZoom) {
                        Text("\(Int(canvasScale * 100))%")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.teal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.12)))
                    }
                } else {
                    Text("Sketch Your Item")
                        .font(.custom("PatrickHand-Regular", size: 24))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: {
                    if !strokes.isEmpty { showSaveSheet = true } else { dismiss() }
                }) {
                    Text("Done")
                        .font(.custom("PatrickHand-Regular", size: 20))
                        .foregroundColor(.teal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.teal.opacity(0.15)))
                }
                .disabled(strokes.isEmpty)
                .opacity(strokes.isEmpty ? 0.4 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("SoftBackground"))

            // Canvas Area
            GeometryReader { _ in
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                    Canvas { context, _ in
                        let style = { (w: CGFloat) in
                            StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
                        }
                        for stroke in strokes {
                            guard !stroke.points.isEmpty else { continue }
                            switch stroke.brushStyle {
                            case .eraser:
                                context.stroke(catmullRomPath(stroke.points), with: .color(.white), style: style(stroke.lineWidth))
                            case .micronPen:
                                context.stroke(catmullRomPath(stroke.points), with: .color(stroke.color), style: style(stroke.lineWidth))
                            case .crayon:
                                // Smooth base gives the colour body
                                context.stroke(catmullRomPath(stroke.points), with: .color(stroke.color.opacity(0.45)), style: style(stroke.lineWidth))
                                // Raw jagged layers — no Catmull-Rom so random offsets stay as rough edges
                                let crayonConfigs: [(Double, CGFloat, [CGFloat])] = [
                                    (0.28, 0.95, []),
                                    (0.22, 1.05, [2.5, 1.5]),
                                    (0.20, 0.80, []),
                                    (0.18, 1.15, [2.0, 2.0]),
                                    (0.15, 0.70, [3.0, 1.5]),
                                    (0.12, 1.00, [1.5, 2.5]),
                                ]
                                for (i, layer) in stroke.crayonLayers.enumerated() where !layer.isEmpty {
                                    let (opacity, wMult, dash) = crayonConfigs[min(i, crayonConfigs.count - 1)]
                                    context.stroke(rawPolylinePath(layer), with: .color(stroke.color.opacity(opacity)),
                                        style: StrokeStyle(lineWidth: stroke.lineWidth * wMult, lineCap: .round, lineJoin: .round, dash: dash, dashPhase: CGFloat(i) * 2.3))
                                }
                            }
                        }
                        if !currentPoints.isEmpty {
                            switch selectedTool {
                            case .eraser:
                                context.stroke(catmullRomPath(currentPoints), with: .color(.white), style: style(selectedSize.rawValue))
                            case .micronPen:
                                context.stroke(catmullRomPath(currentPoints), with: .color(selectedColor), style: style(selectedSize.rawValue))
                            case .crayon:
                                let w = selectedSize.rawValue
                                context.stroke(catmullRomPath(currentPoints), with: .color(selectedColor.opacity(0.45)), style: style(w))
                                context.stroke(catmullRomPath(currentPoints), with: .color(selectedColor.opacity(0.25)),
                                    style: StrokeStyle(lineWidth: w * 1.05, lineCap: .round, lineJoin: .round, dash: [2.5, 1.5], dashPhase: 0.5))
                                context.stroke(catmullRomPath(currentPoints), with: .color(selectedColor.opacity(0.20)),
                                    style: StrokeStyle(lineWidth: w * 0.80, lineCap: .round, lineJoin: .round, dash: [2.0, 2.0], dashPhase: 2.0))
                            case .move:
                                break
                            }
                        }

                        // Pointer ring — shows where the next stroke will land (50pt above finger)
                        if let pt = pointerLocation, selectedTool != .move {
                            let r = selectedSize.rawValue / 2 + 2
                            let ring = Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
                            context.stroke(ring, with: .color(selectedTool == .eraser ? Color.gray : selectedColor), style: StrokeStyle(lineWidth: 1.5))
                            let dot = Path(ellipseIn: CGRect(x: pt.x - 1.5, y: pt.y - 1.5, width: 3, height: 3))
                            context.fill(dot, with: .color(selectedTool == .eraser ? Color.gray : selectedColor))
                        }

                        // Endpoint dot — pulses at the last stroke's end to guide connection
                        if let ep = endpointDot, selectedTool != .move {
                            let outerR: CGFloat = 7
                            let outerRing = Path(ellipseIn: CGRect(x: ep.x - outerR, y: ep.y - outerR, width: outerR * 2, height: outerR * 2))
                            context.stroke(outerRing, with: .color(Color.teal.opacity(endpointDotOpacity * 0.5)), style: StrokeStyle(lineWidth: 1.5))
                            let innerR: CGFloat = 3
                            let dot = Path(ellipseIn: CGRect(x: ep.x - innerR, y: ep.y - innerR, width: innerR * 2, height: innerR * 2))
                            context.fill(dot, with: .color(Color.teal.opacity(endpointDotOpacity)))
                        }

                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .scaleEffect(canvasScale, anchor: .center)
                    .offset(canvasOffset)
                    .animation(.interactiveSpring(response: 0.25), value: canvasScale)
                    .animation(.interactiveSpring(response: 0.25), value: canvasOffset)

                }
                // Capture the actual padded canvas size (not the full GeometryReader size)
                .background(GeometryReader { inner in
                    Color.clear.onAppear { canvasSize = inner.size }
                })
                // Gestures on the ZStack so location is in ZStack-local coordinates
                .contentShape(Rectangle())
                .gesture(mainGesture())
                .simultaneousGesture(pinchGesture())
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Toolbar
            VStack(spacing: 16) {
                Divider().padding(.horizontal, 20)

                // Undo / Redo / Clear
                HStack(spacing: 20) {
                    HStack(spacing: 16) {
                        ToolButton(icon: "arrow.uturn.backward", isEnabled: !strokes.isEmpty) {
                            guard let last = strokes.popLast() else { return }
                            redoStack.append(last)
                            endpointDot = nil
                        }
                        ToolButton(icon: "arrow.uturn.forward", isEnabled: !redoStack.isEmpty) {
                            guard let redo = redoStack.popLast() else { return }
                            strokes.append(redo)
                        }
                    }
                    Spacer()
                    Button(action: {
                        strokes.removeAll(); redoStack.removeAll(); currentPoints.removeAll()
                        endpointDot = nil
                    }) {
                        Text("Clear All")
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.red.opacity(0.3), lineWidth: 1.5))
                    }
                    .disabled(strokes.isEmpty)
                    .opacity(strokes.isEmpty ? 0.3 : 1.0)
                }
                .padding(.horizontal, 20)

                // Tool Picker
                HStack(spacing: 8) {
                    ToolToggleButton(icon: "pencil.tip", label: "Micron", isSelected: selectedTool == .micronPen) {
                        selectedTool = .micronPen
                    }
                    ToolToggleButton(icon: "paintbrush.pointed.fill", label: "Crayon", isSelected: selectedTool == .crayon) {
                        selectedTool = .crayon
                    }
                    ToolToggleButton(icon: "eraser.fill", label: "Erase", isSelected: selectedTool == .eraser) {
                        selectedTool = .eraser
                    }
                    ToolToggleButton(icon: "hand.draw.fill", label: "Move", isSelected: selectedTool == .move) {
                        selectedTool = .move
                    }
                }
                .padding(.horizontal, 20)

                // Size Picker (hidden in Move mode)
                if selectedTool != .move {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brush Size")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)

                        HStack(spacing: 20) {
                            ForEach(Size.allCases, id: \.self) { size in
                                Circle()
                                    .fill(selectedSize == size ? Color.teal : Color.gray.opacity(0.4))
                                    .frame(width: size.displaySize, height: size.displaySize)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(selectedSize == size ? Color.teal : Color.clear, lineWidth: 2)
                                            .padding(-4)
                                    )
                                    .onTapGesture { selectedSize = size }
                                    .frame(width: 32, height: 32)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Color Picker (drawing tools only)
                if selectedTool == .micronPen || selectedTool == .crayon {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(drawingColors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle().strokeBorder(
                                                selectedColor == color ? Color.teal : Color.gray.opacity(0.2),
                                                lineWidth: selectedColor == color ? 3 : 1
                                            )
                                        )
                                        .shadow(color: selectedColor == color ? Color.teal.opacity(0.3) : .clear, radius: 4)
                                        .onTapGesture { selectedColor = color }
                                }
                                ColorPicker("", selection: $selectedColor)
                                    .labelsHidden()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay(Circle().strokeBorder(Color.gray.opacity(0.3), lineWidth: 1))
                                    .onChange(of: selectedColor) { _ in }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }

                if selectedTool == .move {
                    // Move mode hint
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(.teal)
                        Text("Drag to pan · Pinch to zoom")
                            .font(.custom("PatrickHand-Regular", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        if isZoomed {
                            Button("Reset", action: resetZoom)
                                .font(.custom("PatrickHand-Regular", size: 17))
                                .foregroundColor(.teal)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical, 16)
            .background(Color("SoftBackground"))
        }
        .background(Color("SoftBackground").ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showSaveSheet) {
            SaveSketchSheet(
                strokes: strokes,
                canvasSize: canvasSize,
                onSave: { _ in
                    strokes = []
                    redoStack = []
                    currentPoints = []
                    endpointDot = nil
                    selectedTab = 0
                    dismiss()
                }
            )
        }
    }

    // MARK: - Gestures

    private func mainGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if selectedTool == .move {
                    canvasOffset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                } else {
                    let p = value.location
                    var rawPoint = toCanvasLocal(CGPoint(x: p.x, y: p.y - 50))

                    // On the very first point of a new stroke, try to snap to a nearby endpoint
                    if currentPoints.isEmpty, let snapped = snapTarget(for: rawPoint) {
                        rawPoint = snapped
                        endpointDot = nil  // consumed — dismiss the dot
                    }

                    currentPoints.append(rawPoint)
                    pointerLocation = rawPoint
                }
            }
            .onEnded { _ in
                pointerLocation = nil
                if selectedTool == .move {
                    lastOffset = canvasOffset
                } else if !currentPoints.isEmpty {
                    let brushStyle: BrushStyle = selectedTool == .eraser ? .eraser : (selectedTool == .crayon ? .crayon : .micronPen)
                    strokes.append(Stroke(
                        points: currentPoints,
                        color: selectedTool == .eraser ? .white : selectedColor,
                        lineWidth: selectedSize.rawValue,
                        brushStyle: brushStyle
                    ))

                    // Show endpoint dot at where this stroke ended
                    if selectedTool == .micronPen || selectedTool == .crayon, let last = currentPoints.last {
                        endpointDot = last
                        endpointDotOpacity = 1.0
                        // Fade out after 3 seconds
                        withAnimation(.easeIn(duration: 0.4).delay(2.6)) {
                            endpointDotOpacity = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if endpointDotOpacity == 0 { endpointDot = nil; endpointDotOpacity = 1.0 }
                        }
                    }

                    currentPoints = []
                    redoStack = []
                }
            }
    }

    private func pinchGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                canvasScale = max(0.5, min(4.0, lastScale * value))
            }
            .onEnded { _ in
                lastScale = canvasScale
            }
    }

    private func resetZoom() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            canvasScale = 1.0
            canvasOffset = .zero
        }
        lastScale = 1.0
        lastOffset = .zero
    }
}

// MARK: - Helper Views

struct ToolButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isEnabled ? .primary : .gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .background(Circle().fill(isEnabled ? Color.gray.opacity(0.1) : Color.clear))
        }
        .disabled(!isEnabled)
    }
}

struct ToolToggleButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .medium))
                Text(label).font(.custom("PatrickHand-Regular", size: 20))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.teal : Color.gray.opacity(0.1)))
        }
    }
}

#Preview {
    DrawView()
}
