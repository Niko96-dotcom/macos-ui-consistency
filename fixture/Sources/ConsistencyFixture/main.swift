import SwiftUI
import AppKit
import Combine

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

    /// `--compact` starts at the policy minimum content size for verification.
    static var isCompact: Bool {
        CommandLine.arguments.contains("--compact")
    }

    /// `--layout-diagnostics` prints window content/frame/min sizing (no private data).
    static var isLayoutDiagnostics: Bool {
        CommandLine.arguments.contains("--layout-diagnostics")
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

// MARK: - Window/view size policy (fixture-calibrated, deterministic)

// Fixture width budget (content coordinates, not frame):
// Sidebar 150 (min) + 1 divider; detail compact minimum 320
// (24+24 padding + ~150 control column with native unshrunk Toggle/Menu +
// ~70 label column + Table usability margin; narrower would clip
// header/actions); inspector 180 + 1 divider (deferrable, never raises min).
// Budget: sidebar + detail-min = 471; + inspector = 652.
// Thresholds: inspector defers below 860 to keep a comfortable regular row;
// sidebar collapses below 700 to preserve content first; hard stop 560 sits
// below the collapse point so the collapsed state is seen before the minimum.
// Height 450 fits header + controls + 220 list with outer scroll.
// Visibility is derived live from total width (no stored copy, no resize
// calls), so widening restores per user preference with no jitter loop.
enum WindowPolicy {
    static let contentMinWidth: CGFloat = 560
    static let contentMinHeight: CGFloat = 450
    static let contentDefaultWidth: CGFloat = 1000
    static let contentDefaultHeight: CGFloat = 650
    static var contentMinSize: NSSize {
        NSSize(width: contentMinWidth, height: contentMinHeight)
    }
    static var contentDefaultSize: NSSize {
        NSSize(width: contentDefaultWidth, height: contentDefaultHeight)
    }
    static let sidebarMinWidth: CGFloat = 150
    static let sidebarIdealWidth: CGFloat = 170
    static let sidebarMaxWidth: CGFloat = 180
    static let inspectorWidth: CGFloat = 180
    static let detailCompactMin: CGFloat = 320
    static let sidebarCollapseThreshold: CGFloat = 700
    static let inspectorDeferThreshold: CGFloat = 860
}

// User sidebar preference, separate from policy-constrained visibility.
// Retained when the policy collapses the sidebar narrow; widening restores
// per this value. Shared by toolbar, View menu, and shortcut via one
// effective-visibility toggle (no duplicate policy).
final class SidebarPreference: ObservableObject {
    static let shared = SidebarPreference()
    @Published var userShowsSidebar = true

    /// Effective visibility from user intent plus total content width.
    /// Nil width (first layout, non-compact) respects intent; `--compact`
    /// startup initializes width to the 560pt policy minimum so first paint
    /// already reflects collapse instead of squeezing after layout.
    static func isEffectivelyVisible(userShows: Bool, contentWidth: CGFloat?) -> Bool {
        guard userShows else { return false }
        guard let w = contentWidth else { return true }
        return w >= WindowPolicy.sidebarCollapseThreshold
    }

    /// Unified toggle based on EFFECTIVE visibility: if effectively visible
    /// hide intent; if hidden (by intent or narrow policy) show intent and
    /// widen the window to the collapse threshold when narrow. Callers pass
    /// measured width (SwiftUI) or actual window content width (AppKit);
    /// widening always re-checks the live window before resizing.
    func toggleEffective(contentWidth: CGFloat?) {
        let effective = Self.isEffectivelyVisible(userShows: userShowsSidebar, contentWidth: contentWidth)
        if effective {
            userShowsSidebar = false
        } else {
            userShowsSidebar = true
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }
            let measuredNarrow = contentWidth.map { $0 < WindowPolicy.sidebarCollapseThreshold } ?? true
            if measuredNarrow {
                let current = window.contentRect(forFrameRect: window.frame).size.width
                if current < WindowPolicy.sidebarCollapseThreshold {
                    var frame = window.frame
                    frame.size.width += (WindowPolicy.sidebarCollapseThreshold - current)
                    window.setFrame(frame, display: true)
                }
            }
        }
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

// Total content width (window content, for sidebar/inspector policy only).
private struct ContentWidthKey: PreferenceKey {
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
        // policy minimum (with or without deferred inspector). The inner
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
                        // shrink), secondary actions in labeled More menu placed
                        // in the Grid with an empty label cell so Sort and More
                        // control leading edges align with the Shuffle control
                        // column. Native internal title/glyph padding may differ;
                        // do not add offsets to compensate. Every action stays
                        // reachable with the same identifiers and focus.
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
                                GridRow {
                                    Text("")
                                        .font(.body)
                                        .gridColumnAlignment(.trailing)
                                        .accessibilityHidden(true)
                                    Menu("More") {
                                        inspectorButton
                                        infoButton
                                    }
                                    .accessibilityIdentifier("menu-more-\(page.rawValue)")
                                    .accessibilityLabel("More actions")
                                }
                            }
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
        // the root HStack within host bounds at the policy minimum (no minHeight
        // forcing outer overflow). Narrow Tables scroll natively horizontally;
        // header/actions stay usable.
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
    @Binding var volume: Double

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
        .frame(width: WindowPolicy.inspectorWidth)
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
    // Lifted inspector state: single source preserved across pane/sheet
    // transitions so narrow deferred sheet and wide pane share Volume.
    @State private var inspectorVolume = 0.5
    @ObservedObject private var sidebarPref = SidebarPreference.shared
    @State private var measuredContentWidth: CGFloat? = LaunchConfig.isCompact ? WindowPolicy.contentMinWidth : nil

    init(initialPage: Page) {
        _selectedPage = State(initialValue: initialPage)
    }

    // Derived-only policy (no stored visibility, no window resize calls):
    // total-width measurement never feeds back into window size, so no loop.
    // Nil (first layout, non-compact) respects the user request; `--compact`
    // initializes to the 560pt policy minimum so first paint already reflects
    // collapse; narrow widths correct live.
    private var isSidebarVisible: Bool {
        SidebarPreference.isEffectivelyVisible(userShows: sidebarPref.userShowsSidebar, contentWidth: measuredContentWidth)
    }

    private var isSidebarCollapsedByPolicy: Bool {
        sidebarPref.userShowsSidebar && !isSidebarVisible
    }

    private var isInspectorVisible: Bool {
        guard showInspector else { return false }
        guard let w = measuredContentWidth else { return true }
        return w >= WindowPolicy.inspectorDeferThreshold
    }

    /// Requested but deferred narrow: same inspector appears in a native
    /// sheet (no silently disappearing toggle). Volume is shared via
    /// `inspectorVolume` so pane/sheet transitions preserve it.
    private var isInspectorDeferred: Bool {
        showInspector && !isInspectorVisible
    }

    var body: some View {
        // Outer HStack stays within host bounds. Sidebar/inspector are optional:
        // inspector defers first, then sidebar collapses, preserving usable
        // detail (detailCompactMin) before the contentMin hard stop.
        // Narrow Tables scroll natively inside their 220pt viewport;
        // header/actions stay reachable via the outer vertical scroll.
        HStack(spacing: 0) {
            if isSidebarVisible {
                SidebarView(selectedPage: $selectedPage)
                    .frame(minWidth: WindowPolicy.sidebarMinWidth, idealWidth: WindowPolicy.sidebarIdealWidth, maxWidth: WindowPolicy.sidebarMaxWidth, minHeight: 0, maxHeight: .infinity)
                Divider()
            }
            DetailPane(page: selectedPage, showInspector: $showInspector, showInfo: $showInfo, shuffle: $shuffle, sortOrder: $sortOrder)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            if isInspectorVisible {
                Divider()
                InspectorView(volume: $inspectorVolume)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(ContentWidthKey.self) { next in
            if measuredContentWidth != next {
                measuredContentWidth = next
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar") {
                    // Unified effective-visibility toggle (shared with View
                    // menu/shortcut): hidden by intent or narrow policy shows
                    // intent and widens once to reveal; visible hides intent.
                    sidebarPref.toggleEffective(contentWidth: measuredContentWidth)
                }
                .help(isSidebarCollapsedByPolicy ? "Sidebar is hidden below 700pt width. Activating widens the window to show it." : "")
                .accessibilityIdentifier("button-toggle-sidebar")
                .accessibilityLabel(isSidebarCollapsedByPolicy ? "Show sidebar by widening window" : (isSidebarVisible ? "Hide sidebar" : "Show sidebar"))
            }
            if !isSidebarVisible {
                ToolbarItem(placement: .automatic) {
                    Picker("Navigate", selection: $selectedPage) {
                        ForEach(Page.allCases) { page in
                            Text(page.title).tag(page)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("nav-page-picker")
                    .accessibilityLabel("Navigate")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { isInspectorDeferred },
            set: { newValue in if !newValue { showInspector = false } }
        )) {
            VStack(alignment: .leading) {
                InspectorView(volume: $inspectorVolume)
                HStack {
                    Spacer()
                    Button("Close") { showInspector = false }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("button-close-inspector-sheet")
                }
            }
            .padding(12)
            .accessibilityIdentifier("inspector-sheet")
        }
    }
}

// MARK: - App delegate with predictable window startup

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!

    /// Policy frame minimum for the current window chrome (titlebar/toolbar).
    private func policyFrameMin(for sender: NSWindow) -> NSSize {
        sender.frameRect(forContentRect: NSRect(origin: .zero, size: WindowPolicy.contentMinSize)).size
    }

    /// Interactive resize enforcement: clamp proposed FRAME so content never
    /// goes below 560x450. Uses max(policy-derived, currently reported) so a
    /// host/toolbar inflate is still respected, while a shrink below policy
    /// cannot bypass it. Returns clamped size only (no setFrame, no loop).
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let policyMin = policyFrameMin(for: sender)
        var robustMin = policyMin
        robustMin.width = max(robustMin.width, sender.minSize.width)
        robustMin.height = max(robustMin.height, sender.minSize.height)
        if sender.contentMinSize.width > 0 && sender.contentMinSize.height > 0 {
            let reportedFrameMin = sender.frameRect(forContentRect: NSRect(origin: .zero, size: sender.contentMinSize)).size
            robustMin.width = max(robustMin.width, reportedFrameMin.width)
            robustMin.height = max(robustMin.height, reportedFrameMin.height)
        }
        var clamped = frameSize
        clamped.width = max(clamped.width, robustMin.width)
        clamped.height = max(clamped.height, robustMin.height)
        if LaunchConfig.isLayoutDiagnostics {
            let curFrame = sender.frame.size
            let curContent = sender.contentRect(forFrameRect: sender.frame).size
            print("layout-resize proposed=\(Int(frameSize.width))x\(Int(frameSize.height)) clamped=\(Int(clamped.width))x\(Int(clamped.height)) frame=\(Int(curFrame.width))x\(Int(curFrame.height)) content=\(Int(curContent.width))x\(Int(curContent.height)) minSize=\(Int(sender.minSize.width))x\(Int(sender.minSize.height)) contentMinSize=\(Int(sender.contentMinSize.width))x\(Int(sender.contentMinSize.height)) policyContentMin=\(Int(WindowPolicy.contentMinWidth))x\(Int(WindowPolicy.contentMinHeight)) policyFrameMin=\(Int(policyMin.width))x\(Int(policyMin.height)) robustMin=\(Int(robustMin.width))x\(Int(robustMin.height))")
        }
        return clamped
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeMainMenu()
        let initialContentSize = LaunchConfig.isCompact
            ? WindowPolicy.contentMinSize
            : WindowPolicy.contentDefaultSize
        let contentRect = NSRect(origin: .zero, size: initialContentSize)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Consistency Fixture"
        window.isRestorable = false
        let hosting = NSHostingView(rootView: ContentView(initialPage: LaunchConfig.initialPage))
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = NSRect(origin: .zero, size: initialContentSize)
        window.contentView = hosting
        window.setContentSize(initialContentSize)
        // Enforced usable minimum AFTER host installation (content semantics).
        // contentMinSize measures content and takes precedence over minSize,
        // which measures the frame including titlebar. Setting minSize before
        // contentView can be overridden by the host, allowing a tiny drag with
        // clipped title/controls/sidebar. Derive the frame minimum from the
        // content minimum so both agree. No resize loop.
        window.contentMinSize = WindowPolicy.contentMinSize
        let frameMinSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: WindowPolicy.contentMinSize)).size
        window.minSize = frameMinSize
        window.delegate = self
        if LaunchConfig.isLayoutDiagnostics {
            let contentSize = window.contentView?.frame.size ?? .zero
            let frameSize = window.frame.size
            // Sizes and policy numbers only, for coordinator checks.
            print("layout-diagnostics contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) frameSize=\(Int(frameSize.width))x\(Int(frameSize.height)) contentMinSize=\(Int(window.contentMinSize.width))x\(Int(window.contentMinSize.height)) minSize=\(Int(window.minSize.width))x\(Int(window.minSize.height)) policyContentMin=\(Int(WindowPolicy.contentMinWidth))x\(Int(WindowPolicy.contentMinHeight)) policyFrameMin=\(Int(frameMinSize.width))x\(Int(frameMinSize.height)) sidebarThreshold=\(Int(WindowPolicy.sidebarCollapseThreshold)) inspectorThreshold=\(Int(WindowPolicy.inspectorDeferThreshold))")
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        // Inspect post-makeKey host/toolbar overwrite once (no loop): hosting
        // layout can reset minSize/contentMinSize after makeKey. Re-assert if
        // smaller than policy and report both for triage. Observed tiny-drag
        // failure is enforced via windowWillResize above; overwrite ordering
        // alone is not claimed as proven root cause.
        DispatchQueue.main.async { [weak self] in
            guard let self, let w = self.window else { return }
            let policyMin = self.policyFrameMin(for: w)
            var didFix = false
            if w.contentMinSize.width < WindowPolicy.contentMinWidth - 0.5 || w.contentMinSize.height < WindowPolicy.contentMinHeight - 0.5 {
                w.contentMinSize = WindowPolicy.contentMinSize
                didFix = true
            }
            if w.minSize.width < policyMin.width - 0.5 || w.minSize.height < policyMin.height - 0.5 {
                w.minSize = policyMin
                didFix = true
            }
            if LaunchConfig.isLayoutDiagnostics {
                let contentSize = w.contentView?.frame.size ?? .zero
                let frameSize = w.frame.size
                print("layout-diagnostics post-makeKey contentSize=\(Int(contentSize.width))x\(Int(contentSize.height)) frameSize=\(Int(frameSize.width))x\(Int(frameSize.height)) contentMinSize=\(Int(w.contentMinSize.width))x\(Int(w.contentMinSize.height)) minSize=\(Int(w.minSize.width))x\(Int(w.minSize.height)) policyFrameMin=\(Int(policyMin.width))x\(Int(policyMin.height)) didFix=\(didFix)")
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @objc private func toggleSidebarFromMenu(_ sender: Any?) {
        // Unified effective-visibility toggle shared with the toolbar:
        // uses the live window content width so an auto-collapsed sidebar
        // (request true, width narrow) reveals instead of hiding.
        let window = NSApp.keyWindow ?? NSApp.windows.first ?? self.window
        let actualWidth: CGFloat? = window.map { $0.contentRect(forFrameRect: $0.frame).size.width }
        SidebarPreference.shared.toggleEffective(contentWidth: actualWidth)
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
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        let toggleItem = viewMenu.addItem(withTitle: "Toggle Sidebar", action: #selector(toggleSidebarFromMenu(_:)), keyEquivalent: "s")
        toggleItem.keyEquivalentModifierMask = [.command, .control]
        toggleItem.target = self
        NSApp.mainMenu = mainMenu
    }
}

// MARK: - Entry point (SwiftPM executable)

let delegate = AppDelegate()
let application = NSApplication.shared
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
