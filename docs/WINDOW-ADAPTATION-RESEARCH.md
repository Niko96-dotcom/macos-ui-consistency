# Window-Adaptation Research (2026-09-16 snapshots)

Paraphrase-only synthesis. No Apple full text redistributed.

## Sources newly fetched and fully read (2026-09-16)

- [HIG Windows](https://developer.apple.com/design/human-interface-guidelines/windows)
  — Best practices ("adapt fluidly") + macOS anatomy/states;
  alert 2025-06-09; HIG guidance; **strong recommendation**.
- [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
  — Adaptability + Visual hierarchy + macOS ("avoid bottom controls");
  alert 2026-09-09; HIG guidance; **strong / strong**.
- [HIG Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
  — Best practices + macOS ("Consider automatically hiding/revealing");
  alert 2026-06-08; HIG guidance; **weak optional** — no auto mandate.
- [HIG Split views](https://developer.apple.com/design/human-interface-guidelines/split-views)
  — macOS ("reasonable min/max pane sizes", "consider hide", "multiple
  ways to reveal", "thin divider"); alert 2025-06-09; HIG;
  **moderate + weak**.
- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
  — Best practices ("let people resize/hide/show/move", keyboard,
  personalization); snapshot 2026-09-16, no alert stamp; HIG;
  **strong direction, app-calibrated**.
- [NSWindow minSize](https://developer.apple.com/documentation/appkit/nswindow/minsize)
  + [contentMinSize](https://developer.apple.com/documentation/appkit/nswindow/contentminsize)
  — Discussion (frame vs content-view base coords,
  precedence, enforcement excl. `setFrame(_:display:)` variants);
  AppKit API; **normative behavior**.
- [HIG Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
  — Best practices + macOS push/square/help/image; alert 2025-12-16;
  HIG; **idiom guidance**.
- [HIG Pop-up buttons](https://developer.apple.com/design/human-interface-guidelines/pop-up-buttons)
  — "space-efficient", "useful default", predictive label;
  artwork 2023-10-24; HIG; **weak-moderate**.
- [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
  — macOS 13pt default / 10pt floor, SF Pro, no Dynamic Type on macOS;
  alert 2025-12-16; HIG; **platform metric**.

## Existing skill links (not re-fetched this task)

- [WWDC19 session 237](https://developer.apple.com/videos/play/wwdc2019/237/)
  + [NSView alignmentRectInsets](https://developer.apple.com/documentation/appkit/nsview/alignmentrectinsets?language=objc)
  + [`XCUIElementAttributes.frame`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes)
  — alignment-rect vs frame; screen-space presence only.
  Platform authority; **normative for measurement**.

## macOS vs iPad distinction

Size classes (compact/regular) and `sidebarAdaptable` auto-switching
are iOS/iPadOS-only (Layout/Size classes; Sidebars/iOS-iPadOS).
macOS uses user-resized windows, split dividers, and explicit
hide/reveal with menu + shortcut fallback. visionOS 1280×720 default
is visionOS-only. Never transfer numeric or automatic behavior to Mac.

## Robust policy extracted

Prioritize the declared primary task pane per app task priority; this fixture's
browser-family decision is detail controls above sidebar chrome (illustrative,
not normative). Width budget per visible-pane configuration at its threshold: at the
smallest supported width only remaining visible panes count, hidden
panes carry no budget. Optional panes collapse/reveal only where declared, with a
persistent accessible fallback appropriate to app capabilities (fixture uses
button + View-menu command + shortcut; fixture overflow uses a labeled More-menu
to keep actions/selectors reachable — app-declared, not universal). Intent (user-hidden) vs
constraint (squeezed → declared compact variant). Minimum width AND
height both supported where resizable (declared fixed-size utilities record N/A
with justification); bottom-edge content is fragile on Mac.
Content-vs-frame coords in pane-local points; scale to backing pixels
only at capture. Fit transitions tested both directions.
Label/control/action keylines as relational columns where appropriate; whether
differing internal gutters are intentional is decided by the declared semantic
contract, never exempted by type alone; baselines and alignment rects over frame equality.
Platform idiom respected; all values app-owned. Keyboard, VoiceOver,
tooltips, RTL, long locales preserved; never use arbitrary visual scaling to hide
a fit failure (native small/mini sizes in context remain allowed).
Envelope runtime-tested before spacing polish. No universal window
number. Comparison screenshots inspiration only.

## Initial pre-fix observations — fixture limits (2026-09-16, explicit)

Confirmed observations: an absurdly tiny resizable window renders and
clips controls, and compact Sort-value/More show distinct edges from
surrounding columns. No exact geometry claimed. Whether those
relations are undesired is an app/user decision against the declared
contract. Ordering cause (`minSize` placement in fixture `main.swift`)
and contract verdicts stay unverified pending runtime boundary proof
(drag beyond minimum, both directions, sidebar×inspector matrix).
Fixture fix out of scope here; no outcome invented.

## Implementation follow-up (same session)

The initial constraints-only revision still allowed a real drag below its
declared minimum. A native window delegate now clamps interactive proposals to
the calibrated content minimum converted to a frame size. Live attempts to drag
toward 200×200 stopped at a 560×502 captured window (560×450 content policy).
This proves the tested boundary, not the precise cause of the earlier override.
Sidebar collapse/restoration, manual hiding with retained navigation, a narrow
inspector sheet, and inspector value retention on wide reopen were exercised.
Sort and More control-column alignment was visually checked. These are focused
checks, not certification across all locales, accessibility modes, or macOS versions.
