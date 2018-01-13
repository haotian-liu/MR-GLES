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

class ModelObject {
//    init(_ transform: GLKMatrix4) {
//        self.initialTransform = transform
//    }
    init(_ translate: float3) {
        self.translate = GLKVector3(translate)
    }
    var translate: GLKVector3
    var transform: GLKMatrix4 {
        get {
            return      GLKMatrix4MakeTranslation(translate.x, translate.y, translate.z)
                    *   GLKMatrix4MakeRotation(rotate, 0.0, 1.0, 0.0)
                    *   GLKMatrix4MakeScale(scaleBias, scaleBias, scaleBias)
        }
    }
    var scaleBias: GLfloat = 1.0
    var rotate: GLfloat = 0.0
    var selected: Bool = false
}

class Boxes {
//    private let vertices = [
//        GLKVector3(-1.0,  1.0, -1.0),
//        GLKVector3(-1.0,  1.0,  1.0),
//        GLKVector3(-1.0, -1.0,  1.0),
//        GLKVector3(-1.0, -1.0, -1.0),
//        GLKVector3( 1.0,  1.0, -1.0),
//        GLKVector3( 1.0,  1.0,  1.0),
//        GLKVector3( 1.0, -1.0,  1.0),
//        GLKVector3( 1.0, -1.0, -1.0),
//    ]
//
//    private let faces: [GLuint] = [
//        0, 1, 2, 0, 2, 3,
//        0, 3, 7, 0, 7, 4,
//        0, 1, 5, 0, 5, 4,
//        1, 2, 6, 1, 6, 5,
//        2, 6, 7, 2, 7, 3,
//        4, 5, 6, 4, 6, 7,
//    ]

//    private let vertices = [
//        GLKVector3(-1.0, 0.0, -1.0),
//        GLKVector3(-1.0, 0.0,  1.0),
//        GLKVector3( 1.0, 0.0,  1.0),
//        GLKVector3( 1.0, 0.0, -1.0),
//    ]

    private var vertices = [GLKVector3]()

    private var shadowVBO = GLuint()

    private var meshes: [GLKMesh] = []
    private var objects: [ModelObject] = []
    private(set) var selectedObject: ModelObject? = nil

    // shadow FBO
    private var FBO = GLuint()
    private var RBO = GLuint()
    private var depthTexture = GLuint()

    private var VAO = Array<GLuint>(repeating: GLuint(), count: 3)
    private var VBO = Array<GLuint>(repeating: GLuint(), count: 3)
    private var shader: BaseEffect!
    private var shadowBufferShader: BaseEffect!
    private var shadowShader: BaseEffect!
    private var textures = Array<GLuint>(repeating: GLuint(), count: 2)
    private var hasTextures = [Bool]()

    private var viewMatrix = GLKMatrix4Identity, projectionMatrix = GLKMatrix4Identity

    var viewport = CGRect()

    init() {
//        objects.append(GLKMatrix4MakeTranslation(1.0,  1.0, 1.0))
//        objects.append(GLKMatrix4MakeTranslation(1.0, -1.0, 1.0))

        let count = 1000
        vertices.append(GLKVector3(0.0, 0.0, 0.0))
        for i in 0...count {
            let a = GLfloat(sin(Float(i) * (2 * Float.pi) / Float(count)))
            let b = GLfloat(cos(Float(i) * (2 * Float.pi) / Float(count)))
            vertices.append(GLKVector3(a, 0.0, b))
        }
    }

