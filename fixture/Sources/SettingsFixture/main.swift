import SwiftUI
import AppKit
import Darwin

// MARK: - Second family probe (settings form, not browser)
//
// This fixture exists to prove the skill transfers beyond the browser
// family: no sidebar, no inspector, no header envelope, no divider/body
// anchors. The shared contract here is label/control columns in a Grid.
// One seeded defect only (see SettingsLayout). Long-locale wrapping is an
// intentional variant, never a defect. Deterministic local state only.

// MARK: - Launch configuration (CLI flags)

enum SettingsLaunchConfig {
    /// `--aligned` removes ONLY the seeded extra inset (reference mode).
    /// It is not proof that a skill auto-repaired anything.
    static var isAligned: Bool {
        CommandLine.arguments.contains("--aligned")
    }

    /// `--long-locale` swaps in longer label copy. Wrapping and row-height
    /// growth are expected; columns must still hold.
    static var isLongLocale: Bool {
        CommandLine.arguments.contains("--long-locale")
    }

    /// `--layout-diagnostics` prints window sizes only (no private data).
    static var isLayoutDiagnostics: Bool {
        CommandLine.arguments.contains("--layout-diagnostics")
    }

    /// `--print-contract` prints DECLARED contract values and exits before
    /// launching any UI. Declared values only, never measured geometry.
    static var isPrintContract: Bool {
        CommandLine.arguments.contains("--print-contract")
    }

    /// `--dump-geometry` prints instrumented layout frames of tagged views
    /// in grid points, then exits before any interaction. Layout values
    /// only; background readers never affect layout. Settles 1.0s.
    static var isDumpGeometry: Bool {
        CommandLine.arguments.contains("--dump-geometry")
    }
}

// MARK: - Shared layout policy (single source of truth for the defect)

enum SettingsLayout {
    /// Shared label-column width used by every row.
    static let labelColumnWidth: CGFloat = 150
    /// Shared gap between the label and control columns.
    static let columnGap: CGFloat = 12
    /// Declared control-column leading in pane-local points.
    static var controlColumnLeading: CGFloat { labelColumnWidth + columnGap }

    /// SEEDED DEFECT (the one genuine defect in this fixture): the
    /// notifications row adds this extra leading on top of the shared
    /// control column (162 + 12 = 174pt). `--aligned` sets it to 0.
    static var notificationsExtraLeading: CGFloat {
        SettingsLaunchConfig.isAligned ? 0 : 12
    }

    static let contentPadding: CGFloat = 20
}

// MARK: - Row model

struct SettingsRow: Identifiable {
    enum Control { case theme, defaultView, notifications, cache }

    let id: String
    let label: String
    let longLabel: String
    let control: Control
    let accessibilityLabel: String
    let accessibilityControl: String

    var displayLabel: String {
        SettingsLaunchConfig.isLongLocale ? longLabel : label
    }
}

let settingsRows: [SettingsRow] = [
    SettingsRow(
        id: "theme",
        label: "Theme",
        longLabel: "Erscheinungsbild & Darstellung",
        control: .theme,
        accessibilityLabel: "settings-label-theme",
        accessibilityControl: "settings-control-theme"
    ),
    SettingsRow(
        id: "default-view",
        label: "Default view",
        longLabel: "Standardansicht für neue Fenster",
        control: .defaultView,
        accessibilityLabel: "settings-label-default-view",
        accessibilityControl: "settings-control-default-view"
    ),
    SettingsRow(
        id: "notifications",
        label: "Show notifications",
        longLabel: "Mitteilungen & Hinweise anzeigen",
        control: .notifications,
        accessibilityLabel: "settings-label-notifications",
        accessibilityControl: "settings-control-notifications"
    ),
    SettingsRow(
        id: "cache",
        label: "Cache size",
        longLabel: "Größe des Zwischenspeichers",
        control: .cache,
        accessibilityLabel: "settings-label-cache",
        accessibilityControl: "settings-control-cache"
    ),
]

// MARK: - Instrumented geometry dump (fixture test tooling, not skill support)
//
// Background readers report layout frames of tagged views into the
// settings-grid coordinate space. They never affect layout.
// `--dump-geometry` prints the collected frames and exits; normal runs
// only carry the plumbing.

/// Layout frame of one tagged view, in grid points.
struct SettingsGeometryDumpKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Layout-neutral frame reader. Placed INSIDE the seeded offset padding so
/// the visual control position (not the padded frame) is measured.
struct SettingsGeometryDumpReader: View {
    let id: String
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: SettingsGeometryDumpKey.self,
                value: [id: geo.frame(in: .named("settings-grid"))]
            )
        }
    }
}

// MARK: - Settings form (Grid columns, no envelope)

struct SettingsFormView: View {
    @State private var theme = "System"
    @State private var defaultView = "Tracks"
    @State private var showNotifications = true
    @State private var cacheSize = 50.0
    @State private var dumpedGeometries: [String: CGRect] = [:]

