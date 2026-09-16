# Provenance

Original skill and tooling in this repo. Research inputs informed the
design; they are not redistributed here.

## Authority distinction

- Apple documentation is authoritative for platform behavior (layout,
  typography, windows, alignment rects, accessibility frames, WWDC
  sessions). Linked, never restated as skill rules.
- Community skills and tooling READMEs were reviewed as patterns only.
  No aesthetic prescription from them is treated as a platform
  requirement, and no universal dimension from them ships as a default.
- App values are calibrated per app and family with `authority:
  app-decision`. Heuristics stay labeled `audit-heuristic`.

## Reviewed sources

Reviewed repository revisions (research snapshots are not redistributed):

- impeccable layout — [pbakaus/impeccable@0a4e72a](https://github.com/pbakaus/impeccable/tree/0a4e72a)
- SwiftUI agent skill — [twostraws/SwiftUI-Agent-Skill@be297ff](https://github.com/twostraws/SwiftUI-Agent-Skill/tree/be297ff)
- SwiftUI expert skill — [AvdLee/SwiftUI-Agent-Skill@00a94e1](https://github.com/AvdLee/SwiftUI-Agent-Skill/tree/00a94e1)
- macOS community skill — [ehmo/platform-design-skills@dc2be82](https://github.com/ehmo/platform-design-skills/tree/dc2be82)
- design-review skill — [garrytan/gstack@a6b3a57](https://github.com/garrytan/gstack/tree/a6b3a57)
- SwiftUI design tokens — [eworthing/agent-skills@090e206](https://github.com/eworthing/agent-skills/tree/090e206)
- SwiftUI interface skill — [ZHUOLIN0928/swiftui-interface-design-skill@eafbd1b](https://github.com/ZHUOLIN0928/swiftui-interface-design-skill/tree/eafbd1b)
- ViewInspector README — [nalexn/ViewInspector@3a90308](https://github.com/nalexn/ViewInspector/tree/3a90308)
- swift-syntax README — [swiftlang/swift-syntax@383f690](https://github.com/swiftlang/swift-syntax/tree/383f690)

Apple references linked from the skill (canonical URLs, no snapshot
redistribution):

- `https://developer.apple.com/design/human-interface-guidelines/layout`
- `https://developer.apple.com/design/human-interface-guidelines/typography`
- `https://developer.apple.com/design/human-interface-guidelines/windows`
- `https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes`
- `https://developer.apple.com/videos/play/wwdc2019/237/`

## Useful concepts, in our own words

- Compare roles within one family and environment in pane-local units;
  never absolute screen coordinates across families.
- Maintain an explicit surface inventory with a reported denominator;
  unmeasured means unverified, never pass.
- Separate observation from inference; keep values null where unknown.
- Judge numeric drift with tolerance plus measurement uncertainty, in a
  declared unit, space, and environment.

No source text is pasted here. No private skills, personal paths, logs,
or user app data are published. Research snapshots remain local working material.
