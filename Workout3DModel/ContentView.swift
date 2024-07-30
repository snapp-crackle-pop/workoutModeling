//
//  ContentView.swift
//  Workout3DModel
//
//  Created by Jacob Snapp on 7/30/24.
//

//
//  ContentView.swift
//  Workout3DModel
//
//  Created by Jacob Snapp on 7/30/24.
//

import SwiftUI
import SceneKit

struct ContentView: View {
    var body: some View {
        USDZSceneView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct USDZSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        
        // Create a new scene
        let scene = SCNScene()

        // Load the USDZ file
        if let usdzScene = SCNScene(named: "finalanatomy.usdz") {
            let usdzNode = SCNNode()
            for child in usdzScene.rootNode.childNodes {
                applyRandomColors(to: child)
                usdzNode.addChildNode(child)
            }
            
            // Compute the bounding box of the usdzNode
            let (min, max) = usdzNode.boundingBox
            let size = SCNVector3(
                x: max.x - min.x,
                y: max.y - min.y,
                z: max.z - min.z
            )
            let boundingBoxCenter = SCNVector3(
                x: (max.x + min.x) / 2,
                y: (max.y + min.y) / 2,
                z: (max.z + min.z) / 2
            )
            
            // Center the usdzNode
            usdzNode.position = SCNVector3Zero
            usdzNode.position = SCNVector3(
                x: -boundingBoxCenter.x,
                y: -boundingBoxCenter.y,
                z: -boundingBoxCenter.z
            )
            
            // Add the usdzNode to the scene
            scene.rootNode.addChildNode(usdzNode)
            
            // Add a camera to the scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            
            // Position the camera with a zoom factor
            let zoomFactor: Float = 7
            cameraNode.position = SCNVector3(x: 0, y: 0, z: size.z * zoomFactor)
            scene.rootNode.addChildNode(cameraNode)

            // Set the camera's field of view to fit the object
            let fitCamera = cameraNode.camera!
            fitCamera.fieldOfView = 60
            fitCamera.automaticallyAdjustsZRange = true
        } else {
            print("Failed to load the USDZ file.")
        }

        // Add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        // Set up the scene view
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    // Helper function to apply random colors to geometries
    func applyRandomColors(to node: SCNNode) {
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1.0
            )
            geometry.materials = [material]
        }
        
        for child in node.childNodes {
            applyRandomColors(to: child)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
