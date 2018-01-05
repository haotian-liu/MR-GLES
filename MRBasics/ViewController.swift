//
//  ViewController.swift
//  MRBasics
//
//  Created by Haotian on 2017/9/29.
//  Copyright © 2017年 Haotian. All rights reserved.
//

import UIKit
import GLKit
import ARKit
import os.log

class ViewController: GLKViewController, ARSessionDelegate {

    var arSession = ARSession()

    var vertices = [
        GLKVector3(-1.0, -1.0, 0.0),
        GLKVector3( 1.0, -1.0, 0.0),
        GLKVector3( 1.0,  1.0, 0.0),
        GLKVector3(-1.0,  1.0, 0.0)
    ]

    let vertIndex : [GLuint] = [ 0, 1, 2, 0, 2, 3 ]

    var VAO = GLuint()
    var VBO = Array<GLuint>(repeating: GLuint(), count: 3)

    var yTexture = GLuint(), uvTexture = GLuint()
    var baseEffect = GLKBaseEffect()
    var shader : BaseEffect!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGLContext()
        setupShader()
        setupBuffer()
        setupAR()

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runAR()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAR()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        baseEffect.prepareToDraw()

        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GLenum(GL_COLOR_BUFFER_BIT))

        shader.Activate()
        glBindVertexArray(VAO)

        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.yTexture)
        glUniform1i(glGetUniformLocation(shader.programId, "yTexture"), 0)

        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), self.uvTexture)
        glUniform1i(glGetUniformLocation(shader.programId, "uvTexture"), 1)

        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(vertIndex.count), GLenum(GL_UNSIGNED_INT), nil)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        var imageWidth = GLsizei(CVPixelBufferGetWidthOfPlane(pixelBuffer, 0))
        var imageHeight = GLsizei(CVPixelBufferGetHeightOfPlane(pixelBuffer, 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)

        glBindTexture(GLenum(GL_TEXTURE_2D), self.yTexture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, imageWidth, imageHeight, 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), baseAddress)
        //        os_log("y width: %d height: %d\n", imageWidth, imageHeight)

        imageWidth = GLsizei(CVPixelBufferGetWidthOfPlane(pixelBuffer, 1))
        imageHeight = GLsizei(CVPixelBufferGetHeightOfPlane(pixelBuffer, 1))
        let laAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.uvTexture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE_ALPHA, imageWidth, imageHeight, 0, GLenum(GL_LUMINANCE_ALPHA), GLenum(GL_UNSIGNED_BYTE), laAddress)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)

        //        os_log("uv width: %d height: %d\n", imageWidth, imageHeight)
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

    func setupAR() {
        self.arSession.delegate = self

        // MARK: setup ar textures
        glGenTextures(1, &yTexture);
        glBindTexture(GLenum(GL_TEXTURE_2D), self.yTexture)
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)

        glGenTextures(1, &uvTexture);
        glBindTexture(GLenum(GL_TEXTURE_2D), self.uvTexture)
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)

        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    }

    func runAR() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        self.arSession.run(config)
    }

    func pauseAR() {
        self.arSession.pause()
    }
}
