import SwiftUI
import AppKit
import Darwin

// MARK: - Dense workspace probe (transfer case 3)
//
// A dense timeline workspace with app-declared constrained panes: a 150pt
// navigation pane, a timeline viewport with declared horizontal scroll,
// and a transport bar. Seeded flaw: the transport bar is a fixed 460pt
// row with no overflow, so at narrow widths its outer controls clip
// outside the timeline viewport (horizontal outer-page scroll is NOT
// declared). Aligned mode places the transport in a declared horizontal
// scroll viewport, so every control stays reachable. Removing the pane
// constraints or the inner scroll to force a fit would itself fail.

// MARK: - Launch configuration (CLI flags)

enum WsLaunchConfig {
    /// `--aligned` puts the transport in a declared horizontal scroll
    /// viewport (reference mode, not repair proof).
    static var isAligned: Bool {
        CommandLine.arguments.contains("--aligned")
    }

    /// `--content-width=N` starts at a custom content width (clamped to min).
    static var customContentWidth: CGFloat? {
        guard let s = flagValue("--content-width"), let d = Double(s), d > 0 else { return nil }
        return CGFloat(d)
    }
    private static func flagValue(_ name: String) -> String? {
        let args = CommandLine.arguments
        for (index, arg) in args.enumerated() {
            if arg == name, index + 1 < args.count { return args[index + 1] }
            if arg.hasPrefix(name + "=") { return String(arg.dropFirst((name + "=").count)) }
        }
        return nil
    }

    /// `--layout-diagnostics` prints window sizes only (no private data).
    static var isLayoutDiagnostics: Bool {
        CommandLine.arguments.contains("--layout-diagnostics")
    }

    /// `--dump-geometry` prints instrumented layout frames in content
    /// points, then exits. Background readers never affect layout.
    static var isDumpGeometry: Bool {
        CommandLine.arguments.contains("--dump-geometry")
    }
}

// MARK: - Instrumented geometry dump (fixture test tooling)

struct WsGeometryDumpKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct WsGeometryDumpReader: View {
    let id: String
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: WsGeometryDumpKey.self,
                value: [id: geo.frame(in: .named("ws-content"))]
            )
        }
    }
}

// MARK: - Workspace (nav + timeline viewport + transport)

struct WorkspaceContentView: View {
    @State private var isPlaying = false
    @State private var dumpedGeometries: [String: CGRect] = [:]

    private func dumpGeometriesAndExit() {
        for id in dumpedGeometries.keys.sorted() {
            let r = dumpedGeometries[id]!
            print(String(format: "geometry %@ x=%.2f y=%.2f w=%.2f h=%.2f", id as NSString, r.origin.x, r.origin.y, r.size.width, r.size.height))
        }
        fflush(stdout)
        exit(0)
    }

    /// Seeded flaw lives here: fixed 460pt row, no overflow. Aligned uses
    /// the declared inner horizontal scroll viewport instead.
    @ViewBuilder
    private var transportBar: some View {
        let controls = Group {
            Button("⏮") {}.frame(width: 60)
            Button(isPlaying ? "⏸" : "▶") { isPlaying.toggle() }.frame(width: 60)
            Button("⏭") {}.frame(width: 60)
            Button("● Rec") {}.frame(width: 80)
            Button("Loop") {}.frame(width: 60)
            Button("Snap") {}.frame(width: 60)
        }
        if WsLaunchConfig.isAligned {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 10) { controls }
                    .frame(width: 460)
            }
            .background(WsGeometryDumpReader(id: "ws-transport"))
            .accessibilityIdentifier("ws-transport")
        } else {
            HStack(spacing: 10) { controls }
                .frame(width: 460)
                .background(WsGeometryDumpReader(id: "ws-transport"))
                .accessibilityIdentifier("ws-transport")
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("Tracks").font(.headline)
                Text("V1 · Dialogue").padding(.vertical, 2)
                Text("V2 · Music").padding(.vertical, 2)
                Text("A1 · Mix").padding(.vertical, 2)
                Spacer()
            }
            .padding(10)
            .frame(width: 150)
            .background(WsGeometryDumpReader(id: "ws-nav"))
            .accessibilityIdentifier("ws-nav")
            VStack(spacing: 0) {
                transportBar
                    .padding(.vertical, 8)
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    HStack(spacing: 0) {
                        ForEach(0..<32) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i % 2 == 0 ? Color.blue.opacity(0.55) : Color.green.opacity(0.45))
                                .frame(width: 90, height: 44)
                                .padding(2)
                        }
                    }
                    .padding(8)
                }
                .background(WsGeometryDumpReader(id: "ws-viewport"))
                .accessibilityIdentifier("ws-viewport")
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .coordinateSpace(name: "ws-content")
        .onPreferenceChange(WsGeometryDumpKey.self) { dumpedGeometries = $0 }
        .onAppear {
            if WsLaunchConfig.isDumpGeometry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dumpGeometriesAndExit()
                }
            }
        }
    }
}

// MARK: - Window policy

enum WsWindowPolicy {
    static let contentDefaultSize = NSSize(width: 1000, height: 560)
    static let contentMinSize = NSSize(width: 560, height: 400)
}

// MARK: - App delegate

final class WsAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        var initialContentSize = WsWindowPolicy.contentDefaultSize
        if let w = WsLaunchConfig.customContentWidth {
            initialContentSize.width = max(w, WsWindowPolicy.contentMinSize.width)
        }
        let contentRect = NSRect(origin: .zero, size: initialContentSize)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Workspace Fixture"
        window.isRestorable = false
        let hosting = NSHostingView(rootView: WorkspaceContentView())
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = contentRect
        window.contentView = hosting
        window.setContentSize(initialContentSize)
        window.contentMinSize = WsWindowPolicy.contentMinSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: WsWindowPolicy.contentMinSize)).size
        if WsLaunchConfig.isLayoutDiagnostics {
            let contentSize = window.contentView?.frame.size ?? .zero
            print("ws-diagnostics contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) aligned=\(WsLaunchConfig.isAligned)")
            fflush(stdout)
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func makeMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Workspace Fixture", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Workspace Fixture", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point

let wsDelegate = WsAppDelegate()
let wsApplication = NSApplication.shared
wsApplication.delegate = wsDelegate
wsApplication.setActivationPolicy(.regular)
wsApplication.run()
