//
//  ARViewController.swift
//  MRBasics
//
//  Created by Haotian on 2018/1/1.
//  Copyright © 2018年 Haotian. All rights reserved.
//

import GLKit
import ARKit
import os.log

class ARViewController: ViewController {
    var objects = [ARAnchor:Int]()
    var textManager: TextManager!
    var boxes = Boxes()

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messagePanel: UIVisualEffectView!

    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(gesture)
        self.view.isUserInteractionEnabled = true

        setupUIControls()
        boxes.setupShader()
        boxes.setupBuffer()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        super.glkView(view, drawIn: rect)

        glViewport(GLint(self.viewport.origin.x), GLint(self.viewport.origin.y), GLsizei(self.viewport.size.width), GLsizei(self.viewport.size.height))
        glDepthMask(GLboolean(GL_TRUE))
        glEnable(GLenum(GL_DEPTH_TEST))
        boxes.draw()
    }

    override func session(_ session: ARSession, didUpdate frame: ARFrame) {
        super.session(session, didUpdate: frame)
        boxes.updateMatrix(type: .view, mat: self.viewMatrix)
        boxes.viewport = self.viewport
    }

    override func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        super.session(session, cameraDidChangeTrackingState: camera)
        boxes.updateMatrix(type: .projection, mat: self.projectionMatrix)

        // change text manager status
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)

        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
    }
}

extension ARViewController {
    func setupUIControls() {
        textManager = TextManager(viewController: self)

        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let currentFrame = self.arSession.currentFrame
        let point = gesture.location(in: gesture.view)
        let relativePoint = CGPoint(x: point.y / (gesture.view?.frame.size.height)!, y: point.x / (gesture.view?.frame.size.width)!)
//        os_log("tap point relative (%f, %f)\n", relativePoint.x, relativePoint.y)
        let results = currentFrame?.hitTest(relativePoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        if let count = results?.count, count != 0 {
            for result in results! {
//                let transform = GLKMatrix4(result.worldTransform) * GLKMatrix4MakeScale(0.05, 0.05, 0.05)
                let transform = GLKMatrix4(result.worldTransform)
                let anchor = ARAnchor(transform: result.worldTransform)
                self.arSession.add(anchor: anchor)
                boxes.addBox(transform: transform)
            }
            os_log("Found %d planes", count)
        } else {
            os_log("No plane found, start feature test")
//            let featureHitTestResult = hitTest
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // called after an anchor is added to the session
    }
}

//extension ARViewController {
//    // Extension for more AR Feature detection stuff
//
//    // MARK: - Types
//
//    struct HitTestRay {
//        var origin: float3
//        var direction: float3
//
//        func intersectionWithHorizontalPlane(atY planeY: Float) -> float3? {
//            let normalizedDirection = simd_normalize(direction)
//
//            // Special case handling: Check if the ray is horizontal as well.
//            if normalizedDirection.y == 0 {
//                if origin.y == planeY {
//                    /*
//                     The ray is horizontal and on the plane, thus all points on the ray
//                     intersect with the plane. Therefore we simply return the ray origin.
//                     */
//                    return origin
//                } else {
//                    // The ray is parallel to the plane and never intersects.
//                    return nil
//                }
//            }
//
//            /*
//             The distance from the ray's origin to the intersection point on the plane is:
//             (`pointOnPlane` - `rayOrigin`) dot `planeNormal`
//             --------------------------------------------
//             direction dot planeNormal
//             */
//
//            // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
//            let distance = (planeY - origin.y) / normalizedDirection.y
//
//            // Do not return intersections behind the ray's origin.
//            if distance < 0 {
//                return nil
//            }
//
//            // Return the intersection point.
//            return origin + (normalizedDirection * distance)
//        }
//
//    }
//
//    struct FeatureHitTestResult {
//        var position: float3
//        var distanceToRayOrigin: Float
//        var featureHit: float3
//        var featureDistanceToHitResult: Float
//    }
//
//
//    // MARK: - Hit Tests
//
//    func hitTestRayFromScreenPosition(_ point: CGPoint) -> HitTestRay? {
//        guard let frame = self.arSession.currentFrame else { return nil }
//
//        let cameraPos = frame.camera.transform.translation
//
//        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
//        let positionVec = float3(x: Float(point.x), y: Float(point.y), z: 1.0)
//        let screenPosOnFarClippingPlane = unprojectPoint(positionVec)
//
//        let rayDirection = simd_normalize(screenPosOnFarClippingPlane - cameraPos)
//        return HitTestRay(origin: cameraPos, direction: rayDirection)
//    }
//
//    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: float3) -> float3? {
//        guard let ray = hitTestRayFromScreenPosition(point) else { return nil }
//
//        // Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
//        if ray.direction.y > -0.03 {
//            return nil
//        }
//
//        /*
//         Return the intersection of a ray from the camera through the screen position
//         with a horizontal plane at height (Y axis).
//         */
//        return ray.intersectionWithHorizontalPlane(atY: pointOnPlane.y)
//    }
//
//    func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float, minDistance: Float = 0, maxDistance: Float = Float.greatestFiniteMagnitude, maxResults: Int = 1) -> [FeatureHitTestResult] {
//
//        guard let features = self.arSession.currentFrame?.rawFeaturePoints, let ray = hitTestRayFromScreenPosition(point) else {
//            return []
//        }
//
//        let maxAngleInDegrees = min(coneOpeningAngleInDegrees, 360) / 2
//        let maxAngle = (maxAngleInDegrees / 180) * .pi
//
//        let results = features.points.flatMap { featurePosition -> FeatureHitTestResult? in
//            let originToFeature = featurePosition - ray.origin
//
//            let crossProduct = simd_cross(originToFeature, ray.direction)
//            let featureDistanceFromResult = simd_length(crossProduct)
//
//            let hitTestResult = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
//            let hitTestResultDistance = simd_length(hitTestResult - ray.origin)
//
//            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
//                // Skip this feature - it is too close or too far away.
//                return nil
//            }
//
//            let originToFeatureNormalized = simd_normalize(originToFeature)
//            let angleBetweenRayAndFeature = acos(simd_dot(ray.direction, originToFeatureNormalized))
//
//            if angleBetweenRayAndFeature > maxAngle {
//                // Skip this feature - is is outside of the hit test cone.
//                return nil
//            }
//
//            // All tests passed: Add the hit against this feature to the results.
//            return FeatureHitTestResult(position: hitTestResult,
//                                        distanceToRayOrigin: hitTestResultDistance,
//                                        featureHit: featurePosition,
//                                        featureDistanceToHitResult: featureDistanceFromResult)
//        }
//
//        // Sort the results by feature distance to the ray origin.
//        let sortedResults = results.sorted { $0.distanceToRayOrigin < $1.distanceToRayOrigin }
//
//        let remainingResults = maxResults > 0 ? Array(sortedResults.prefix(maxResults)) : sortedResults
//
//        return Array(remainingResults)
//    }
//
//    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
//        guard let features = self.arSession.currentFrame?.rawFeaturePoints,
//            let ray = hitTestRayFromScreenPosition(point) else {
//                return []
//        }
//
//        /*
//         Find the feature point closest to the hit test ray, then create
//         a hit test result by finding the point on the ray closest to that feature.
//         */
//        let possibleResults = features.points.map { featurePosition in
//            return FeatureHitTestResult(featurePoint: featurePosition, ray: ray)
//        }
//        let closestResult = possibleResults.min(by: { $0.featureDistanceToHitResult < $1.featureDistanceToHitResult })!
//        return [closestResult]
//    }
//
//}