    func loadModel() {
        guard let url = Bundle.main.url(forResource: "Model/sofa/sofa", withExtension: "obj") else {
            os_log("error loading model", type: .error)
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
                os_log("error loading object", type: .error)
                exit(-1)
            }
            for case let submesh as MDLSubmesh in object.submeshes! {
                hasTextures.append(submesh.material!.name == "VRayMtl1SG")
            }
//            object.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
            os_log("Loaded MDLMesh with %d submeshes, %d vertex buffers, %d vertices", type: .debug, object.submeshes!.count, object.vertexBuffers.count, object.vertexCount)
//            os_log("Loaded MDLMesh vertex descriptor attributes debug: %s %d %d", type: .debug, (object.vertexDescriptor.attributes[0] as! MDLVertexAttribute).name, (object.vertexDescriptor.attributes[0] as! MDLVertexAttribute).offset, (object.vertexDescriptor.attributes[0] as! MDLVertexAttribute).bufferIndex)
            do {
                let mesh = try GLKMesh(mesh: object)
                meshes.append(mesh)
                os_log("Loaded GLKMesh with %d submeshes, %d vertex buffers, %d vertices", type: .debug, mesh.submeshes.count, mesh.vertexBuffers.count, mesh.vertexCount)

//                let shadowPlane = MDLMesh.newPlane(withDimensions: float2(x: 1.0, y: 1.0), segments: uint2(x: 10, y: 10), geometryType: .triangles, allocator: GLKMeshBufferAllocator())
//
//                let shadowMesh = try GLKMesh(mesh: shadowPlane)
//                shadowPlanes.append(shadowMesh)
//                os_log("Shadow GLKMesh with %d submeshes, %d vertex buffers, %d vertices", type: .debug, shadowMesh.submeshes.count, shadowMesh.vertexBuffers.count, shadowMesh.vertexCount)

//                // generate shadow plane and bake light
//                let asset = MDLAsset(bufferAllocator: GLKMeshBufferAllocator())
//
//                let shadowPlane = MDLMesh.newPlane(withDimensions: float2(x: 1.0, y: 1.0), segments: uint2(x: 100, y: 100), geometryType: .triangles, allocator: GLKMeshBufferAllocator())
//                let lightSource = MDLAreaLight()
//                // MDLLight Property
//                lightSource.lightType = .rectangularArea
//                lightSource.colorSpace = CGColorSpace.sRGB as String!
//
//                // MDLPhysicallyPlausibleLight Property
//                lightSource.innerConeAngle = 120
//                lightSource.outerConeAngle = 150
//
//                // MDLAreaLight Property
//                lightSource.areaRadius = 2.0
//                lightSource.aspect = 0.1
//                lightSource.superEllipticPower = float2(x: 2.0, y: 2.0)
//
//                os_log("Loaded shadowMDLMesh with %d submeshes, %d vertex buffers, %d vertices", type: .debug, shadowPlane.submeshes!.count, shadowPlane.vertexBuffers.count, shadowPlane.vertexCount)
//
//                object.transform = MDLTransform(identity: ())
//                object.transform!.setLocalTransform!(object.transform!.matrix)
////                shadowPlane.transform = MDLTransform(identity: ())
////                shadowPlane.transform!.setLocalTransform!(shadowPlane.transform!.matrix)
////                shadowPlane.addNormals(withAttributeNamed: nil, creaseThreshold: 1.0)
//                lightSource.transform = MDLTransform(identity: ())
//                lightSource.transform!.setLocalTransform!(lightSource.transform!.matrix)
//
//                asset.add(object)
//                asset.add(shadowPlane)
//                asset.add(lightSource)
//
//                let lightsToConsider = [lightSource]
//                let objectsToConsider = [object]
//                let vertexAttributeNamed = MDLVertexAttributeOcclusionValue
//                let submeshes = shadowPlane.submeshes!
//                let material = (submeshes.firstObject as! MDLSubmesh).material!
//                let materialPropertyNamed = material.name
//                shadowPlane.generateLightMapVertexColorsWithLights(toConsider: lightsToConsider, objectsToConsider: [object], vertexAttributeNamed: MDLVertexAttributeColor)
////                shadowPlane.generateLightMapTexture(withQuality: 0.1, lightsToConsider: lightsToConsider, objectsToConsider: [shadowPlane], vertexAttributeNamed: vertexAttributeNamed, materialPropertyNamed: materialPropertyNamed)
//
////                shadowPlane.generateAmbientOcclusionVertexColors(withQuality: 1, attenuationFactor: 0.98, objectsToConsider: [shadowPlane], vertexAttributeNamed: MDLVertexAttributeOcclusionValue)
//
//                let shadowMesh = try GLKMesh(mesh: shadowPlane)
//                os_log("Baked shadowMesh with %d submeshes, %d vertex buffers, %d vertices", type: .debug, shadowMesh.submeshes.count, shadowMesh.vertexBuffers.count, shadowMesh.vertexCount)
            } catch {
                os_log("error converting GLKMesh", type: .error)
                print("caught: \(error)")
                exit(-1)
            }
        }
        os_log("Loaded meshes: %d", type: .debug, meshes.count)
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

