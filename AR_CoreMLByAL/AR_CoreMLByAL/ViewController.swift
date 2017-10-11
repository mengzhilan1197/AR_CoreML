//
//  ViewController.swift
//  AR_CoreMLByAL
//
//  Created by ailin on 2017/10/10.
//  Copyright © 2017年 北京电小二网络科技有限公司. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    var hitResult : ARHitTestResult!
    var resnetModel = Resnet50()
    var visionRequest = [VNRequest]()
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //设置代理
        sceneView.delegate = self
        //显示
        sceneView.showsStatistics = true
        //创建场景
        let scene = SCNScene()
        //展示场景
        sceneView.scene = scene
    
        //注册手势
        registerTapScreenRecognizer()
    }
    
    //注册一个点击屏幕的手势
    func registerTapScreenRecognizer(){
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapScreen))
        self.sceneView.addGestureRecognizer(tapGes)
    }
    
    //点击屏幕
    @objc func tapScreen(tapGes: UITapGestureRecognizer){
        let sceneView = tapGes.view as! ARSCNView//获得点击的view(截图)
        let touchLocation = self.sceneView.center
        guard let currentFrame = sceneView.session.currentFrame else{ return }
        let hitResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        if hitResults.isEmpty{ return }
        guard let hitResult = hitResults.first else {return}
        self.hitResult = hitResult
        
        let pixelBuffer = currentFrame.capturedImage//把图片丢进图片缓冲区
        performVisionRequest(pixelBuffer: pixelBuffer)
    }
    
    func performVisionRequest(pixelBuffer:CVPixelBuffer) {
        let visionModel = try! VNCoreMLModel(for: self.resnetModel.model)
        
        let request = VNCoreMLRequest(model: visionModel) { (request, error) in
            if error != nil {return}
            guard let observations = request.results else{return}
            let observation = observations.first as! VNClassificationObservation//点击一瞬间的画面
            
            DispatchQueue.main.async {
                self.displayPredictions(text: observation.identifier)
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        self.visionRequest = [request]
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        
        DispatchQueue.global().async {
            try! imageRequestHandler.perform(self.visionRequest)
        }
    }
    
    //展示3d模型
    func displayPredictions(text:String) {
        let node = creatText(text: text)
        node.position = SCNVector3(self.hitResult.worldTransform.columns.3.x,
        self.hitResult.worldTransform.columns.3.y,
        self.hitResult.worldTransform.columns.3.z)
        
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    //创建节点
    func creatText(text:String) -> SCNNode {
        let parrentNode = SCNNode()
        let sphere = SCNSphere(radius: 0.01)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.red
        sphere.firstMaterial = sphereMaterial
        let sphereNode = SCNNode(geometry: sphere)
        parrentNode.addChildNode(sphereNode)
        
        
        let textGeo = SCNText(string: text, extrusionDepth: 0)
        textGeo.alignmentMode = kCAAlignmentCenter
        textGeo.firstMaterial?.diffuse.contents = UIColor.red
        textGeo.firstMaterial?.specular.contents = UIColor.white
        textGeo.firstMaterial?.isDoubleSided = true
        
        let font = UIFont(name: "Futura", size: 0.15)
        textGeo.font = font
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        parrentNode.addChildNode(textNode)
        
        return parrentNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //这里面做全局追踪
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
