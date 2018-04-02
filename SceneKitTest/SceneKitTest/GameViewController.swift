//
//  GameViewController.swift
//  SceneKitTest
//
//  Created by mac on 02.04.18.
//  Copyright © 2018 Dim Malysh. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    var scnView: SCNView!
    var scnScene: SCNScene!
    
    var cameraNode: SCNNode!
    var ball: SCNNode!
    var firstBox: SCNNode!
    var tempBox: SCNNode!
    
    var left = Bool()
    var firstBoxNumber = Int()
    var prevBoxNumber = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        createBox()
        createBall()
        setupCamera()
        setupLight()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if left == false {
            ball.removeAllActions()
            ball.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(-50.0, 0.0, 0.0), duration: 20.0)))
            left = true
        } else {
            ball.removeAllActions()
            ball.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(0.0, 0.0, -50.0), duration: 20.0)))
            left = false
        }
    }
    
    //MARK: - SCNSceneRendererDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let deleteBox = self.scnScene.rootNode.childNode(withName: "\(prevBoxNumber)", recursively: true)
        
        if deleteBox!.position.x > ball.position.x + 1 || deleteBox!.position.z > ball.position.z + 1 {
            prevBoxNumber += 1
            deleteBox?.removeFromParentNode()
            createBoxes()
        }
    }
    
    //MARK: - Helpers

    func setupView() {
        self.view.backgroundColor = UIColor.white
        
        scnView = self.view as! SCNView
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnView.delegate = self
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 3.0
        cameraNode.position = SCNVector3Make(20.0, 20.0, 20.0)
        cameraNode.eulerAngles = SCNVector3Make(-45.0, 45.0, 0)
        
        let constraint = SCNLookAtConstraint(target: ball)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
        scnScene.rootNode.addChildNode(cameraNode)
        
        ball.addChildNode(cameraNode)
    }
    
    func setupLight() {
        let firstLightNode = SCNNode()
        firstLightNode.light = SCNLight()
        firstLightNode.light?.type = .directional
        firstLightNode.eulerAngles = SCNVector3Make(-45.0, 45.0, 0.0)
        
        let secondLightNode = SCNNode()
        secondLightNode.light = SCNLight()
        secondLightNode.light?.type = .directional
        secondLightNode.eulerAngles = SCNVector3Make(45.0, 45.0, 0.0)
        
        scnScene.rootNode.addChildNode(firstLightNode)
        scnScene.rootNode.addChildNode(secondLightNode)
    }
    
    func createBall() {
        ball = SCNNode()
        
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIColor.cyan
        
        let ballGeometry = SCNSphere(radius: 0.2)
        ballGeometry.materials = [ballMaterial]
        
        ball.geometry = ballGeometry
        ball.position = SCNVector3Make(0.0, 1.1, 0.0)
        
        scnScene.rootNode.addChildNode(ball)
    }
    
    func createBox() {
        firstBoxNumber = 0
        prevBoxNumber = 0
        
        firstBox = SCNNode()
        firstBox.name = "\(firstBoxNumber)"
        
        let firstBoxGeometry = SCNBox(width: 1.0, height: 1.5, length: 1.0, chamferRadius: 0.0)
        firstBox.geometry = firstBoxGeometry
        firstBox.position = SCNVector3Make(0.0, 0.0, 0.0)
        
        let firstBoxMaterial = SCNMaterial()
        firstBoxMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0)
        firstBoxGeometry.materials = [firstBoxMaterial]
        
        scnScene.rootNode.addChildNode(firstBox)
        
        for _ in 0...6 {
            createBoxes()
        }
    }

    func createBoxes() {
        tempBox = SCNNode(geometry: firstBox.geometry)
        
        let prevBox = scnScene.rootNode.childNode(withName: "\(firstBoxNumber)", recursively: true)
        firstBoxNumber += 1
        tempBox.name = "\(firstBoxNumber)"
        
        let randomNumber = arc4random() % 2
        switch randomNumber {
        case 0:
            tempBox.position = SCNVector3Make((prevBox?.position.x)! - firstBox.scale.x, (prevBox?.position.y)!, (prevBox?.position.z)!)
            break
        case 1:
            tempBox.position = SCNVector3Make((prevBox?.position.x)!, (prevBox?.position.y)!, (prevBox?.position.z)! - firstBox.scale.z)
            break
        default:
            break
        }
        
        self.scnScene.rootNode.addChildNode(tempBox)
    }
    
}