    /// Prints collected layout frames and exits (only under `--dump-geometry`).
    private func dumpGeometriesAndExit() {
        for id in dumpedGeometries.keys.sorted() {
            let r = dumpedGeometries[id]!
            print(String(format: "geometry %@ x=%.2f y=%.2f w=%.2f h=%.2f", id as NSString, r.origin.x, r.origin.y, r.size.width, r.size.height))
        }
        fflush(stdout)
        exit(0)
    }

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: SettingsLayout.columnGap, verticalSpacing: 12) {
            ForEach(settingsRows) { row in
                GridRow {
                    Text(row.displayLabel)
                        .frame(width: SettingsLayout.labelColumnWidth, alignment: .trailing)
                        .accessibilityIdentifier(row.accessibilityLabel)
                    control(for: row)
                        .accessibilityIdentifier(row.accessibilityControl)
                }
            }
            GridRow {
                Color.clear
                    .frame(width: SettingsLayout.labelColumnWidth, height: 1)
                    .accessibilityHidden(true)
                Text(helpText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SettingsGeometryDumpReader(id: "settings-help-default-view"))
                    .accessibilityIdentifier("settings-help-default-view")
            }
        }
        .coordinateSpace(name: "settings-grid")
        .padding(SettingsLayout.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onPreferenceChange(SettingsGeometryDumpKey.self) { dumpedGeometries = $0 }
        .onAppear {
            if SettingsLaunchConfig.isDumpGeometry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dumpGeometriesAndExit()
                }
            }
        }
    }

    private var helpText: String {
        SettingsLaunchConfig.isLongLocale
            ? "Gilt für alle neu geöffneten Fenster und Bereiche."
            : "Applies to new windows."
    }

    @ViewBuilder
    private func control(for row: SettingsRow) -> some View {
        switch row.control {
        case .theme:
            Picker("", selection: $theme) {
                Text("Light").tag("Light")
                Text("Dark").tag("Dark")
                Text("System").tag("System")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .background(SettingsGeometryDumpReader(id: row.accessibilityControl))
        case .defaultView:
            Picker("", selection: $defaultView) {
                Text("Tracks").tag("Tracks")
                Text("Albums").tag("Albums")
                Text("Playlists").tag("Playlists")
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .background(SettingsGeometryDumpReader(id: row.accessibilityControl))
        case .notifications:
            Toggle("", isOn: $showNotifications)
                .labelsHidden()
                .background(SettingsGeometryDumpReader(id: row.accessibilityControl))
                // Seeded defect lives here and only here: per-row offset
                // against the shared control column. The reader sits INSIDE
                // this padding so the visual position is measured.
                .padding(.leading, SettingsLayout.notificationsExtraLeading)
        case .cache:
            HStack {
                Slider(value: $cacheSize, in: 0...100)
                    .frame(width: 140)
                Text("\(Int(cacheSize)) MB")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .background(SettingsGeometryDumpReader(id: row.accessibilityControl))
        }
    }
}

// MARK: - Window policy (fixture-calibrated, deterministic)

enum SettingsWindowPolicy {
    static let contentDefaultSize = NSSize(width: 480, height: 360)
    static let contentMinSize = NSSize(width: 400, height: 300)
}

// MARK: - App delegate with predictable window startup

final class SettingsAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        let contentRect = NSRect(origin: .zero, size: SettingsWindowPolicy.contentDefaultSize)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings Fixture"
        window.isRestorable = false
        let hosting = NSHostingView(rootView: SettingsFormView())
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = contentRect
        window.contentView = hosting
        window.setContentSize(SettingsWindowPolicy.contentDefaultSize)
        window.contentMinSize = SettingsWindowPolicy.contentMinSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: SettingsWindowPolicy.contentMinSize)).size
        if SettingsLaunchConfig.isLayoutDiagnostics {
            let contentSize = window.contentView?.frame.size ?? .zero
            let frameSize = window.frame.size
            print("settings-diagnostics contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) frameSize=\(Int(frameSize.width))x\(Int(frameSize.height)) contentMinSize=\(Int(window.contentMinSize.width))x\(Int(window.contentMinSize.height)) minSize=\(Int(window.minSize.width))x\(Int(window.minSize.height)) controlColumnLeading=\(Int(SettingsLayout.controlColumnLeading)) defectExtra=\(Int(SettingsLayout.notificationsExtraLeading)) longLocale=\(SettingsLaunchConfig.isLongLocale)")
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
        appMenu.addItem(withTitle: "About Settings Fixture", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Settings Fixture", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point (SwiftPM executable)

// Declared-values print for headless smoke checks. These are the contract
// inputs, not measured geometry; runtime geometry still needs screenshots
// or manual pane-local measures mapped to evidence.
if SettingsLaunchConfig.isPrintContract {
    print("settings-contract family=settings variant=regular authority=app-decision (declared, not measured)")
    print("settings-contract controlColumnLeading=\(SettingsLayout.controlColumnLeading)pt pane-local tolerance=0.5")
    print("settings-contract seededDefect=settings-control-notifications +\(SettingsLayout.notificationsExtraLeading)pt aligned=0.0")
    print("settings-contract intentionalVariants=long-locale-wrapping,row-height-growth,help-text-length (must stay excluded)")
    exit(0)
}

let settingsDelegate = SettingsAppDelegate()
let settingsApplication = NSApplication.shared
settingsApplication.delegate = settingsDelegate
settingsApplication.setActivationPolicy(.regular)
settingsApplication.run()
