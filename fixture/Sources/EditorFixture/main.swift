import SwiftUI
import AppKit
import Darwin

// MARK: - Document editor probe (transfer case 2)
//
// A document editor where the inspector is the ESSENTIAL formatting editor
// for the declared primary task and the side navigation is optional and
// collapsible. Seeded flaw: the inspector format bar is a fixed 300pt row
// with no wrap or scroll, so at narrow widths (inspector pane at its
// 200pt minimum) the trailing controls clip. Aligned mode wraps the bar
// into two rows. The inspector must never be forced to collapse: it is
// essential, and collapsing it would strand required function.

// MARK: - Launch configuration (CLI flags)

enum EditLaunchConfig {
    /// `--aligned` wraps the format bar (reference mode, not repair proof).
    static var isAligned: Bool {
        CommandLine.arguments.contains("--aligned")
    }

    /// `--nav-hidden` starts with the optional nav collapsed (same state as
    /// manual collapse; no behavior change beyond initial state).
    static var isNavHidden: Bool {
        CommandLine.arguments.contains("--nav-hidden")
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

struct EditGeometryDumpKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct EditGeometryDumpReader: View {
    let id: String
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: EditGeometryDumpKey.self,
                value: [id: geo.frame(in: .named("edit-content"))]
            )
        }
    }
}

// MARK: - Editor (nav + document + essential inspector)

struct EditorWidthKey: PreferenceKey {
    static var defaultValue: CGFloat? { nil }
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

struct EditorContentView: View {
    @State private var navVisible = !EditLaunchConfig.isNavHidden
    @State private var text = "The quick brown fox jumps over the lazy dog.\nPack my box with five dozen liquor jugs."
    @State private var fontSize = 13.0
    @State private var dumpedGeometries: [String: CGRect] = [:]
    @State private var measuredContentWidth: CGFloat?

    private func dumpGeometriesAndExit() {
        for id in dumpedGeometries.keys.sorted() {
            let r = dumpedGeometries[id]!
            print(String(format: "geometry %@ x=%.2f y=%.2f w=%.2f h=%.2f", id as NSString, r.origin.x, r.origin.y, r.size.width, r.size.height))
        }
        fflush(stdout)
        exit(0)
    }

    /// Seeded flaw lives here: fixed 300pt row, no wrap/scroll. Aligned
    /// wraps into two short rows that fit the 200pt minimum pane.
    @ViewBuilder
    private var formatBar: some View {
        if EditLaunchConfig.isAligned {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button("B") {}.frame(width: 44)
                    Button("I") {}.frame(width: 44)
                    Button("U") {}.frame(width: 44)
                }
                HStack {
                    Text("Size")
                    Slider(value: $fontSize, in: 9...36).frame(width: 120)
                    Stepper("", value: $fontSize, in: 9...36).labelsHidden()
                }
            }
            .background(EditGeometryDumpReader(id: "edit-formatbar"))
            .accessibilityIdentifier("edit-formatbar")
        } else {
            HStack(spacing: 8) {
                Button("B") {}.frame(width: 44)
                Button("I") {}.frame(width: 44)
                Button("U") {}.frame(width: 44)
                Text("Size")
                Slider(value: $fontSize, in: 9...36).frame(width: 120)
                Stepper("", value: $fontSize, in: 9...36).labelsHidden()
            }
            .frame(width: 300)
            .background(EditGeometryDumpReader(id: "edit-formatbar"))
            .accessibilityIdentifier("edit-formatbar")
        }
    }

    /// Declared compact inspector: full 300pt pane at comfortable widths,
    /// 200pt minimum pane at narrow widths (derived live from content
    /// width, same policy-driven pattern as pane collapse). The inspector
    /// is essential and never hidden; only its width adapts.
    private var inspectorWidth: CGFloat {
        guard let w = measuredContentWidth else { return 340 }
        return w >= 900 ? 340 : 200
    }

    var body: some View {
        HStack(spacing: 0) {
            if navVisible {
                VStack(alignment: .leading) {
                    Text("Documents").font(.headline)
                    Text("Draft").padding(.vertical, 4)
                    Text("Notes").padding(.vertical, 4)
                    Spacer()
                }
                .padding(12)
                .frame(width: 150)
                .accessibilityIdentifier("edit-nav")
            }
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(EditGeometryDumpReader(id: "edit-editor"))
                .accessibilityIdentifier("edit-editor")
            VStack(alignment: .leading, spacing: 10) {
                Text("Format").font(.headline)
                formatBar
                Spacer()
            }
            .padding(12)
            .frame(width: inspectorWidth)
            .background(EditGeometryDumpReader(id: "edit-inspector"))
            .accessibilityIdentifier("edit-inspector")
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .coordinateSpace(name: "edit-content")
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: EditorWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(EditorWidthKey.self) { next in
            if measuredContentWidth != next {
                measuredContentWidth = next
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(navVisible ? "Hide Documents" : "Show Documents") {
                    navVisible.toggle()
                }
            }
        }
        .onPreferenceChange(EditGeometryDumpKey.self) { dumpedGeometries = $0 }
        .onAppear {
            if EditLaunchConfig.isDumpGeometry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dumpGeometriesAndExit()
                }
            }
        }
    }
}

// MARK: - Window policy

enum EditWindowPolicy {
    static let contentDefaultSize = NSSize(width: 1000, height: 600)
    static let contentMinSize = NSSize(width: 560, height: 400)
}

// MARK: - App delegate

final class EditAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        var initialContentSize = EditWindowPolicy.contentDefaultSize
        if let w = EditLaunchConfig.customContentWidth {
            initialContentSize.width = max(w, EditWindowPolicy.contentMinSize.width)
        }
        let contentRect = NSRect(origin: .zero, size: initialContentSize)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Editor Fixture"
        window.isRestorable = false
        let hosting = NSHostingView(rootView: EditorContentView())
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = contentRect
        window.contentView = hosting
        window.setContentSize(initialContentSize)
        window.contentMinSize = EditWindowPolicy.contentMinSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: EditWindowPolicy.contentMinSize)).size
        if EditLaunchConfig.isLayoutDiagnostics {
            let contentSize = window.contentView?.frame.size ?? .zero
            print("edit-diagnostics contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) aligned=\(EditLaunchConfig.isAligned) navHidden=\(EditLaunchConfig.isNavHidden)")
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
        appMenu.addItem(withTitle: "About Editor Fixture", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Editor Fixture", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point

let editDelegate = EditAppDelegate()
let editApplication = NSApplication.shared
editApplication.delegate = editDelegate
editApplication.setActivationPolicy(.regular)
editApplication.run()
