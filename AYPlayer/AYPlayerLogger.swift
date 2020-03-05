//
//  AYPlayerLogger.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import Foundation

final class AYPlayerLoggerInputParam {
    var domains: [AYPlayerLoggerDomain]?
}

final class AYPlayerLogger {
    // MARK: Singletons

    static let instance = AYPlayerLogger()
    static let setup = AYPlayerLoggerInputParam()

    // MARK: Input

    private var domains: [AYPlayerLoggerDomain] = []
    private let formatter = DateFormatter()
    private let dateFormat = "hh:mm:ssSSS"

    // MARK: Init

    private init() {
        guard let domains = AYPlayerLogger.setup.domains
        else { assertionFailure("should provide configuration to logger"); return }

        self.domains = domains
        setupDateFormatter()
    }

    private func setupDateFormatter() {
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
    }

    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last ?? ""
    }

    func log(message: String,
             domain: AYPlayerLoggerDomain,
             fileName: String = #file,
             line: Int = #line,
             funcName _: String = #function) {
        guard domains.contains(domain) else { return }
        print("\(formatter.string(from: Date())) \(domain.description)[\(sourceFileName(filePath: fileName))]:\(line) :: \(message)")
    }
}
