//
//  GLESBasic.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/29.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import Foundation
import GLKit

extension GLKVector2 {
    init(_ x: GLfloat, _ y: GLfloat) {
        self = GLKVector2Make(x, y)
    }
}

extension GLKVector3 {
    init(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        self = GLKVector3Make(x, y, z)
    }
}

extension GLKVector4 {
    init(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
        self = GLKVector4Make(x, y, z, w)
    }
}

extension GLKMatrix3 {
    init(_ row0: GLKVector3, _ row1: GLKVector3, _ row2: GLKVector3) {
        self = GLKMatrix3MakeWithRows(row0, row1, row2)
    }
}

extension GLKMatrix4 {
    init(_ row0: GLKVector4, _ row1: GLKVector4, _ row2: GLKVector4, _ row3: GLKVector4) {
        self = GLKMatrix4MakeWithRows(row0, row1, row2, row3)
    }
}
