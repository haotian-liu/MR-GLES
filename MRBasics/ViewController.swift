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
        GLKVector3(-0.5, -0.5, 0.0),
        GLKVector3( 0.5, -0.5, 0.0),
        GLKVector3( 0.5,  0.5, 0.0),
        GLKVector3(-0.5,  0.5, 0.0)
    ]

    var vertexBufferId = GLuint()
    var baseEffect = GLKBaseEffect()
    var shader : BaseEffect!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGLContext()
        setupShader()
        setupBuffer()

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        baseEffect.prepareToDraw()

        glClearColor(1.0, 0.0, 0.0, 1.0);
        glClear(GLenum(GL_COLOR_BUFFER_BIT))

        shader.prepareToDraw()

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferId)
        let locVertPos = GLuint(glGetAttribLocation(shader.ProgramId(), "vertPos"))
        glEnableVertexAttribArray(locVertPos)
        glVertexAttribPointer(locVertPos, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, GLsizei(vertices.count))
    }
}

extension ViewController {
    func setupGLContext() {
        let view = self.view as! GLKView
        view.context = EAGLContext(api: .openGLES3)!
        EAGLContext.setCurrent(view.context)
    }

    func setupShader() {
        self.shader = BaseEffect(vertexShader: "Shader/base.vs", fragmentShader: "Shader/base.fs")
    }

    func setupBuffer() {
        glGenBuffers(1, &vertexBufferId)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBufferId)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLKVector3>.size, vertices, GLenum(GL_STATIC_DRAW))
    }
}

