//
//  ViewController.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController, NSWindowDelegate {

    @IBOutlet var skView: SKView!
    var scene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
                self.scene = scene as? GameScene
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        view.window!.setFrame(NSRect(x: 0, y: 0, width: 1280, height: 720), display: true)
        view.window!.trueCenter()
        
        scene.drawGame()
    }
}

extension NSWindow {
    
    func trueCenter() {
        guard let targetScreen = self.screen ?? NSScreen.main else { return }
        let screenRect = targetScreen.visibleFrame
        
        let xPos = screenRect.origin.x + (screenRect.width - self.frame.width) / 2
        let yPos = screenRect.origin.y + (screenRect.height - self.frame.height) / 2
        
        self.setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
}
