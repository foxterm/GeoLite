// FoxTerm | MaxMind.swift
// Copyright (c) 2025-2026 foxterm.app
// Created by foxterm@foxmail.com

import Extension
import FileKit
import Foundation
import libmaxminddb

public final class MaxMind: @unchecked Sendable {
    /// A singleton instance of `MaxMind` initialized with the GeoLite2 country database file.
    ///
    /// This instance provides access to the GeoLite2 country database for geolocation lookups.
    ///
    /// Usage:
    /// ```swift
    /// let maxMindInstance = MaxMind.shared
    /// ```
    public static let shared: MaxMind = .init()
    var raw: UnsafeMutablePointer<MMDB_s>?

    public var isRemote = false

    var size: Int64 = 0

    /// Initializes a new instance of the class with the specified file path.
    ///
    /// - Parameter file: The path to the MaxMind database file as a `String`.
    /// - Note: The file path is converted to bytes and used to open the MaxMind database.
    public init() {
        open()
    }

    deinit {
        mmdb_close(raw)
        raw = nil
    }
}

public extension MaxMind {
    func open() {
        close()
        if let file = Path(url: GeoLite2.shared.remote) {
            raw = mmdb_open(file.rawValue.bytes)
            if raw != nil {
                size = Int64(file.fileSize ?? 0)
            }
        }
        if raw == nil, let local = Path(url: GeoLite2.shared.local) {
            raw = mmdb_open(local.rawValue.bytes)
            if raw != nil {
                size = Int64(local.fileSize ?? 0)
            }
            isRemote = false
        } else {
            isRemote = true
        }
    }

    func close() {
        mmdb_close(raw)
        raw = nil
    }

    /// Looks up the ISO country code for a given IP address.
    ///
    /// This function checks if the provided IP address is valid and not a local network IP.
    /// If the IP address is valid and not a LAN IP, it queries the MaxMind database for the
    /// corresponding ISO country code.
    ///
    /// - Parameter ip: The IP address to look up.
    /// - Returns: The ISO country code as a `String` if found, otherwise `nil`.
    func lookupIsoCode(_ ip: IP) -> String? {
        guard ip.isPubIP else {
            return nil
        }
        guard let code = mmdb_lookup_iso_code(raw, ip.bytes) else {
            return nil
        }
        defer {
            code.deallocate()
        }
        let str = code.string
        guard str.count == 2 else {
            return nil
        }
        return str.uppercased()
    }

    /// A computed property that provides access to the metadata of the MaxMind database.
    ///
    /// This property returns an `UnsafeMutablePointer` to an `MMDB_metadata_s` structure,
    /// which contains metadata information about the MaxMind database.
    ///
    /// - Note: The pointer returned by this property is unsafe and mutable, so it should be
    ///         used with caution to avoid memory safety issues.
    var metadata: Metadata? {
        guard let data = mmdb_metadata(raw) else {
            return nil
        }
        let metadata = data.pointee
        return .init(
            type: String(cString: metadata.database_type),
            version:
            "\(metadata.ip_version).\(metadata.binary_format_minor_version).\(metadata.binary_format_major_version)",
            date: Date(timeIntervalSince1970: TimeInterval(metadata.build_epoch)),
            mode: Int(metadata.node_count), size: size
        )
    }
}

public struct Metadata {
    public let type: String
    public let version: String
    public let date: Date
    public let mode: Int
    public let size: Int64
}
