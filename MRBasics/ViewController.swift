//
//  ViewController.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/29.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import UIKit
import GLKit

class ViewController: GLKViewController {

    var vertices = [
        Vertex(-0.5, -0.5, 0.0),
        Vertex( 0.5, -0.5, 0.0),
        Vertex( 0.5,  0.5, 0.0),
        Vertex(-0.5,  0.5, 0.0)
    ]

    var vertexBufferId = GLuint()
    var baseEffect = GLKBaseEffect()

    override func viewDidLoad() {
        super.viewDidLoad()

        let view = self.view as! GLKView
        view.context = EAGLContext(api: .openGLES3)!
        EAGLContext.setCurrent(view.context)

        baseEffect.useConstantColor = GLboolean(GL_TRUE)
        baseEffect.constantColor = GLKVector4Make(1, 0, 1, 1)

        glGenBuffers(1, &vertexBufferId)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferId)

        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<Vertex>.size, vertices, GLenum(GL_STATIC_DRAW))
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        baseEffect.prepareToDraw()

        glClearColor(1.0, 0.0, 0.0, 1.0);
        glClear(GLenum(GL_COLOR_BUFFER_BIT))
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferId)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, GLsizei(vertices.count))
    }
}

