import SwiftUI
import AppKit
import Darwin

// MARK: - Fixed-size utility probe (transfer case 4)
//
// A small utility window declared fixed-size with justification: a timer
// interval picker plus Start/Stop. No sidebar, no resize, no collapse, no
// overflow menu. The correct audit records no-resize N/A with reason and
// checks every primary control is visible and operable — never requiring
// a resize matrix or affordances the app does not declare. The Start
// button prints `utility-action-fired` to stdout so operability is
// observable without screenshots.

// MARK: - Launch configuration (CLI flags)

enum UtilLaunchConfig {
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

struct UtilGeometryDumpKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct UtilGeometryDumpReader: View {
    let id: String
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: UtilGeometryDumpKey.self,
                value: [id: geo.frame(in: .named("util-content"))]
            )
        }
    }
}

// MARK: - Utility form (fixed content, fully visible by declaration)

struct UtilityFormView: View {
    @State private var interval = "5 min"
    @State private var dumpedGeometries: [String: CGRect] = [:]

    private func dumpGeometriesAndExit() {
        for id in dumpedGeometries.keys.sorted() {
            let r = dumpedGeometries[id]!
            print(String(format: "geometry %@ x=%.2f y=%.2f w=%.2f h=%.2f", id as NSString, r.origin.x, r.origin.y, r.size.width, r.size.height))
        }
        fflush(stdout)
        exit(0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Interval")
                    .frame(width: 70, alignment: .trailing)
                    .accessibilityIdentifier("util-label-interval")
                Picker("", selection: $interval) {
                    Text("1 min").tag("1 min")
                    Text("5 min").tag("5 min")
                    Text("15 min").tag("15 min")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .background(UtilGeometryDumpReader(id: "util-control-interval"))
                .accessibilityIdentifier("util-control-interval")
            }
            HStack {
                Button("Start") {
                    print("utility-action-fired")
                    fflush(stdout)
                }
                .keyboardShortcut(.defaultAction)
                .background(UtilGeometryDumpReader(id: "util-button-start"))
                .accessibilityIdentifier("util-button-start")
                Button("Stop") {}
                    .background(UtilGeometryDumpReader(id: "util-button-stop"))
                    .accessibilityIdentifier("util-button-stop")
            }
        }
        .padding(20)
        .frame(width: 320, height: 200, alignment: .topLeading)
        .coordinateSpace(name: "util-content")
        .onPreferenceChange(UtilGeometryDumpKey.self) { dumpedGeometries = $0 }
        .onAppear {
            if UtilLaunchConfig.isDumpGeometry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dumpGeometriesAndExit()
                }
            }
        }
    }
}

// MARK: - App delegate (fixed-size: no resizable mask, no min/max policy)

final class UtilAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        // Declared fixed size with justification (timer utility with three
        // controls; nothing to gain from resizing). No minSize/contentMinSize
        // policy and no resize matrix: N/A with this reason recorded.
        let contentRect = NSRect(x: 0, y: 0, width: 320, height: 200)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Utility Fixture"
        window.isRestorable = false
        let hosting = NSHostingView(rootView: UtilityFormView())
        hosting.frame = contentRect
        window.contentView = hosting
        if UtilLaunchConfig.isLayoutDiagnostics {
            let contentSize = window.contentView?.frame.size ?? .zero
            print("util-diagnostics contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) resizable=false")
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
        appMenu.addItem(withTitle: "About Utility Fixture", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Utility Fixture", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point

let utilDelegate = UtilAppDelegate()
let utilApplication = NSApplication.shared
utilApplication.delegate = utilDelegate
utilApplication.setActivationPolicy(.regular)
utilApplication.run()
