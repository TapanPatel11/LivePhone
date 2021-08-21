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
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        sceneView.addGestureRecognizer(panRecognizer)
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/EmptyScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    var selectedNode : SCNNode?
    var phoneNode : SCNNode?
    
    //store previous coordinates from hittest to compare with current ones
    var PCoordx: Float = 0.0
    var PCoordy: Float = 0.0
    var PCoordz: Float = 0.0

    @objc func panGesture(_ sender:UIPanGestureRecognizer)
    {
        switch sender.state {
            case .began:
                let hitNode = self.sceneView.hitTest(sender.location(in: self.sceneView),
                                                     options: nil)
                self.PCoordx = (hitNode.first?.worldCoordinates.x)!
                self.PCoordy = (hitNode.first?.worldCoordinates.y)!
                self.PCoordz = (hitNode.first?.worldCoordinates.z)!
            case .changed:
                // when you start to pan in screen with your finger
                // hittest gives new coordinates of touched location in sceneView
                // coord-pcoord gives distance to move or distance paned in sceneview
                let hitNode = sceneView.hitTest(sender.location(in: sceneView), options: nil)
                if let coordx = hitNode.first?.worldCoordinates.x,
                    let coordy = hitNode.first?.worldCoordinates.y,
                    let coordz = hitNode.first?.worldCoordinates.z {
                    let action = SCNAction.moveBy(x: CGFloat(coordx - PCoordx),
                                                  y: 0,
                                                  z: CGFloat(coordz - PCoordz),
                                                  duration: 0.0)
                    self.phoneNode?.runAction(action)

                    self.PCoordx = coordx
                    self.PCoordy = coordy
                    self.PCoordz = coordz
                }

                sender.setTranslation(CGPoint.zero, in: self.sceneView)
            case .ended:
                print(phoneNode?.position)
                self.PCoordx = 0.0
                self.PCoordy = 0.0
                self.PCoordz = 0.0
            default:
                break
            }
    }
    
    
    
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
//            print(result)
            _ = result.node.position
            let name = result.node.name
            
//            print(name)
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
                
                plane.cornerRadius = 0.001
                let planeNode = SCNNode(geometry : plane)
                planeNode.scale.x = 0.84
                planeNode.scale.y = 0.72
                planeNode.position.x = planeNode.position.x - 0.0003
                planeNode.position.z = planeNode.position.z + 0.001


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
