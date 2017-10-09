//
//  ObjLoader.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/30.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation

class ObjLoader {
    var scanner: Scanner
    let basePath: String

    init(basePath: String, source: String) {
        self.basePath = basePath

        let sourcePath = Bundle.main.path(forResource: basePath + "/" + source, ofType: nil)
        do {
            let sourceString = try String(contentsOfFile: sourcePath!, encoding: String.Encoding.utf8)
            scanner = Scanner(string: sourceString)
        } catch {
            exit(1)
        }
    }
}
