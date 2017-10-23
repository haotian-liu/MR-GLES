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

    let vertIndex : [GLuint] = [ 0, 1, 2, 0, 2, 3 ]

    var VAO = GLuint()
    var VBO = Array<GLuint>(repeating: GLuint(), count: 3)
    var baseEffect = GLKBaseEffect()
    var shader : BaseEffect!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGLContext()
        setupShader()
        setupBuffer()

        let loader = ObjLoader(basePath: "./Model", source: "3d-model.obj")

        loader.read()

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        baseEffect.prepareToDraw()

        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GLenum(GL_COLOR_BUFFER_BIT))

        shader.Activate()
        glBindVertexArray(VAO)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(vertIndex.count), GLenum(GL_UNSIGNED_INT), nil)
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
        glGenVertexArrays(1, &VAO)
        glBindVertexArray(VAO)

        glGenBuffers(3, &VBO[0])

        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), VBO[0])
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), vertIndex.count * MemoryLayout<GLuint>.size, vertIndex, GLenum(GL_STATIC_DRAW))

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO[1])
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLKVector3>.size, vertices, GLenum(GL_STATIC_DRAW))
        let locVertPos = GLuint(glGetAttribLocation(shader.programId, "vertPos"))
        glEnableVertexAttribArray(locVertPos)
        glVertexAttribPointer(locVertPos, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        glBindVertexArray(0)
    }
}

