//
//  VScanner.swift
//  MRBasics
//
//  Created by Haotian on 2017/10/9.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation

extension Scanner {

    // MARK: Strings

    /// Returns a string, scanned as long as characters from a given character set are encountered, or `nil` if none are found.
    func scanCharactersFromSet(set: CharacterSet) -> String? {
        var value: NSString? = ""
        if scanCharacters(from: set, into: &value),
            let value = value as String? {
            return value
        }
        return nil
    }

    /// Returns a string, scanned until a character from a given character set are encountered, or the remainder of the scanner's string. Returns `nil` if the scanner is already `atEnd`.
    func scanUpToCharactersFromSet(set: CharacterSet) -> String? {
        var value: NSString? = ""
        if scanUpToCharacters(from: set, into: &value),
            let value = value as String? {
            return value
        }
        return nil
    }

    /// Returns the given string if scanned, or `nil` if not found.
    func scanString(str: String) -> String? {
        var value: NSString? = ""
        if scanString(str, into: &value),
            let value = value as String? {
            return value
        }
        return nil
    }

    /// Returns a string, scanned until the given string is found, or the remainder of the scanner's string. Returns `nil` if the scanner is already `atEnd`.
    func scanUpToString(str: String) -> String? {
        var value: NSString? = ""
        if scanUpTo(str, into: &value),
            let value = value as String? {
            return value
        }
        return nil
    }

    // MARK: Numbers

    /// Returns a Double if scanned, or `nil` if not found.
    func scanDouble() -> Double? {
        var value = 0.0
        if scanDouble(&value) {
            return value
        }
        return nil
    }

    /// Returns a Float if scanned, or `nil` if not found.
    func scanFloat() -> Float? {
        var value: Float = 0.0
        if scanFloat(&value) {
            return value
        }
        return nil
    }

    /// Returns an Int if scanned, or `nil` if not found.
    func scanInteger() -> Int? {
        var value = 0
        if scanInt(&value) {
            return value
        }
        return nil
    }

    /// Returns an Int32 if scanned, or `nil` if not found.
    func scanInt() -> Int32? {
        var value: Int32 = 0
        if scanInt32(&value) {
            return value
        }
        return nil
    }

    /// Returns an Int64 if scanned, or `nil` if not found.
    func scanLongLong() -> Int64? {
        var value: Int64 = 0
        if scanInt64(&value) {
            return value
        }
        return nil
    }

    /// Returns a UInt64 if scanned, or `nil` if not found.
    func scanUnsignedLongLong() -> UInt64? {
        var value: UInt64 = 0
        if scanUnsignedLongLong(&value) {
            return value
        }
        return nil
    }

    /// Returns an NSDecimal if scanned, or `nil` if not found.
    func scanDecimal() -> Decimal? {
        var value = Decimal()
        if scanDecimal(&value) {
            return value
        }
        return nil
    }

    // MARK: Hex Numbers

    /// Returns a Double if scanned in hexadecimal, or `nil` if not found.
    func scanHexDouble() -> Double? {
        var value = 0.0
        if scanHexDouble(&value) {
            return value
        }
        return nil
    }

    /// Returns a Float if scanned in hexadecimal, or `nil` if not found.
    func scanHexFloat() -> Float? {
        var value: Float = 0.0
        if scanHexFloat(&value) {
            return value
        }
        return nil
    }

    /// Returns a UInt32 if scanned in hexadecimal, or `nil` if not found.
    func scanHexInt() -> UInt32? {
        var value: UInt32 = 0
        if scanHexInt32(&value) {
            return value
        }
        return nil
    }

    /// Returns a UInt64 if scanned in hexadecimal, or `nil` if not found.
    func scanHexLongLong() -> UInt64? {
        var value: UInt64 = 0
        if scanHexInt64(&value) {
            return value
        }
        return nil
    }
}

enum VScannerErrors: Error {
    case UnreadableData(error: String)
    case InvalidData(error: String)
}

class VScanner {
    let scanner: Scanner
    var isAvailable: Bool {
        get {
            return false == scanner.isAtEnd
        }
    }

    init(string: String) {
        scanner = Scanner(string: string)
    }

    func moveToNextLine() {
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: nil)
        scanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
    }

    // Read from current scanner location up to the next whitespace
    func readMarker() -> String? {
        return scanner.scanUpToCharactersFromSet(set: CharacterSet.whitespacesAndNewlines)
    }

    // Read rom the current scanner location till the end of the line
    func readLine() -> String? {
        return scanner.scanUpToCharactersFromSet(set: CharacterSet.newlines)
    }

    // Read a single Int32 value
    func readInt() throws -> Int32 {
        var value = Int32.max
        if scanner.scanInt32(&value) {
            return value
        }

        throw VScannerErrors.InvalidData(error: "Invalid Int value")
    }

    // Read a single Double value
    func readDouble() throws -> Double {
        var value = Double.infinity
        if scanner.scanDouble(&value) {
            return value
        }

        throw VScannerErrors.InvalidData(error: "Invalid Double value")
    }


    func readString() throws -> String {
        if let string = scanner.scanUpToCharactersFromSet(set: CharacterSet.whitespacesAndNewlines) {
            return string
        }

        throw VScannerErrors.InvalidData(error: "Invalid String value")
    }

    func readTokens() throws -> [String] {
        var result: [String] = []

        while let string = scanner.scanUpToCharactersFromSet(set: CharacterSet.whitespacesAndNewlines) {
            result.append(string)
        }

        return result
    }

    func reset() {
        scanner.scanLocation = 0
    }

}
