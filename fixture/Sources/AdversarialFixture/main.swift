import SwiftUI
import AppKit
import Darwin

// MARK: - Adversarial majority-wrong probe (transfer case 5)
//
// Four sibling form screens share one declared label-column contract
// (150pt). Three of them (alpha/beta/gamma) carry the same copied +12pt
// offset; only delta follows the contract. An audit must fail the
// majority against the contract, never re-baseline to it. Pages selected
// via --page (no sidebar needed). Deterministic local state only.

// MARK: - Launch configuration (CLI flags)

enum AdvLaunchConfig {
    /// `--page alpha|beta|gamma|delta`, default alpha.
    static var initialPage: AdvPage {
        let args = CommandLine.arguments
        var value: String?
        for (index, arg) in args.enumerated() {
            if arg == "--page", index + 1 < args.count {
                value = args[index + 1]
            } else if arg.hasPrefix("--page=") {
                value = String(arg.dropFirst("--page=".count))
            }
        }
        if let value, let page = AdvPage(rawValue: value.lowercased()) {
            return page
        }
        return .alpha
    }

    /// `--layout-diagnostics` prints window sizes only (no private data).
    static var isLayoutDiagnostics: Bool {
        CommandLine.arguments.contains("--layout-diagnostics")
    }

    /// `--dump-geometry` prints instrumented layout frames in grid points,
    /// then exits. Background readers never affect layout. Settles 1.0s.
    static var isDumpGeometry: Bool {
        CommandLine.arguments.contains("--dump-geometry")
    }
}

// MARK: - Page model

enum AdvPage: String, CaseIterable, Identifiable, Hashable {
    case alpha
    case beta
    case gamma
    case delta

    var id: String { rawValue }

    /// Pages alpha/beta/gamma share one copied offset (the majority is
    /// wrong); delta follows the declared contract (the minority is right).
    var labelExtraLeading: CGFloat {
        switch self {
        case .alpha, .beta, .gamma: return 12
        case .delta: return 0
        }
    }
}

// MARK: - Shared layout policy (the declared contract)

enum AdvLayout {
    static let labelColumnWidth: CGFloat = 150
    static let columnGap: CGFloat = 12
    static var controlColumnLeading: CGFloat { labelColumnWidth + columnGap }
    static let contentPadding: CGFloat = 20
}

// MARK: - Instrumented geometry dump (fixture test tooling)

struct AdvGeometryDumpKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct AdvGeometryDumpReader: View {
    let id: String
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: AdvGeometryDumpKey.self,
                value: [id: geo.frame(in: .named("adv-grid"))]
            )
        }
    }
}

// MARK: - Form (one page at a time)

struct AdvFormView: View {
    let page: AdvPage
    @State private var value = ""
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
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: AdvLayout.columnGap, verticalSpacing: 12) {
            GridRow {
                Text("Display name")
                    .frame(width: AdvLayout.labelColumnWidth + page.labelExtraLeading, alignment: .trailing)
                    .accessibilityIdentifier("adv-label-\(page.rawValue)")
                TextField("Name", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .background(AdvGeometryDumpReader(id: "adv-control-\(page.rawValue)"))
                    .accessibilityIdentifier("adv-control-\(page.rawValue)")
            }
            GridRow {
                Text("Role")
                    .frame(width: AdvLayout.labelColumnWidth + page.labelExtraLeading, alignment: .trailing)
                    .accessibilityIdentifier("adv-label2-\(page.rawValue)")
                TextField("Role", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .accessibilityIdentifier("adv-control2-\(page.rawValue)")
            }
        }
        .coordinateSpace(name: "adv-grid")
        .padding(AdvLayout.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onPreferenceChange(AdvGeometryDumpKey.self) { dumpedGeometries = $0 }
        .onAppear {
            if AdvLaunchConfig.isDumpGeometry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dumpGeometriesAndExit()
                }
            }
        }
    }
}

// MARK: - Window policy

enum AdvWindowPolicy {
    static let contentDefaultSize = NSSize(width: 520, height: 300)
    static let contentMinSize = NSSize(width: 420, height: 240)
}

// MARK: - App delegate

final class AdvAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        let contentRect = NSRect(origin: .zero, size: AdvWindowPolicy.contentDefaultSize)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Adversarial Fixture"
        window.isRestorable = false
        let hosting = NSHostingView(rootView: AdvFormView(page: AdvLaunchConfig.initialPage))
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = contentRect
        window.contentView = hosting
        window.setContentSize(AdvWindowPolicy.contentDefaultSize)
        window.contentMinSize = AdvWindowPolicy.contentMinSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: AdvWindowPolicy.contentMinSize)).size
        if AdvLaunchConfig.isLayoutDiagnostics {
            let contentSize = window.contentView?.frame.size ?? .zero
            print("adv-diagnostics contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) page=\(AdvLaunchConfig.initialPage.rawValue) extra=\(AdvLaunchConfig.initialPage.labelExtraLeading)")
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
        appMenu.addItem(withTitle: "About Adversarial Fixture", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Adversarial Fixture", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point

let advDelegate = AdvAppDelegate()
let advApplication = NSApplication.shared
advApplication.delegate = advDelegate
advApplication.setActivationPolicy(.regular)
advApplication.run()
