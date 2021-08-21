//
//  ViewController.swift
//  HiPhone
//
//  Created by Tapan Patel on 21/08/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        // Set the view's delegate
        sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Create the gesture recognizer:
        //        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        //        sceneView.addGestureRecognizer(panRecognizer)
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/EmptyScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    var selectedNode : SCNNode?
    var phoneNode : SCNNode?
    
    
    
    @objc func handleTap(sender:UITapGestureRecognizer)
    {
        let sceneViewTappedOn = sender.view as! SCNView
        let touchCoordinates = sender.location(in:sceneViewTappedOn)
        let hittest = sceneViewTappedOn.hitTest(touchCoordinates)
        if hittest.isEmpty
        {
            
            // print("scene")
        }
        else
        {
            let result = hittest.first!
            print(result)
            _ = result.node.position
            let name = result.node.name
            
            print(name)
        }
        
    }
    
    
    @objc func handlePinch(gesture: UIPinchGestureRecognizer){
        var pinchScale = gesture.scale
        pinchScale = round(pinchScale * 1000) / 1000.0
        let sceneViewTappedOn = gesture.view as! SCNView
        let touchCoordinates = gesture.location(in:sceneViewTappedOn)
        let hittest = sceneViewTappedOn.hitTest(touchCoordinates)
        if !hittest.isEmpty
        {
            let result = hittest.first!
            //            print(result)
            //            _ = result.node.position
            let name = result.node.name
            print("\(name) is being pinched")
            if (gesture.state == .changed) {
                let pinchScaleX = Float(gesture.scale) *  result.node.scale.x
                let pinchScaleY =  Float(gesture.scale) * result.node.scale.y
                let pinchScaleZ =  Float(gesture.scale) * result.node.scale.z
                result.node.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
                gesture.scale=1
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "Photos", bundle: Bundle.main)
        else {
            print("NO Images Available")
            return
        }
        configuration.trackingImages = trackedImages
        configuration.maximumNumberOfTrackedImages = 1
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        DispatchQueue.main.async {
            
            //fetch video
            let videofile = "HiPhone.mp4"
            let file = videofile.components(separatedBy: ".")
            guard let path = Bundle.main.path(forResource: file[0], ofType:file[1]) else {
                debugPrint( "\(file.joined(separator: ".")) not found")
                return
            }
            
            if let imageAnchor = anchor as? ARImageAnchor,self.phoneNode == nil
            {
                print("running renderer")
                let videoItem = AVPlayerItem(url: URL(fileURLWithPath: path))
                let player = AVPlayer(playerItem: videoItem)
                //initialize video node with avplayer
                let videoNode = SKVideoNode(avPlayer: player)
                player.play()
                // add observer when our player.currentItem finishes player, then start playing from the beginning
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
                    player.seek(to: CMTime.zero)
                    player.play()
                    print("Looping Video")
                }
                
                // set the size (just a rough one will do)
                let videoScene = SKScene(size: CGSize(width: 640, height: 1136))
                // center our video to the size of our video scene
                videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
                // invert our video so it does not look upside down
                videoNode.yScale = -1.0
                // add the video to our scene
                videoScene.addChild(videoNode)
                
                let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
                plane.firstMaterial?.diffuse.contents = videoScene
                
                
                let planeNode = SCNNode(geometry : plane)
                planeNode.scale.x = 0.8
                planeNode.scale.y = 0.7
                planeNode.eulerAngles.x = -.pi/2
                planeNode.name = "HiPhone"
                
                self.phoneNode = planeNode
                self.phoneNode?.name = "Phone Node"
                node.addChildNode(self.phoneNode!)
            }
        }
        
        return node
    }
}
