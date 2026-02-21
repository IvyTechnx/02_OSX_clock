import Cocoa
import SwiftUI

// MARK: - Settings

class ClockSettings: ObservableObject {
    static let shared = ClockSettings()

    @Published var use24Hour: Bool {
        didSet { UserDefaults.standard.set(use24Hour, forKey: "use24Hour") }
    }
    @Published var showSeconds: Bool {
        didSet { UserDefaults.standard.set(showSeconds, forKey: "showSeconds") }
    }

    private init() {
        let ud = UserDefaults.standard
        _use24Hour = Published(wrappedValue: ud.bool(forKey: "use24Hour"))
        _showSeconds = Published(wrappedValue:
            ud.object(forKey: "showSeconds") == nil ? true : ud.bool(forKey: "showSeconds"))
    }
}

// MARK: - Traffic Light Buttons

struct TrafficLightButtons: View {
    @State private var isGroupHovering = false

    var body: some View {
        Button(action: { NSApp.terminate(nil) }) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.38, blue: 0.34))
                    .frame(width: 12, height: 12)
                if isGroupHovering {
                    Image(systemName: "xmark")
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundStyle(.black.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isGroupHovering = hovering
            }
        }
    }
}

// MARK: - Clock View

struct ClockFace: View {
    @ObservedObject var settings = ClockSettings.shared
    @State private var now = Date()
    @State private var isHovering = false

    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeString)
                    .font(.system(size: 54, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                if let ampm = ampmString {
                    Text(ampm)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Text(dateString)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(minWidth: 260)
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
        .overlay(animatedBorder)
        .overlay(alignment: .topLeading) {
            TrafficLightButtons()
                .padding(.top, 12)
                .padding(.leading, 14)
                .opacity(isHovering ? 1 : 0)
                .allowsHitTesting(isHovering)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
        .preferredColorScheme(.dark)
        .padding(28)
        .onReceive(timer) { _ in now = Date() }
    }

    // Animated gradient border
    private var animatedBorder: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 15.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let angle = t.truncatingRemainder(dividingBy: 12.0) / 12.0 * 360.0

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            .cyan.opacity(0.4),
                            .clear,
                            .purple.opacity(0.4),
                            .clear,
                        ],
                        center: .center,
                        angle: .degrees(angle)
                    ),
                    lineWidth: 3.0
                )
        }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = settings.use24Hour
            ? (settings.showSeconds ? "HH:mm:ss" : "HH:mm")
            : (settings.showSeconds ? "h:mm:ss" : "h:mm")
        return f.string(from: now)
    }

    private var ampmString: String? {
        guard !settings.use24Hour else { return nil }
        let f = DateFormatter()
        f.dateFormat = "a"
        return f.string(from: now)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: now)
    }
}

// MARK: - App Controller

class AppController: NSObject, NSMenuDelegate {
    let panel: NSPanel

    override init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.acceptsMouseMovedEvents = true

        let hosting = NSHostingView(rootView: ClockFace())
        panel.contentView = hosting

        // Size to fit content
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        panel.setContentSize(size)

        // Restore saved position or default to top-right
        let ud = UserDefaults.standard
        if let x = ud.object(forKey: "windowX") as? CGFloat,
           let y = ud.object(forKey: "windowY") as? CGFloat {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: sf.maxX - size.width - 10,
                y: sf.maxY - size.height - 10
            ))
        }

        // Save position on move
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let origin = self?.panel.frame.origin else { return }
            ud.set(origin.x, forKey: "windowX")
            ud.set(origin.y, forKey: "windowY")
        }

        // Context menu
        let menu = NSMenu()
        menu.delegate = self

        let t24 = NSMenuItem(title: "24時間表示", action: #selector(toggle24), keyEquivalent: "")
        t24.target = self
        menu.addItem(t24)

        let tSec = NSMenuItem(title: "秒を表示", action: #selector(toggleSec), keyEquivalent: "")
        tSec.target = self
        menu.addItem(tSec)

        menu.addItem(.separator())

        let tQuit = NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q")
        tQuit.target = self
        menu.addItem(tQuit)

        hosting.menu = menu
        panel.orderFront(nil)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.items[0].state = ClockSettings.shared.use24Hour ? .on : .off
        menu.items[1].state = ClockSettings.shared.showSeconds ? .on : .off
    }

    @objc func toggle24() { ClockSettings.shared.use24Hour.toggle() }
    @objc func toggleSec() { ClockSettings.shared.showSeconds.toggle() }
    @objc func quit() { NSApp.terminate(nil) }
}

// MARK: - Entry Point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let controller = AppController()
app.run()
