import SwiftUI
import AppKit

// MARK: - Page model

enum Page: String, CaseIterable, Identifiable, Hashable {
    case tracks
    case albums
    case playlists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tracks: return "Tracks"
        case .albums: return "Albums"
        case .playlists: return "Playlists"
        }
    }

    var symbol: String {
        switch self {
        case .tracks: return "music.note.list"
        case .albums: return "square.stack"
        case .playlists: return "list.bullet.rectangle"
        }
    }

    var subtitle: String {
        switch self {
        case .tracks: return "All songs in your library"
        case .albums: return "Browse albums by artist and year"
        case .playlists: return "Curated mixes and collections"
        }
    }
}

// MARK: - Launch configuration (CLI flags)

enum LaunchConfig {
    /// `--aligned` removes ONLY the deliberate extra inset (reference screenshots).
    /// It is not proof that a skill auto-repaired anything.
    static var isAligned: Bool {
        CommandLine.arguments.contains("--aligned")
    }

    /// `--compact` starts at the minimum content size (700x450) for verification.
    static var isCompact: Bool {
        CommandLine.arguments.contains("--compact")
    }

    /// `--page tracks|albums|playlists`, default tracks. Supports `--page X` and `--page=X`.
    static var initialPage: Page {
        let args = CommandLine.arguments
        var value: String?
        for (index, arg) in args.enumerated() {
            if arg == "--page", index + 1 < args.count {
                value = args[index + 1]
            } else if arg.hasPrefix("--page=") {
                value = String(arg.dropFirst("--page=".count))
            }
        }
        if let value, let page = Page(rawValue: value.lowercased()) {
            return page
        }
        return .tracks
    }
}

// MARK: - Shared layout policy (single source of truth for the defect)

enum ContentLayout {
    /// Shared app-owned content inset used by every page body and by Tracks/Albums titles.
    static let sharedLeading: CGFloat = 24
    static let sharedTop: CGFloat = 16

    /// SEEDED DEFECT (the one genuine main defect): Playlists title adds this extra
    /// leading on top of `sharedLeading` (24 + 8 = 32pt). `--aligned` sets it to 0
    /// so all three titles read 24pt for reference screenshots.
    static var playlistTitleExtraLeading: CGFloat {
        LaunchConfig.isAligned ? 0 : 8
    }
}

// MARK: - Deterministic in-memory data (no files, accounts, or network)

struct Track: Identifiable {
    var id: String { title + "|" + artist + "|" + duration }
    let title: String
    let artist: String
    let duration: String
}

struct Album: Identifiable {
    var id: String { title + "|" + artist + "|" + year }
    let title: String
    let artist: String
    let year: String
}

struct PlaylistItem: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
    let detail: String
}

let sampleTracks: [Track] = [
    Track(title: "Blue Line", artist: "Northbound", duration: "3:12"),
    Track(title: "Paper Lanterns", artist: "A. Okafor", duration: "4:05"),
    Track(title: "Half Light", artist: "Meridian", duration: "2:58"),
    Track(title: "Static Bloom", artist: "Glasswing", duration: "3:47"),
    Track(title: "Low Orbit", artist: "Cassini Drift", duration: "5:01"),
    Track(title: "Copper Sky", artist: "Northbound", duration: "3:33"),
    Track(title: "Night Parcel", artist: "Meridian", duration: "4:22"),
    Track(title: "Fern & Wire", artist: "A. Okafor", duration: "3:19"),
]

let sampleAlbums: [Album] = [
    Album(title: "Meridian", artist: "Meridian", year: "2021"),
    Album(title: "Paper Houses", artist: "A. Okafor", year: "2019"),
    Album(title: "Glasswing EP", artist: "Glasswing", year: "2022"),
    Album(title: "Northbound", artist: "Northbound", year: "2020"),
    Album(title: "Cassini Sessions", artist: "Cassini Drift", year: "2023"),
]

