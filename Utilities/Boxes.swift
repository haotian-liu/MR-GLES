//
//  Boxes.swift
//  MRBasics
//
//  Created by Haotian on 2018/1/5.
//  Copyright © 2018年 Haotian. All rights reserved.
//

import GLKit
import os.log

class Boxes {
    private let vertices = [
        GLKVector3(-1.0,  1.0, -1.0),
        GLKVector3(-1.0,  1.0,  1.0),
        GLKVector3(-1.0, -1.0,  1.0),
        GLKVector3(-1.0, -1.0, -1.0),
        GLKVector3( 1.0,  1.0, -1.0),
        GLKVector3( 1.0,  1.0,  1.0),
        GLKVector3( 1.0, -1.0,  1.0),
        GLKVector3( 1.0, -1.0, -1.0),
    ]

    private let faces: [GLuint] = [
        0, 1, 2, 0, 2, 3,
        0, 3, 7, 0, 7, 4,
        0, 1, 5, 0, 5, 4,
        1, 2, 6, 1, 6, 5,
        2, 6, 7, 2, 7, 3,
        4, 5, 6, 4, 6, 7,
    ]

    private var objects: [GLKMatrix4] = []

    private var VAO = GLuint()
    private var VBO = Array<GLuint>(repeating: GLuint(), count: 3)
    private var shader: BaseEffect!

    var viewMatrix = GLKMatrix4Identity, projectionMatrix = GLKMatrix4Identity

    init() {
//        objects.append(GLKMatrix4MakeTranslation(1.0,  1.0, 1.0))
//        objects.append(GLKMatrix4MakeTranslation(1.0, -1.0, 1.0))
    }

    func setupBuffer() {
        glGenVertexArrays(1, &VAO)
        glBindVertexArray(VAO)

        glGenBuffers(3, &VBO[0])

        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), VBO[0])
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), faces.count * MemoryLayout<GLuint>.size, faces, GLenum(GL_STATIC_DRAW))

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO[1])
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLKVector3>.size, vertices, GLenum(GL_STATIC_DRAW))
        let locVertPos = GLuint(glGetAttribLocation(shader.programId, "vertPos"))
        glEnableVertexAttribArray(locVertPos)
        glVertexAttribPointer(locVertPos, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        glBindVertexArray(0)
    }

    func setupShader() {
        self.shader = BaseEffect(vertexShader: "Shader/box.vs", fragmentShader: "Shader/box.fs")
    }

    func updateMatrix(type: MatrixType, mat: GLKMatrix4) {
        switch type {
        case .view:
            self.viewMatrix = mat
        case .projection:
            self.projectionMatrix = mat
        default:
            return
        }
    }

    func draw() {
        shader.Activate()
        glBindVertexArray(VAO)
        for modelMatrix in objects {
            var MVPMatrix = self.projectionMatrix * self.viewMatrix * modelMatrix
            withUnsafePointer(to: &MVPMatrix) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(glGetUniformLocation(shader.programId, "MVPMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(faces.count), GLenum(GL_UNSIGNED_INT), nil)
        }
    }

    func addBox(transform: GLKMatrix4) {
        objects.append(transform)
        os_log("Current boxes: %d", objects.count)
    }
}
