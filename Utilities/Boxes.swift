//
//  Boxes.swift
//  MRBasics
//
//  Created by Haotian on 2018/1/5.
//  Copyright © 2018年 Haotian. All rights reserved.
//

import ModelIO
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

    private var meshes: [GLKMesh] = []
    private var objects: [GLKMatrix4] = []

    private var VAO = GLuint()
    private var VBO = Array<GLuint>(repeating: GLuint(), count: 3)
    private var shader: BaseEffect!

    var viewMatrix = GLKMatrix4Identity, projectionMatrix = GLKMatrix4Identity

    init() {
//        objects.append(GLKMatrix4MakeTranslation(1.0,  1.0, 1.0))
//        objects.append(GLKMatrix4MakeTranslation(1.0, -1.0, 1.0))
    }

    func loadModel() {
        guard let url = Bundle.main.url(forResource: "Model/787", withExtension: "obj") else {
            os_log("error loading model")
            exit(-1)
        }

        let vertexDescriptor = MDLVertexDescriptor()

        var attr = vertexDescriptor.attributes[0] as! MDLVertexAttribute
        attr.name = MDLVertexAttributePosition
        attr.format = .float3
        attr.offset = 0
        attr.bufferIndex = 0

        attr = vertexDescriptor.attributes[1] as! MDLVertexAttribute
        attr.name = MDLVertexAttributeNormal
        attr.format = .float3
        attr.offset = 0
        attr.bufferIndex = 1

        attr = vertexDescriptor.attributes[2] as! MDLVertexAttribute
        attr.name = MDLVertexAttributeTextureCoordinate
        attr.format = .float3
        attr.offset = 0
        attr.bufferIndex = 2

        (vertexDescriptor.layouts[0] as! MDLVertexBufferLayout).stride = 12
        (vertexDescriptor.layouts[1] as! MDLVertexBufferLayout).stride = 12
        (vertexDescriptor.layouts[2] as! MDLVertexBufferLayout).stride = 12

        let asset = MDLAsset(url: url, vertexDescriptor: vertexDescriptor, bufferAllocator: GLKMeshBufferAllocator())
        for index in 0..<asset.count {
            guard let object = asset.object(at: index) as? MDLMesh else {
                os_log("error loading object")
                exit(-1)
            }
            os_log("Loaded MDLMesh with %d submeshes, %d vertex buffers, %d vertices", object.submeshes!.count, object.vertexBuffers.count, object.vertexCount)
            os_log("Loaded MDLMesh vertex descriptor attributes debug: %s %d %d", (object.vertexDescriptor.attributes[0] as! MDLVertexAttribute).name, (object.vertexDescriptor.attributes[0] as! MDLVertexAttribute).offset, (object.vertexDescriptor.attributes[0] as! MDLVertexAttribute).bufferIndex)
            do {
                let mesh = try GLKMesh(mesh: object)
                meshes.append(mesh)
                os_log("Loaded GLKMesh with %d submeshes, %d vertex buffers, %d vertices", mesh.submeshes.count, mesh.vertexBuffers.count, mesh.vertexCount)
            } catch {
                os_log("error converting GLKMesh")
                print("caught: \(error)")
                exit(-1)
            }
        }
        os_log("Loaded meshes: %d", meshes.count)
    }

    func setupBuffer() {
        loadModel()
        
//        glGenVertexArrays(1, &VAO)
//        glBindVertexArray(VAO)
//
//        glGenBuffers(3, &VBO[0])
//
//        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), VBO[0])
//        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), faces.count * MemoryLayout<GLuint>.size, faces, GLenum(GL_STATIC_DRAW))
//
//        glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO[1])
//        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLKVector3>.size, vertices, GLenum(GL_STATIC_DRAW))
//        let locVertPos = GLuint(glGetAttribLocation(shader.programId, "vertPos"))
//        glEnableVertexAttribArray(locVertPos)
//        glVertexAttribPointer(locVertPos, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)
//
//        glBindVertexArray(0)

        /////////////////////////////////////

        let mesh = meshes.first!
        let submesh = mesh.submeshes.first!

//        for submesh in mesh.submeshes {
//            let buf = submesh.elementBuffer
//            os_log("element count: %d, buffer offset: %d, buffer length: %d", submesh.elementCount, buf.offset, buf.length)
//        }

        glGenVertexArrays(1, &VAO)
        glBindVertexArray(VAO)
        // vertex position
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffers[0].glBufferName)
        let locVertPos = GLuint(glGetAttribLocation(shader.programId, "vertPos"))
        glEnableVertexAttribArray(locVertPos)
        glVertexAttribPointer(locVertPos, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        // vertex normal
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffers[1].glBufferName)
        let locVertNormal = GLuint(glGetAttribLocation(shader.programId, "vertNormal"))
        glEnableVertexAttribArray(locVertNormal)
        glVertexAttribPointer(locVertNormal, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        // vertex texture
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffers[2].glBufferName)
        let locVertTexture = GLuint(glGetAttribLocation(shader.programId, "vertUV"))
        glEnableVertexAttribArray(locVertTexture)
        glVertexAttribPointer(locVertTexture, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        // vertex index
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), submesh.elementBuffer.glBufferName)

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
//        glBindVertexArray(VAO)
//        for modelMatrix in objects {
//            let viewMatrix = GLKMatrix4MakeLookAt(3, 0, 0, 0, 0, 0, 0, 1, 0)
//            let projectionMatrix = GLKMatrix4MakePerspective(60.0, 4.0/3.0, 0.001, 50.0)
//            var MVPMatrix = projectionMatrix * viewMatrix * modelMatrix
//            withUnsafePointer(to: &MVPMatrix) {
//                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
//                    glUniformMatrix4fv(glGetUniformLocation(shader.programId, "MVPMatrix"), 1, GLboolean(GL_FALSE), $0)
//                }
//            }
//            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(faces.count), GLenum(GL_UNSIGNED_INT), nil)
//        }
        /////////////////////////////////
        glBindVertexArray(VAO)
        let mesh = meshes[0]
        let elementCount = mesh.submeshes.reduce(0, {sum, e in
            sum + e.elementCount
        })
        for _ in mesh.submeshes {
            let modelMatrix = GLKMatrix4Identity
            let viewMatrix = GLKMatrix4MakeLookAt(1000, 1000, 0, 0, 0, 0, 0, 1, 0)
            let projectionMatrix = GLKMatrix4MakePerspective(60.0, 4.0/3.0, 1, 5000.0)
            var MVPMatrix = projectionMatrix * viewMatrix * modelMatrix
            withUnsafePointer(to: &MVPMatrix) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(glGetUniformLocation(shader.programId, "MVPMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }
//            let offset: CConstVoidPointer = COpaquePointer(UnsafePointer<Int>(submesh.elementBuffer.offset))
//            glDrawElements(GLenum(GL_TRIANGLES), submesh.elementCount, GLenum(GL_UNSIGNED_INT), nil)
            glDrawElements(GLenum(GL_TRIANGLES), elementCount, GLenum(GL_UNSIGNED_INT), nil)
            break
        }
    }

    func addBox(transform: GLKMatrix4) {
        objects.append(transform)
        os_log("Current boxes: %d", objects.count)
    }
}
