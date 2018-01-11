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

        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tapGesture)

        let rotateGesture = UIRotationGestureRecognizer.init(target: self, action: #selector(self.handleRotate(_:)))
        self.view.addGestureRecognizer(rotateGesture)

        let pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(self.handlePinch(_:)))
        self.view.addGestureRecognizer(pinchGesture)

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

//        let baseIntensity: CGFloat = 40
//        let lightEstimateIntensity: CGFloat
//        if let lightEstimate = session.currentFrame?.lightEstimate {
//            lightEstimateIntensity = lightEstimate.ambientIntensity / baseIntensity
//        } else {
//            lightEstimateIntensity = baseIntensity
//        }

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

    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.view != nil else { return }

        if gesture.state == .began || gesture.state == .changed {
            boxes.rotate(by: gesture.rotation)
            gesture.rotation = 0
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.view != nil else { return }

        if gesture.state == .began || gesture.state == .changed {
            boxes.scale(by: gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let currentFrame = self.arSession.currentFrame
        let point = gesture.location(in: gesture.view)
        let relativePoint = CGPoint(x: point.y / (gesture.view?.frame.size.height)!, y: point.x / (gesture.view?.frame.size.width)!)
        let adjustedPoint = CGPoint(x: relativePoint.y * self.viewport.size.width, y: (1.0 - relativePoint.x) * self.viewport.size.height)
//        print("Adjusted point: \(adjustedPoint.x), \(adjustedPoint.y)")
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
            /*
                2. Collect more information about the environment by hit testing against
                the feature point cloud, but do not return the result yet.
             */
            let featureHitTestResult = hitTestWithFeatures(adjustedPoint, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0).first
            let featurePosition = featureHitTestResult?.position
            if let featurePosition = featurePosition {
                os_log("Feature point detection success!")
                let transform = GLKMatrix4MakeTranslation(featurePosition.x, featurePosition.y, featurePosition.z)

//                let anchor = ARAnchor(transform: transform)
//                self.arSession.add(anchor: anchor)
                boxes.addBox(transform: transform)
            } else {
                // last resort
                let unfilteredFeatureHitTestResults = hitTestWithFeatures(adjustedPoint)
                if let result = unfilteredFeatureHitTestResults.first?.position {
                    os_log("Feature point unfiltered success!")
                    let transform = GLKMatrix4MakeTranslation(result.x, result.y, result.z)
                    boxes.addBox(transform: transform)
                } else {
                    os_log("Feature point failed!")
                }
            }
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // called after an anchor is added to the session
    }
}

extension ARViewController {
    // Extension for more AR Feature detection stuff

    struct HitTestRay {
        var origin: float3
        var direction: float3

        func intersectionWithHorizontalPlane(atY planeY: Float) -> float3? {
            let normalizedDirection = simd_normalize(direction)

            // Special case handling: Check if the ray is horizontal as well.
            if normalizedDirection.y == 0 {
                if origin.y == planeY {
                    /*
                     The ray is horizontal and on the plane, thus all points on the ray
                     intersect with the plane. Therefore we simply return the ray origin.
                     */
                    return origin
                } else {
                    // The ray is parallel to the plane and never intersects.
                    return nil
                }
            }

            /*
             The distance from the ray's origin to the intersection point on the plane is:
             (`pointOnPlane` - `rayOrigin`) dot `planeNormal`
             --------------------------------------------
             direction dot planeNormal
             */

            // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
            let distance = (planeY - origin.y) / normalizedDirection.y

            // Do not return intersections behind the ray's origin.
            if distance < 0 {
                return nil
            }

            // Return the intersection point.
            return origin + (normalizedDirection * distance)
        }

    }

    struct FeatureHitTestResult {
        var position: float3
        var distanceToRayOrigin: Float
        var featureHit: float3
        var featureDistanceToHitResult: Float
    }

    // MARK: - Hit Tests

    func hitTestRayFromScreenPosition(_ point: CGPoint) -> HitTestRay? {
        guard let frame = self.arSession.currentFrame else { return nil }

        let cameraPos = frame.camera.transform.translation

        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = GLKVector3(Float(point.x), Float(point.y), 1.0)
//        let screenPosOnFarClippingPlane = unprojectPoint(positionVec)
        var ptr: [Int32] = [Int32(self.viewport.origin.x), Int32(self.viewport.origin.y), Int32(self.viewport.size.width), Int32(self.viewport.size.height)]
        let screenPosOnFarClippingPlane = GLKMathUnproject(positionVec, self.viewMatrix, self.projectionMatrix, &ptr[0], nil)

        let rayDirection = simd_normalize(float3(screenPosOnFarClippingPlane) - cameraPos)
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }

    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: float3) -> float3? {
        guard let ray = hitTestRayFromScreenPosition(point) else { return nil }

        // Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
        if ray.direction.y > -0.03 {
            return nil
        }

        /*
         Return the intersection of a ray from the camera through the screen position
         with a horizontal plane at height (Y axis).
         */
        return ray.intersectionWithHorizontalPlane(atY: pointOnPlane.y)
    }

    func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float, minDistance: Float = 0, maxDistance: Float = Float.greatestFiniteMagnitude, maxResults: Int = 1) -> [FeatureHitTestResult] {

        guard let features = self.arSession.currentFrame?.rawFeaturePoints, let ray = hitTestRayFromScreenPosition(point) else {
            return []
        }

//        print("Hit test on point: \(point.x) \(point.y)")

        let maxAngleInDegrees = min(coneOpeningAngleInDegrees, 360) / 2
        let maxAngle = (maxAngleInDegrees / 180) * .pi

        let results = features.points.flatMap { featurePosition -> FeatureHitTestResult? in
            let originToFeature = featurePosition - ray.origin

            let crossProduct = simd_cross(originToFeature, ray.direction)
            let featureDistanceFromResult = simd_length(crossProduct)

            let hitTestResult = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
            let hitTestResultDistance = simd_length(hitTestResult - ray.origin)

            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                // Skip this feature - it is too close or too far away.
                return nil
            }

            let originToFeatureNormalized = simd_normalize(originToFeature)
            let angleBetweenRayAndFeature = acos(simd_dot(ray.direction, originToFeatureNormalized))

            if angleBetweenRayAndFeature > maxAngle {
                // Skip this feature - is is outside of the hit test cone.
                return nil
            }

            // All tests passed: Add the hit against this feature to the results.
            return FeatureHitTestResult(position: hitTestResult,
                                        distanceToRayOrigin: hitTestResultDistance,
                                        featureHit: featurePosition,
                                        featureDistanceToHitResult: featureDistanceFromResult)
        }

        // Sort the results by feature distance to the ray origin.
        let sortedResults = results.sorted { $0.distanceToRayOrigin < $1.distanceToRayOrigin }

        let remainingResults = maxResults > 0 ? Array(sortedResults.prefix(maxResults)) : sortedResults

        return remainingResults
    }

    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
        guard let features = self.arSession.currentFrame?.rawFeaturePoints,
            let ray = hitTestRayFromScreenPosition(point) else {
                return []
        }

        let possibleResults = features.points.map { featurePosition in
            return FeatureHitTestResult(featurePoint: featurePosition, ray: ray)
        }
        let closestResult = possibleResults.min(by: { $0.featureDistanceToHitResult < $1.featureDistanceToHitResult })!
        return [closestResult]
    }

}

extension ARViewController.FeatureHitTestResult {
    init(featurePoint: float3, ray: ARViewController.HitTestRay) {
        self.featureHit = featurePoint
        
        let originToFeature = featurePoint - ray.origin
        self.position = ray.origin + (ray.direction * simd_dot(ray.direction, originToFeature))
        self.distanceToRayOrigin = simd_length(self.position - ray.origin)
        self.featureDistanceToHitResult = simd_length(simd_cross(originToFeature, ray.direction))
    }
}