        glGenTextures(2, &textures[0])

//        load(texture: textures[0], from: "Model/basketball/map_Ka.png")
//        load(texture: textures[1], from: "Model/basketball/map_bump.png")
        load(texture: textures[0], from: "Model/sofa/41515f_cloth_dif.jpg")
//        load(texture: textures[1], from: "Model/sofa/41515f_cloth_dif.jpg")

//        for submesh in mesh.submeshes {
//            let buf = submesh.elementBuffer
//            os_log("element count: %d, buffer offset: %d, buffer length: %d", type: .debug, submesh.elementCount, buf.offset, buf.length)
//        }

        glGenVertexArrays(3, &VAO[0])
        glBindVertexArray(VAO[0])
        // vertex position
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffers[0].glBufferName)
        let locVertPos = GLuint(glGetAttribLocation(shader.programId, "vertPos"))
//        print("loc vao0\(locVertPos)")
//        let locVertPos: GLuint = 0 // fixed layout
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

//        // vertex tangent
//        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffers[3].glBufferName)
//        let locVertTangent = GLuint(glGetAttribLocation(shader.programId, "vertTangent"))
//        glEnableVertexAttribArray(locVertTangent)
//        glVertexAttribPointer(locVertTangent, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)
//
//        // vertex bitangent
//        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffers[4].glBufferName)
//        let locVertBitangent = GLuint(glGetAttribLocation(shader.programId, "vertBitangent"))
//        glEnableVertexAttribArray(locVertBitangent)
//        glVertexAttribPointer(locVertBitangent, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        // vertex index
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), submesh.elementBuffer.glBufferName)

        glBindVertexArray(0)

        // setup shadow buffer
        glGenBuffers(1, &shadowVBO)
        glBindVertexArray(VAO[1])
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), shadowVBO)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLKVector3>.size, vertices, GLenum(GL_STATIC_DRAW))
        let locShadowVertPos = GLuint(glGetAttribLocation(shadowShader.programId, "vertPos"))
        glEnableVertexAttribArray(locShadowVertPos)
//        print("loc vao1\(locShadowVertPos)")
        glVertexAttribPointer(locShadowVertPos, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLKVector3>.size), nil)

        glBindVertexArray(0)

        // preserve default FBO
        var defaultFBO = GLint()
        glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING_OES), &defaultFBO)

        glGenTextures(1, &depthTexture)
        glActiveTexture(GLenum(GL_TEXTURE2))
        glBindTexture(GLenum(GL_TEXTURE_2D), depthTexture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, 1024, 1024, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)

//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)

//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_COMPARE_MODE), GL_COMPARE_REF_TO_TEXTURE)
//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_COMPARE_FUNC), GL_LEQUAL)

        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

        glBindTexture(GLenum(GL_TEXTURE_2D), 0)

        // deal with shadow FBO and texture
        glGenFramebuffers(1, &FBO)
        glGenRenderbuffers(1, &RBO)

        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), RBO)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), 1024, 1024)

        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), FBO)
        glBindTexture(GLenum(GL_TEXTURE_2D), depthTexture)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), RBO)
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), depthTexture, 0)

//        glDrawBuffers(1, [GLenum(GL_NONE)])
        glDrawBuffers(1, [GLenum(GL_COLOR_ATTACHMENT0)])

        if glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE {
            os_log("Frame buffer not complete!", type: .error)
            switch Int32(glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))) {
            case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: print("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT")
            case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS: print("GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS")
            case GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES: print("GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES")
            case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES: print("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES")
            case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES: print("GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES")
            case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE: print("GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE")
            case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: print("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT")
            case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES: print("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES")
            default: print("Unknown")
            }
            exit(-1)
        } else {
            os_log("Complete!", type: .debug)
        }

        glBindTexture(GLenum(GL_TEXTURE_2D), 0)

        renderShadow()

        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(defaultFBO))
    }

    func setupShader() {
        self.shader = BaseEffect(vertexShader: "Shader/sofa_phong.vs", fragmentShader: "Shader/sofa_phong.fs")
        self.shadowShader = BaseEffect(vertexShader: "Shader/shadow.vs", fragmentShader: "Shader/shadow.fs")
        self.shadowBufferShader = BaseEffect(vertexShader: "Shader/shadow_buf.vs", fragmentShader: "Shader/shadow_buf.fs")
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

    private func getMVPMatrixForShadow(scale factor: Float) -> GLKMatrix4 {
        let scaleFactor = factor
        let model = GLKMatrix4MakeScale(scaleFactor, scaleFactor, scaleFactor)
        let view = GLKMatrix4MakeLookAt(0, 2, 0, 0, 0, 0, 0, 0, 1)
        let width: GLfloat = 1.0
        let nearZ: GLfloat = 0.001
        let farZ: GLfloat = 10.0
        let projection = GLKMatrix4MakeOrtho(-width, width, -width, width, nearZ, farZ)
        let in_MVP = projection * view * model
        return in_MVP
    }

    private func renderShadow() {
        glPushGroupMarkerEXT(0, "shadow")

        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), FBO)
        glViewport(0, 0, 1024, 1024)

