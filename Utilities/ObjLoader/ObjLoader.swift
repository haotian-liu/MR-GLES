//
//  ObjLoader.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/30.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

class ObjLoader {
    var scanner: VScanner
    let basePath: String

    init(basePath: String, source: String) {
        self.basePath = basePath

        let sourcePath = Bundle.main.path(forResource: basePath + "/" + source, ofType: nil)
        do {
            let sourceString = try String(contentsOfFile: sourcePath!, encoding: String.Encoding.utf8)
            scanner = VScanner(string: sourceString)
        } catch {
            exit(1)
        }
    }

    func read() {
        scanner.reset()
        while scanner.isAvailable {
            let marker = scanner.readMarker()
            scanner.moveToNextLine()
        }
    }
}
