import AppKit
import Foundation

struct SystemFontWeight: Identifiable, Hashable {
    let id: Int
    let name: String
    let weight: Int
}

struct SystemFontFamily: Identifiable, Hashable {
    let id: String
    let name: String
    let weights: [SystemFontWeight]
}

enum FontCatalog {
    static func loadFamilies() -> [SystemFontFamily] {
        let manager = NSFontManager.shared
        let names = manager.availableFontFamilies.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return names.compactMap { family -> SystemFontFamily? in
            guard let members = manager.availableMembers(ofFontFamily: family) else {
                return SystemFontFamily(id: family, name: family, weights: [
                    SystemFontWeight(id: 400, name: "Regular", weight: 400)
                ])
            }
            var weights: [SystemFontWeight] = []
            var seen = Set<Int>()
            for member in members {
                // [postScriptName, faceName, weight, traits]
                guard member.count >= 3,
                      let face = member[1] as? String else { continue }
                let rawWeight = (member[2] as? NSNumber)?.intValue ?? 5
                let css = mapAppKitWeightToCSS(rawWeight)
                if seen.contains(css) { continue }
                seen.insert(css)
                weights.append(SystemFontWeight(id: css, name: face, weight: css))
            }
            weights.sort { $0.weight < $1.weight }
            if weights.isEmpty {
                weights = [SystemFontWeight(id: 400, name: "Regular", weight: 400)]
            }
            return SystemFontFamily(id: family, name: family, weights: weights)
        }
    }

    // AppKit font weight is typically 0...15 (sometimes 1...15)
    private static func mapAppKitWeightToCSS(_ value: Int) -> Int {
        switch value {
        case ...2: return 100
        case 3: return 200
        case 4: return 300
        case 5: return 400
        case 6: return 500
        case 7, 8: return 600
        case 9: return 700
        case 10, 11: return 800
        default: return 900
        }
    }
}