let samplePlaylists: [PlaylistItem] = [
    PlaylistItem(name: "Morning Commute", count: 18, detail: "Upbeat, short tracks"),
    PlaylistItem(name: "Deep Focus", count: 24, detail: "Instrumental and ambient"),
    PlaylistItem(name: "Weekend Cooking", count: 12, detail: "Warm soul and jazz"),
    PlaylistItem(name: "Rainy Day", count: 15, detail: "Slow acoustic"),
    PlaylistItem(name: "Gym Mix", count: 21, detail: "High tempo"),
    PlaylistItem(name: "Late Night Drive", count: 17, detail: "Synth and downtempo"),
]

// Intentional variant (NOT the defect): per-page description copy differs in length
// and wraps to multiple lines. Audits must not normalize copy length or wrapping.
let pageDescriptions: [Page: String] = [
    .tracks: "Every track in one list. Sort by title or artist.",
    .albums: "Five albums with artist and year. This description is a little longer so it can wrap onto a second line in the detail pane, which is expected and must not be treated as a misalignment.",
    .playlists: "Six playlists with deliberately varied detail strings. Some rows carry much longer trailing detail text than others so row heights and wrapping differ across the list. This uneven text length is an intended variant, not the seeded alignment defect.",
]

// MARK: - Shared header envelope (vertical stability across sibling pages)

// Width-dependent, content-derived envelope over sibling descriptions.
// All three page descriptions are measured live at the current offered width;
// the envelope height is the max, so shorter copy (Tracks, one line) reserves
// the same vertical space as longer copy (Albums/Playlists, two lines) at that
// width. No hardcoded height/line count, no truncation, no copy shortening,
// no per-page offsets, no cached max: inspector toggle, narrow width, and
// resize all re-resolve live with no stale height. Hidden siblings are
// accessibility-excluded and non-interactive; only the current page carries
// its description identifier. Title/subtitle/controls/divider/body share one
// code path for every page, so controls baseline, divider, and body start stay
// stable within this family. Table-vs-List internal differences preserved.
struct DescriptionEnvelope: View {
    let page: Page

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Page.allCases) { other in
                if other == page {
                    Text(pageDescriptions[other] ?? "")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("page-description-\(other.rawValue)")
                } else {
                    Text(pageDescriptions[other] ?? "")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Branch measurement (control-row fit only, prose excluded)

// Available content width (inside shared leading/trailing padding).
private struct AvailableContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat? { nil }
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() {
            value = next
        }
    }
}

// Intrinsic requirement of the regular control row only (same pieces/spacing).
private struct RegularControlsWidthKey: PreferenceKey {
    static var defaultValue: CGFloat? { nil }
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() {
            value = next
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedPage: Page

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Library")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            ForEach(Page.allCases) { page in
                Button {
                    selectedPage = page
                } label: {
                    Label(page.title, systemImage: page.symbol)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(
                            selectedPage == page
                                ? Color.accentColor.opacity(0.16)
                                : Color.clear
                        )
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("page-button-\(page.rawValue)")
            }
            Spacer()
            Text(LaunchConfig.isAligned ? "Mode: aligned" : "Mode: seeded")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .accessibilityIdentifier("sidebar-mode-label")
        }
        .padding(12)
    }
}

// MARK: - Detail pane

struct DetailPane: View {
    let page: Page
    @Binding var showInspector: Bool
    @Binding var showInfo: Bool
    // Shuffle/sort live in ContentView (passed as bindings) so page navigation,
    // resize, and branch switches never reset them.
    @Binding var shuffle: Bool
    @Binding var sortOrder: Int
    @State private var measuredAvailableWidth: CGFloat?
    @State private var measuredControlsWidth: CGFloat?

