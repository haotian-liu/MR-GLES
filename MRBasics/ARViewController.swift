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

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messagePanel: UIVisualEffectView!

    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(gesture)
        self.view.isUserInteractionEnabled = true

        setupUIControls()
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        super.glkView(view, drawIn: rect)
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
            os_log("Found %d planes", count)
        } else {
            os_log("No plane found")
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
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

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // called after an anchor is added to the session
    }
}
