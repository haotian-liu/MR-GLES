//
//  GLESBasic.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/29.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

struct Vertex {
    var x: GLfloat = 0.0
    var y: GLfloat = 0.0
    var z: GLfloat = 0.0

    init(_ x:GLfloat, _ y:GLfloat, _ z:GLfloat) {
        self.x = x
        self.y = y
        self.z = z
    }
}
