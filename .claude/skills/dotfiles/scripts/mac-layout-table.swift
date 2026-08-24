// Generate the key-translation tables used in emacs/init.el.
//
//   swift .claude/skills/dotfiles/scripts/mac-layout-table.swift "Dev Dvorak" Russian Ukrainian
//
// The first argument is the reference layout (the one Emacs bindings are
// learned on); the rest are layouts whose *modified* keys should behave as if
// the reference layout were active. Names are the localized names shown in
// System Settings > Keyboard (macOS's "Ukrainian-PC" shows as "Ukrainian").
// Tables come from UCKeyTranslate, i.e. the same data macOS itself uses.
//
// Output, as elisp string literals:
//   reference: FROM (base+shift plane chars) / QWERTY (its ⌘-plane chars)
//   others:    FROM (chars the reference layout has nowhere, so translating
//              them can't disturb typing on the reference layout) /
//              DVORAK (reference base plane, for C-/M- chords) /
//              QWERTY (reference ⌘ plane, for ⌘ shortcuts)
// Only keycodes 0-50 are covered (the ANSI character keys), minus 10 (ISO §),
// 36 (Return), 48 (Tab), 49 (Space).
import Carbon
import Foundation

let codes = (0...50).filter { ![10, 36, 48, 49].contains($0) }
let planes: [(String, UInt32)] = [
    ("base", 0), ("shift", UInt32(shiftKey) >> 8),
    ("cmd", UInt32(cmdKey) >> 8), ("shiftcmd", UInt32(cmdKey | shiftKey) >> 8),
]

func layoutTable(named wanted: String) -> [String: [Character?]]? {
    let filter = [kTISPropertyInputSourceType: kTISTypeKeyboardLayout] as CFDictionary
    let list = TISCreateInputSourceList(filter, true).takeRetainedValue() as! [TISInputSource]
    for src in list {
        let n = Unmanaged<CFString>.fromOpaque(
            TISGetInputSourceProperty(src, kTISPropertyLocalizedName)!).takeUnretainedValue() as String
        guard n == wanted,
              let p = TISGetInputSourceProperty(src, kTISPropertyUnicodeKeyLayoutData) else { continue }
        let data = Unmanaged<CFData>.fromOpaque(p).takeUnretainedValue() as Data
        var table: [String: [Character?]] = [:]
        data.withUnsafeBytes { raw in
            let layout = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress!
            for (pname, state) in planes {
                table[pname] = codes.map { code in
                    var dead: UInt32 = 0, len = 0
                    var chars = [UniChar](repeating: 0, count: 4)
                    let st = UCKeyTranslate(layout, UInt16(code), UInt16(kUCKeyActionDown), state,
                                            UInt32(LMGetKbdType()), UInt32(kUCKeyTranslateNoDeadKeysMask),
                                            &dead, 4, &len, &chars)
                    guard st == noErr, len == 1 else { return nil }
                    return Character(String(utf16CodeUnits: chars, count: 1))
                }
            }
        }
        return table
    }
    return nil
}

func elisp(_ s: String) -> String {
    "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 1, let ref = layoutTable(named: args[0]) else {
    FileHandle.standardError.write("usage: mac-layout-table.swift <reference layout> [layout...]\n".data(using: .utf8)!)
    exit(1)
}
let refChars = Set(planes.flatMap { ref[$0.0]!.compactMap { $0 } })

// Reference layout: base/shift plane -> ⌘ plane, where they differ.
var from = "", qwerty = ""
for (plain, cmd) in [("base", "cmd"), ("shift", "shiftcmd")] {
    for i in codes.indices {
        if let a = ref[plain]![i], let b = ref[cmd]![i], a != b { from.append(a); qwerty.append(b) }
    }
}
print(";; \(args[0])\n  from   \(elisp(from))\n  qwerty \(elisp(qwerty))")

for name in args.dropFirst() {
    guard let t = layoutTable(named: name) else {
        FileHandle.standardError.write("no such layout: \(name)\n".data(using: .utf8)!); exit(1)
    }
    var from = "", dvorak = "", qwerty = ""
    for (plain, cmd) in [("base", "cmd"), ("shift", "shiftcmd")] {
        for i in codes.indices {
            guard let a = t[plain]![i], !refChars.contains(a),
                  let d = ref[plain]![i], let q = ref[cmd]![i] else { continue }
            from.append(a); dvorak.append(d); qwerty.append(q)
        }
    }
    print(";; \(name)\n  from   \(elisp(from))\n  dvorak \(elisp(dvorak))\n  qwerty \(elisp(qwerty))")
}
