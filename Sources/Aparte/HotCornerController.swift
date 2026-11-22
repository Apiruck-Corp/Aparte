import AppKit

enum HotCorner: String, CaseIterable {
    case off, topLeft, topRight, bottomLeft, bottomRight

    var title: String {
        switch self {
        case .off: "Off"
        case .topLeft: "Top left"
        case .topRight: "Top right"
        case .bottomLeft: "Bottom left"
        case .bottomRight: "Bottom right"
        }
    }

    func region(in frame: NSRect) -> NSRect? {
        let size: CGFloat = 6
        guard self != .off else { return nil }
        let x = self == .topLeft || self == .bottomLeft ? frame.minX : frame.maxX - size
        let y = self == .bottomLeft || self == .bottomRight ? frame.minY : frame.maxY - size
        return NSRect(x: x, y: y, width: size, height: size)
    }
}

struct HotCornerHover {
    enum Change { case none, arm, cancel }

    private var regions: [NSRect] = []
    private var occupied: NSRect?

    mutating func reset(to corner: HotCorner, screens: [NSRect], pointer: NSPoint) {
        regions = screens.compactMap { corner.region(in: $0) }
        occupied = region(at: pointer)
    }

    mutating func update(at point: NSPoint, hovering: Bool) -> Change {
        let next = region(at: point)
        let previous = occupied
        occupied = next
        // A drag or click consumes this visit, including the release inside the corner.
        guard hovering else { return .cancel }
        guard next != previous else { return .none }
        return next == nil ? .cancel : .arm
    }

    func stillInside(_ point: NSPoint) -> Bool {
        guard let occupied else { return false }
        return NSMouseInRect(point, occupied, false)
    }

    private func region(at point: NSPoint) -> NSRect? {
        regions.first { NSMouseInRect(point, $0, false) }
    }
}

@MainActor
final class HotCornerController {
    private static let preferenceKey = "Aparte.hotCorner"
    private let defaults: UserDefaults
    private let action: () -> Void
    private var hover = HotCornerHover()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var dwell: Timer?
    private(set) var selection: HotCorner

    init(defaults: UserDefaults = .standard, action: @escaping () -> Void) {
        self.defaults = defaults
        self.action = action
        selection = defaults.string(forKey: Self.preferenceKey).flatMap(HotCorner.init(rawValue:)) ?? .off
        if selection != .off { start() }
    }

    func select(_ corner: HotCorner) {
        guard selection != corner else { return }
        invalidate()
        selection = corner
        defaults.set(corner.rawValue, forKey: Self.preferenceKey)
        if selection != .off { start() }
    }

    func screensChanged() {
        guard selection != .off else { return }
        cancelDwell()
        hover.reset(to: selection, screens: NSScreen.screens.map(\.frame), pointer: NSEvent.mouseLocation)
    }

    private func start() {
        screensChanged()
        let events: NSEvent.EventTypeMask = [.mouseMoved,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
            return event
        }
    }

    private func handle(_ event: NSEvent) {
        let point = event.cgEvent?.unflippedLocation ?? NSEvent.mouseLocation
        let hovering = event.type == .mouseMoved && NSEvent.pressedMouseButtons == 0
        switch hover.update(at: point, hovering: hovering) {
        case .none:
            break
        case .cancel:
            cancelDwell()
        case .arm:
            cancelDwell()
            let timer = Timer(timeInterval: 0.35, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.dwell = nil
                    if NSEvent.pressedMouseButtons == 0 && self.hover.stillInside(NSEvent.mouseLocation) {
                        self.action()
                    }
                }
            }
            dwell = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func cancelDwell() {
        dwell?.invalidate()
        dwell = nil
    }

    func invalidate() {
        cancelDwell()
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }
}