    /// Branch choice from control-row fit only; prose never participates.
    /// Unknown (first layout) defaults to the wide variant; narrow widths
    /// correct live once both measures resolve. No magic breakpoint.
    private var useRegularBranch: Bool {
        guard let available = measuredAvailableWidth,
              let required = measuredControlsWidth else {
            return true
        }
        return available >= required
    }

    /// App-owned content title leading. Tracks/Albums use the shared 24pt inset.
    /// Playlists adds the seeded +8pt extra (32pt total) unless `--aligned`.
    var titleLeading: CGFloat {
        switch page {
        case .playlists:
            return ContentLayout.sharedLeading + ContentLayout.playlistTitleExtraLeading
        case .tracks, .albums:
            return ContentLayout.sharedLeading
        }
    }

    // MARK: - Shared control pieces (single source, reused in both variants)

    private var shuffleRegular: some View {
        Toggle("Shuffle", isOn: $shuffle)
            .toggleStyle(.switch)
            .accessibilityIdentifier("control-shuffle-\(page.rawValue)")
    }

    private var shuffleCompactControl: some View {
        Toggle("Shuffle", isOn: $shuffle)
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel("Shuffle")
            .accessibilityIdentifier("control-shuffle-\(page.rawValue)")
    }

    private var sortSegmented: some View {
        Picker("Sort", selection: $sortOrder) {
            Text("Title").tag(0)
            Text("Artist").tag(1)
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
        .accessibilityIdentifier("control-sort-\(page.rawValue)")
    }

    private var sortMenuCompact: some View {
        Picker("Sort", selection: $sortOrder) {
            Text("Title").tag(0)
            Text("Artist").tag(1)
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .accessibilityLabel("Sort")
        .accessibilityIdentifier("control-sort-\(page.rawValue)")
    }

    private var inspectorButton: some View {
        Button(showInspector ? "Hide Inspector" : "Show Inspector") {
            showInspector.toggle()
        }
        .accessibilityIdentifier("button-toggle-inspector")
    }

    private var infoButton: some View {
        Button("Info") {
            showInfo = true
        }
        .accessibilityIdentifier("button-show-info")
    }

    var body: some View {
        // Viewport policy: the detail page scrolls vertically as one unit so
        // header, description, controls, and list all stay reachable at the
        // 700x450 minimum (with or without the inspector). The inner
        // Table/List keeps an explicitly bounded 220pt viewport and scrolls
        // internally; it never forces the outer page taller than the host.
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 12) {
                // Content header: app-owned title inside the detail pane.
                // This is the measured keyline, NOT the native window titlebar.
                Text(page.title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.leading, titleLeading)
                    .padding(.top, ContentLayout.sharedTop)
                    .accessibilityIdentifier("page-title-\(page.rawValue)")
                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, ContentLayout.sharedLeading)
                    .padding(.trailing, ContentLayout.sharedLeading)
                    .accessibilityIdentifier("page-subtitle-\(page.rawValue)")

                // Title/description policy (explicit, variant-scoped):
                // Regular variant: description envelope above controls keeps
                // controls/divider/body stable across siblings at same width.
                // Compact variant (fit-driven fallback below): controls sit
                // directly below subtitle so controls top stays stable with no
                // huge reserved blank; long description moves to the shared
                // below-controls DisclosureGroup ("About this view"). Collapsed
                // height is stable across siblings; expanded shows full text
                // with wrapping (no truncation, no blanket-hide). No hardcoded
                // heights, no per-page offsets, no global height forcing.
                // Branch choice is control-row fit only: measured available
                // content width vs measured regular-row intrinsic requirement.
                // Description prose never participates in the switch (it
                // previously inflated ViewThatFits ideal width and pinned
                // 1000x650 to compact). No magic screen breakpoint; inspector
                // show/hide and resize re-resolve live with no stale branch.
                Group {
                    if useRegularBranch {
                        // Regular: coherent wide row with native readable sizes.
                        VStack(alignment: .leading, spacing: 12) {
                            DescriptionEnvelope(page: page)
                            HStack(spacing: 12) {
                                shuffleRegular
                                sortSegmented
                                Spacer()
                                inspectorButton
                                infoButton
                            }
                        }
                    } else {
                        // Compact (intentional composition, not accidental stack):
                        // aligned label/control columns via Grid (no arbitrary
                        // offsets), native menu picker for Sort (no indent, no
                        // shrink), secondary actions in labeled More menu.
                        // Every action and selection stays reachable with the same
                        // identifiers and focus.
                        VStack(alignment: .leading, spacing: 12) {
                            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                                GridRow {
                                    Text("Shuffle")
                                        .font(.body)
                                        .gridColumnAlignment(.trailing)
                                        .accessibilityHidden(true)
                                    shuffleCompactControl
                                }
                                GridRow {
                                    Text("Sort")
                                        .font(.body)
                                        .gridColumnAlignment(.trailing)
                                        .accessibilityHidden(true)
                                    sortMenuCompact
                                }
                            }
                            Menu("More") {
                                inspectorButton
                                infoButton
                            }
                            .accessibilityIdentifier("menu-more-\(page.rawValue)")
                            .accessibilityLabel("More actions")
                            DisclosureGroup {
                                Text(pageDescriptions[page] ?? "")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("page-description-\(page.rawValue)")
                            } label: {
                                Text("About this view")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityIdentifier("disclosure-about-\(page.rawValue)")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: AvailableContentWidthKey.self,
                            value: proxy.size.width
                        )
                    }
                )
                .overlay(alignment: .topLeading) {
                    // Inert sizing probe: native counterparts with constant
                    // bindings and no-op actions (no shared helpers, no live
                    // bindings, no identifiers, no state mutation). Same
                    // labels/styles/spacing/widths, including the current
                    // Show/Hide Inspector label, so intrinsic width matches.
                    HStack(spacing: 12) {
                        Toggle("Shuffle", isOn: .constant(false))
                            .toggleStyle(.switch)
                        Picker("Sort", selection: .constant(0)) {
                            Text("Title").tag(0)
                            Text("Artist").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        Spacer()
                        Button(showInspector ? "Hide Inspector" : "Show Inspector") {}
                        Button("Info") {}
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .disabled(true)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .background(
                        GeometryReader { probe in
                            Color.clear.preference(
                                key: RegularControlsWidthKey.self,
                                value: probe.size.width
                            )
                        }
                    )
                }
                .onPreferenceChange(AvailableContentWidthKey.self) { next in
                    if measuredAvailableWidth != next {
                        measuredAvailableWidth = next
                    }
                }
                .onPreferenceChange(RegularControlsWidthKey.self) { next in
                    if measuredControlsWidth != next {
                        measuredControlsWidth = next
                    }
                }
                .padding(.leading, ContentLayout.sharedLeading)
                .padding(.trailing, ContentLayout.sharedLeading)

                Divider()

                pageBody
                    .padding(.leading, ContentLayout.sharedLeading)
                    .padding(.trailing, ContentLayout.sharedLeading)
                    .accessibilityIdentifier("page-body-\(page.rawValue)")
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, 16)
        }
        .id(page) // Each page begins at the same top-of-content position.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showInfo) {
            InfoSheetView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Info") { showInfo = true }
                    .accessibilityIdentifier("toolbar-button-info")
            }
        }
    }

    @ViewBuilder
    private var pageBody: some View {
        // Bounded internal viewport: each list/table is exactly 220pt tall and
        // scrolls internally. Combined with the outer page ScrollView this keeps
        // the root HStack within host bounds at 700x450 (no minHeight forcing
        // outer overflow).
        switch page {
        case .tracks:
            Table(sampleTracks) {
                TableColumn("Title", value: \.title)
                TableColumn("Artist", value: \.artist)
                TableColumn("Length", value: \.duration)
            }
            .frame(height: 220)
        case .albums:
            List(sampleAlbums) { album in
                HStack {
                    Image(systemName: "square.stack")
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading) {
                        Text(album.title)
                        Text("\(album.artist) · \(album.year)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .listStyle(.inset)
            .frame(height: 220)
        case .playlists:
            List(samplePlaylists) { item in
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                        Text("\(item.count) songs · \(item.detail)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(item.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.inset)
            .frame(height: 220)
        }
    }
}

// MARK: - Inspector (intentional variant, different family — excluded from title keyline)

/// Compact inspector uses tighter spacing and smaller type on purpose.
/// It is a different surface family from the browser content titles and must be
/// excluded from any content-title leading contract, not "fixed" into alignment.
struct InspectorView: View {
    @State private var volume = 0.5

    var body: some View {
        // Vertical safe scroll: inspector content is small but must stay
        // reachable at 450pt height when the detail page also scrolls.
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Inspector")
                    .font(.headline)
                    .accessibilityIdentifier("inspector-title")
                Text("Compact variant: tighter spacing is intentional.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                Text("Volume")
                    .font(.caption)
                Slider(value: $volume, in: 0...1)
                    .accessibilityIdentifier("inspector-volume")
                    .frame(width: 150)
                Text("Applies to preview only.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(10)
        .frame(width: 180)
        .frame(maxHeight: .infinity)
        .accessibilityIdentifier("inspector-pane")
    }
}

// MARK: - Info sheet

struct InfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency Fixture")
                .font(.title2)
                .bold()
                .accessibilityIdentifier("info-title")
            Text("A small native fixture for testing macOS UI consistency audits. Seeded mode shows one deliberate title-inset defect on Playlists; aligned mode removes it for reference screenshots.")
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text(LaunchConfig.isAligned ? "Running in aligned mode." : "Running in seeded mode.")
                .font(.callout)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("info-mode-label")
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("button-close-info")
            }
        }
        .padding(24)
        .frame(width: 420)
        .accessibilityIdentifier("info-sheet")
    }
}

// MARK: - Root content

struct ContentView: View {
    @State private var selectedPage: Page
    @State private var showInspector = false
    @State private var showInfo = false
    // Shared filter state: owned here so page changes, resizes, and
    // compact/regular branch switches never reset shuffle/sort.
    @State private var shuffle = false
    @State private var sortOrder = 0

    init(initialPage: Page) {
        _selectedPage = State(initialValue: initialPage)
    }

    var body: some View {
        // Outer HStack stays within host bounds: fixed compact sidebar width
        // leaves room for detail + inspector at 700pt, and the detail page
        // scrolls instead of forcing the row taller than the window.
        HStack(spacing: 0) {
            SidebarView(selectedPage: $selectedPage)
                .frame(minWidth: 150, idealWidth: 170, maxWidth: 180, minHeight: 0, maxHeight: .infinity)
            Divider()
            DetailPane(page: selectedPage, showInspector: $showInspector, showInfo: $showInfo, shuffle: $shuffle, sortOrder: $sortOrder)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            if showInspector {
                Divider()
                InspectorView()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}

// MARK: - App delegate with predictable window startup

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        let initialSize = LaunchConfig.isCompact
            ? NSSize(width: 700, height: 450)
            : NSSize(width: 1000, height: 650)
        let contentRect = NSRect(origin: .zero, size: initialSize)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Consistency Fixture"
        window.minSize = NSSize(width: 700, height: 450)
        window.isRestorable = false
        let hosting = NSHostingView(rootView: ContentView(initialPage: LaunchConfig.initialPage))
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = NSRect(origin: .zero, size: initialSize)
        window.contentView = hosting
        window.setContentSize(initialSize)
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
        appMenu.addItem(withTitle: "About Consistency Fixture", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Consistency Fixture", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point (SwiftPM executable)

let delegate = AppDelegate()
let application = NSApplication.shared
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
