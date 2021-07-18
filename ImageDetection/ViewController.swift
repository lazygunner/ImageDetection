//
//  ViewController.swift
//  ImageDetection
//
//  Created by GUNNER on 2020/2/20.
//  Copyright © 2020 GUNNER. All rights reserved.
//

import ARKit
import SceneKit
import UIKit
import SceneKit.ModelIO

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: Properties
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    // 当修改SceneKit节点图像时线程安全的串行队列
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".serialSceneKitQueue")
    
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // 关联 status view controller 回调
        statusViewController.restartExperienceHandler = {
            [unowned self] in
            self.restartExperience()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 阻止平面变暗来防止终端AR体验
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 开始AR体验
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    // MARK: - session management
    
    /// 放置在一个重启过程中执行另一个重启操作
    var isRestartAvailable = true
    
    /// 创建一个新的AR配置项来运行 session
    /// - Tag: ARReferenceImage - Loading
    func resetTracking() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("资源目录下未找到该资源")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("请观察周边来检测图像", inSeconds: 7.5, messageType: .contentPlacement)
    }
    
    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let referrenceImage = imageAnchor.referenceImage
        
        updateQueue.async {
            
            let plane = SCNPlane(width: referrenceImage.physicalSize.width, height: referrenceImage.physicalSize.height)
            
            let planeNode = SCNNode(geometry: plane)
            
            /*
             SCNPlane 在其坐标系中是垂直方向的，但是 ARImageAnchor 假设图像在其空间中是水平方向。所以反转该平面以匹配
             */
            
            planeNode.eulerAngles.x = -.pi / 2
            
            /*
             图像锚点在初次检测后不会再被追踪，所以创建一个动画来限制展示平面消失的时间
             */
                
            planeNode.runAction(self.imageHighlightAction)
            
            node.addChildNode(planeNode)
            
            /*
              增加 3D 对象
             */
            guard let urlPath = Bundle.main.url(forResource: "obj47", withExtension: "usdz") else {
                NSLog("load obj47 failed")
                return
            }
            let mdlAsset = MDLAsset(url: urlPath)
            // you can load the textures on an MDAsset so it's not white
            mdlAsset.loadTextures()
            
            let asset = mdlAsset.object(at: 0) // extract first object
            let assetNode = SCNNode(mdlObject: asset)
            assetNode.eulerAngles.x = -.pi / 2
            assetNode.runAction(.moveBy(x: 0, y: 0, z: 30, duration: 1))
            assetNode.scale = SCNVector3(100, 100, 100)
            assetNode.runAction(.repeatForever(.rotateBy(x: 0, y: 0, z: 0.5, duration: 0.3)))
            node.addChildNode(assetNode)

        }
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
    


}

