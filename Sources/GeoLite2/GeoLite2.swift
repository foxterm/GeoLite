// FoxTerm | GeoLite2.swift
// Copyright (c) 2025-2026 foxterm.app
// Created by foxterm@foxmail.com

import Extension
import FileKit
import Foundation

public final class GeoLite2: Sendable {
    public static let shared: GeoLite2 = .init()
    public let geoip: String =
        "https://github.com/foxterm/GeoLite2/releases/latest/download/GeoLite2-Country.mmdb"
    public let remote: URL = Path.userCaches.url.appendingPathComponent("GeoLite2.mmdb")
    public let local: URL = Bundle.module.url(forResource: "GeoLite2", withExtension: "mmdb")!
}

public extension GeoLite2 {
    func downloadFile(
        from url: String, to localURL: URL, completion: @escaping (Error?) -> Void
    ) {
        guard let with = URL(string: url) else {
            completion(nil)
            return
        }
        let task = URLSession.shared.downloadTask(with: with) { tempLocalURL, response, error in
            if let error {
                completion(error)
                return
            }

            guard let tempLocalURL, let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  (200 ... 299).contains(statusCode)
            else {
                completion(NSError(domain: "InvalidResponse", code: -1, userInfo: nil))
                return
            }
            do {
                if let p = Path(url: localURL), p.isRegular {
                    try p.deleteFile()
                }
                try FileManager.default.moveItem(at: tempLocalURL, to: localURL)
                completion(nil)
            } catch let writeError {
                completion(writeError)
            }
        }
        task.resume()
    }
}
