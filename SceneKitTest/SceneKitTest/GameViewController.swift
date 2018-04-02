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

struct bodyType {
    static let Ball = 0x1 << 1
    static let Coin = 0x1 << 2
}

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    var scnView: SCNView!
    var scnScene = SCNScene()
    
    var cameraNode = SCNNode()
    var ball: SCNNode!
    var firstBox: SCNNode!
    var tempBox: SCNNode!
    
    var scoreLabel = UILabel()
    var highScoreLabel = UILabel()
    
    var left = Bool()
    var correctPath = Bool()
    var isDead = Bool()
    
    var firstBoxNumber = Int()
    var prevBoxNumber = Int()
    var score = Int()
    var highScore = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        scnScene.physicsWorld.contactDelegate = self
        
        highScoreLabel = UILabel(frame: CGRect(origin: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5), size: CGSize(width: self.view.frame.width, height: 100.0)))
        highScoreLabel.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 - self.view.frame.height / 2.5)
        highScoreLabel.textAlignment = .center
        highScoreLabel.text = "Highscore: \(highScore)"
        highScoreLabel.textColor = UIColor.red
        self.view.addSubview(highScoreLabel)
        
        scoreLabel = UILabel(frame: CGRect(origin: CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5), size: CGSize(width: self.view.frame.width, height: 100.0)))
        scoreLabel.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5)
        scoreLabel.textAlignment = .center
        scoreLabel.text = "Score: \(score)"
        scoreLabel.textColor = UIColor.red
        self.view.addSubview(scoreLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDead == false {
            self.performSelector(onMainThread: #selector(GameViewController.updateScoreLabels), with: nil, waitUntilDone: false)
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
    }
    
    //MARK: - SCNSceneRendererDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isDead == false {
            let deleteBox = self.scnScene.rootNode.childNode(withName: "\(prevBoxNumber)", recursively: true)
            let currentBox = self.scnScene.rootNode.childNode(withName: "\(prevBoxNumber + 1)", recursively: true)
            
            if deleteBox!.position.x > ball.position.x + 1 || deleteBox!.position.z > ball.position.z + 1 {
                prevBoxNumber += 1
                fadeOut(node: deleteBox!)
                createBoxes()
            }
            
            if ball.position.x > currentBox!.position.x - 0.5 && ball.position.x < currentBox!.position.x + 0.5 ||
                ball.position.z > currentBox!.position.z - 0.5 && ball.position.z < currentBox!.position.z + 0.5 {
                // ball is on platform
            } else {
                ballDies()
                isDead = true
            }
        }
    }
    
    //MARK: - SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.physicsBody?.categoryBitMask == bodyType.Coin && nodeB.physicsBody?.categoryBitMask == bodyType.Ball {
            nodeA.removeFromParentNode()
            addScore()
        } else if nodeA.physicsBody?.categoryBitMask == bodyType.Ball && nodeB.physicsBody?.categoryBitMask == bodyType.Coin {
            nodeB.removeFromParentNode()
            addScore()
        }
    }
    
    //MARK: - Helpers

    func setup() {
        setupView()
        setupScene()
        createBox()
        createBall()
        setupCamera()
        setupLight()
    }
    
    func updateScoreLabels() {
        scoreLabel.text = "Score: \(score)"
        highScoreLabel.text = "Highscore: \(highScore)"
    }
    
    func addScore() {
        score += 1
        
        self.performSelector(onMainThread: #selector(GameViewController.updateScoreLabels), with: nil, waitUntilDone: false)
        
        if score > highScore {
            highScore = score
            let scoreDefaults = UserDefaults.standard
            scoreDefaults.set(highScore, forKey: "highScore")
        }
    }
    
    func addCoin(box: SCNNode) {
        scnScene.physicsWorld.gravity = SCNVector3Make(0.0, 0.0, 0.0)
        
        let rotate = SCNAction.rotate(by: CGFloat(M_PI * 2), around: SCNVector3Make(0.0, 0.5, 0.0), duration: 0.5)
        
        let randomCoin = arc4random() % 8
        if randomCoin == 3 {
            let addCoinScene = SCNScene(named: "Coin.dae")
            let coin = addCoinScene?.rootNode.childNode(withName: "Coin", recursively: true)
            coin?.position = SCNVector3Make(box.position.x, box.position.y + 1, box.position.z)
            coin?.scale = SCNVector3Make(0.2, 0.2, 0.2)
            
            coin?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: coin!, options: nil))
            coin?.physicsBody?.categoryBitMask = bodyType.Coin
            coin?.physicsBody?.collisionBitMask = bodyType.Ball
            coin?.physicsBody?.contactTestBitMask = bodyType.Ball
            coin?.physicsBody?.isAffectedByGravity = false
            
            scnScene.rootNode.addChildNode(coin!)
            coin?.runAction(SCNAction.repeatForever(rotate))
            
            fadeIn(node: coin!)
        }
    }
    
    func fadeIn(node: SCNNode) {
        node.opacity = 0.0
        node.runAction(SCNAction.fadeIn(duration: 1.0))
    }
    
    func fadeOut(node: SCNNode) {
        let move = SCNAction.move(to: SCNVector3Make(node.position.x, node.position.y - 2.0, node.position.z), duration: 0.5)
        node.runAction(move)
        node.runAction(SCNAction.fadeOut(duration: 1.0))
    }
    
    func ballDies() {
        ball.runAction(SCNAction.move(to: SCNVector3Make(ball.position.x, ball.position.y - 10.0, ball.position.z), duration: 1.0))
        
        let wait = SCNAction.wait(duration: 0.5)
        
        let removeBall = SCNAction.run { (node) in
            self.scnScene.rootNode.enumerateChildNodes({ (node, stop) in
                node.removeFromParentNode()
            })
        }
        
        let createScene = SCNAction.run { (node) in
            self.setup()
        }
        
        let sequence = SCNAction.sequence([wait, removeBall, createScene])
        ball.runAction(sequence)
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.white
        scnView = self.view as! SCNView
    }
    
    func setupScene() {
        scnView.scene = scnScene
        scnView.delegate = self
    }
    
    func setupCamera() {
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
        
        ball.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: ball!, options: nil))
        ball.physicsBody?.categoryBitMask = bodyType.Ball
        ball.physicsBody?.collisionBitMask = bodyType.Coin
        ball.physicsBody?.contactTestBitMask = bodyType.Coin
        ball.physicsBody?.isAffectedByGravity = false
        
        scnScene.rootNode.addChildNode(ball)
    }
    
    func createBox() {
        let scoreDefaults = UserDefaults.standard
        if scoreDefaults.integer(forKey: "highScore") != 0 {
            highScore = scoreDefaults.integer(forKey: "highScore")
        } else {
            highScore = 0
        }
        
        firstBoxNumber = 0
        prevBoxNumber = 0
        correctPath = true
        isDead = false
        
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
            if correctPath == true {
                correctPath = false
                left = false
            }
            break
            
        case 1:
            tempBox.position = SCNVector3Make((prevBox?.position.x)!, (prevBox?.position.y)!, (prevBox?.position.z)! - firstBox.scale.z)
            if correctPath == true {
                correctPath = false
                left = true
            }
            break
            
        default:
            break
        }
        
        self.scnScene.rootNode.addChildNode(tempBox)
        
        addCoin(box: tempBox)
        fadeIn(node: tempBox)
    }
    
}
