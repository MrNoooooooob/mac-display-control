// Copyright © 2026 MrNoooooooob. MIT licensed.
// Pure release-version parsing; no background networking or auto-installation.
import Foundation

struct ReleaseVersion: Comparable, Equatable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: String?
    init?(_ value: String) {
        let normalized = value.hasPrefix("v") ? String(value.dropFirst()) : value
        let fragments = normalized.split(separator: "-", maxSplits: 1).map(String.init)
        guard !fragments.isEmpty else { return nil }
        let parts = fragments[0].split(separator: ".")
        guard parts.count == 3, let major = Int(parts[0]),
              let minor = Int(parts[1]), let patch = Int(parts[2]),
              major >= 0, minor >= 0, patch >= 0 else { return nil }
        self.major = major; self.minor = minor; self.patch = patch
        self.prerelease = fragments.count > 1 ? fragments[1] : nil
    }
    var description: String {
        "\(major).\(minor).\(patch)" + (prerelease.map { "-" + $0 } ?? "")
    }
    static func < (lhs: ReleaseVersion, rhs: ReleaseVersion) -> Bool {
        let left = [lhs.major,lhs.minor,lhs.patch]
        let right = [rhs.major,rhs.minor,rhs.patch]
        if left != right { return left.lexicographicallyPrecedes(right) }
        switch (lhs.prerelease,rhs.prerelease) {
        case (nil,nil): return false
        case (nil,_?): return false
        case (_?,nil): return true
        case (let a?,let b?): return a < b
        }
    }
}