//        glClearDepthf(1.0)
//        glClear(GLenum(GL_DEPTH_BUFFER_BIT))
        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GLenum(GL_COLOR_BUFFER_BIT) | GLenum(GL_DEPTH_BUFFER_BIT))

        glEnable(GLenum(GL_DEPTH_TEST))
        glDepthMask(GLboolean(GL_TRUE))

        glEnable(GLenum(GL_CULL_FACE))
        glCullFace(GLenum(GL_FRONT))

        // start draw
        shadowBufferShader.Activate()
        let mesh = meshes[0], submeshes = mesh.submeshes

        var in_MVP = getMVPMatrixForShadow(scale: 0.001)

        withUnsafePointer(to: &in_MVP) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                glUniformMatrix4fv(shadowShader.getUniformLocation("MVPMatrix"), 1, GLboolean(GL_FALSE), $0)
            }
        }

        glBindVertexArray(VAO[0])
        for submesh in submeshes {
            glDrawElements(GLenum(GL_TRIANGLES), submesh.elementCount, GLenum(GL_UNSIGNED_INT), UnsafeRawPointer(bitPattern: submesh.elementBuffer.offset))
        }
        // draw end

        glDisable(GLenum(GL_CULL_FACE))
        glPopGroupMarkerEXT()
    }

    func draw() {
        shader.Activate()

        glPushGroupMarkerEXT(0, "Sofa")

        glEnable(GLenum(GL_CULL_FACE))
        glCullFace(GLenum(GL_BACK))
        glBindVertexArray(VAO[0])
        let mesh = meshes[0], submeshes = mesh.submeshes
//        let elementCount = submeshes.reduce(0, {sum, e in
//            sum + e.elementCount
//        })
        for object in objects {
            let scaleFactor: Float = 0.001
//            let transform = object.initialTransform
//            let modelMatrix = transform * GLKMatrix4MakeScale(scaleFactor, scaleFactor, scaleFactor)
//            let viewMatrix = GLKMatrix4MakeLookAt(3, 0, 0, 0, 0, 0, 0, 1, 0)
//            let viewMatrix = GLKMatrix4Invert(self.viewMatrix, nil)
//            let viewMatrix = self.viewMatrix
//            let width = GLfloat(viewport.width)
//            var height = GLfloat(viewport.height)
//            if (height == 0.0) {
//                height = 1.0
//            }
//            let projectionMatrix = GLKMatrix4MakePerspective(60.0, width / height, 0.001, 10.0)
//            let projectionMatrix = self.projectionMatrix

//            var in_model = modelMatrix * GLKMatrix4MakeRotation(object.rotate, 0.0, 1.0, 0.0) * GLKMatrix4MakeScale(object.scaleBias, object.scaleBias, object.scaleBias)
            var in_model = object.transform * GLKMatrix4MakeScale(scaleFactor, scaleFactor, scaleFactor)
            var in_view = self.viewMatrix
            var in_proj = moveNearClipClose(projection: self.projectionMatrix)
            var in_modelview = GLKMatrix3(in_view * in_model)

            withUnsafePointer(to: &in_model) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(shader.getUniformLocation("modelMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }
            withUnsafePointer(to: &in_view) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(shader.getUniformLocation("viewMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }
            withUnsafePointer(to: &in_proj) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(shader.getUniformLocation("projectionMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }
            withUnsafePointer(to: &in_modelview) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 9) {
                    glUniformMatrix3fv(shader.getUniformLocation("modelViewMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }

            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), textures[0])
            glUniform1i(shader.getUniformLocation("mapKaSampler"), 0)
//            glActiveTexture(GLenum(GL_TEXTURE1))
//            glBindTexture(GLenum(GL_TEXTURE_2D), textures[1])
//            glUniform1i(shader.getUniformLocation("mapBumpSampler"), 1)

            glUniform1i(shader.getUniformLocation("selected"), object.selected ? 1 : 0)

//            for (index, submesh) in submeshes.enumerated() {
            for submesh in submeshes {
                glUniform1i(shader.getUniformLocation("hasTexture"), 1)

                glDrawElements(GLenum(GL_TRIANGLES), submesh.elementCount, GLenum(GL_UNSIGNED_INT), UnsafeRawPointer(bitPattern: submesh.elementBuffer.offset))
            }
        }
        glDisable(GLenum(GL_CULL_FACE))

        glPopGroupMarkerEXT()
        glPushGroupMarkerEXT(0, "shadow")

        glBindVertexArray(VAO[1])
        shadowShader.Activate()
        // draw shadow plane

        glActiveTexture(GLenum(GL_TEXTURE2))
        glBindTexture(GLenum(GL_TEXTURE_2D), depthTexture)
//        glGenerateMipmap(GLenum(GL_TEXTURE_2D))

        for object in objects {
            let scaleFactor: Float = 1.0
            let in_model = object.transform * GLKMatrix4MakeScale(scaleFactor, scaleFactor, scaleFactor)
            var in_MVP = moveNearClipClose(projection: self.projectionMatrix) * self.viewMatrix * in_model

            withUnsafePointer(to: &in_MVP) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(shadowShader.getUniformLocation("MVPMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }

            var shadow_MVP = getMVPMatrixForShadow(scale: 1)
            withUnsafePointer(to: &shadow_MVP) {
                $0.withMemoryRebound(to: GLfloat.self, capacity: 16) {
                    glUniformMatrix4fv(shadowShader.getUniformLocation("shadowMatrix"), 1, GLboolean(GL_FALSE), $0)
                }
            }

            glUniform1i(shadowShader.getUniformLocation("hasTexture"), 1)
            glUniform1i(shadowShader.getUniformLocation("depthTexture"), 2)

            glBindBuffer(GLenum(GL_ARRAY_BUFFER), shadowVBO)
            glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, GLsizei(vertices.count))

//            glInsertEventMarkerEXT(0, "com.apple.GPUTools.event.debug-frame")
        }
        glPopGroupMarkerEXT()
    }

//    func addBox(transform: GLKMatrix4) {
//        let object = ModelObject(transform)
//
//        if let lastObject = objects.last {
//            lastObject.selected = false
//        }
//        object.selected = true
//        selectedObject = object
//        objects.append(object)
//        os_log("Current objects: %d", type: .debug, objects.count)
//    }

    func addBox(translate: float3) {
        let object = ModelObject(translate)

        if let lastObject = objects.last {
            lastObject.selected = false
        }
        object.selected = true
        selectedObject = object
        objects.append(object)
        os_log("Current objects: %d", type: .debug, objects.count)
    }

    func rotate(by degCGFloat: CGFloat) {
        guard let object = selectedObject else { return }
        let deg = GLfloat(degCGFloat)
        object.rotate -= deg
    }

    func scale(by degCGFloat: CGFloat) {
        guard let object = selectedObject else { return }
        let deg = GLfloat(degCGFloat)
        object.scaleBias *= deg
    }
}

extension Boxes {
    func load(texture textureId: GLuint, from texturePath: String) {
        let texture = MDLTexture(named: texturePath)!
        let imageData = texture.texelDataWithTopLeftOrigin()!
        glBindTexture(GLenum(GL_TEXTURE_2D), textureId)

        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)

        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

        imageData.withUnsafeBytes { (ptr: UnsafePointer<GLubyte>) in
            let rawPtr = UnsafeRawPointer(ptr)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, texture.dimensions.x, texture.dimensions.y, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), rawPtr)
        }
        glGenerateMipmap(GLenum(GL_TEXTURE_2D))
    }

    func moveNearClipClose(projection in_matrix: GLKMatrix4) -> GLKMatrix4 {
        var matrix = in_matrix

        let a = matrix.m.10
        let b = matrix.m.14

//        let near = b / (a - 1)
        let near: Float = 0.001
        let far = b / (a + 1)

        let a_ = (near + far) / (near - far)
        let b_ = (2.0 * near * far) / (near - far)

        matrix.m.10 = a_
        matrix.m.14 = b_

        return matrix
    }
}
