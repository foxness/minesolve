//
//  GameScene.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    let fieldWidth = 10
    let fieldHeight = 10
    let squareSize: CGFloat = 50

//    private var label : SKLabelNode?
    private var spinnyNode: SKShapeNode?
    private var boardNode: SKShapeNode? = nil
    
    let localCamera = SKCameraNode()
    var game = Game()
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
//        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        
//        localCamera.yScale = -1
//        localCamera.position = CGPoint(x: size.width/2, y: size.height/2)
//        addChild(localCamera)
//        self.camera = localCamera
        
        game.initialize()
        
        drawBoard()
        drawCenter()
    }
    
    func getOrigin() -> CGPoint {
        .init(
            x: -CGFloat(fieldWidth) * squareSize / 2 + squareSize / 2,
            y: CGFloat(fieldHeight) * squareSize / 2 - squareSize / 2
        )
    }
    
    func drawBoard() {
        boardNode?.removeFromParent()
        
        let boardWidth = CGFloat(fieldWidth) * squareSize
        let boardHeight = CGFloat(fieldHeight) * squareSize
        boardNode = SKShapeNode(rectOf: .init(width: boardWidth, height: boardHeight))
        guard let boardNode else { return }
        
        let origin = getOrigin()
        let square = SKShapeNode(rectOf: .init(width: squareSize, height: squareSize))
        square.fillColor = .blue
        
        for y in 0..<fieldHeight {
            for x in 0..<fieldWidth {
                let newSquare = square.copy() as! SKShapeNode
                
                newSquare.position = CGPoint(
                    x: CGFloat(x) * squareSize,
                    y: CGFloat(y) * -squareSize
                )
                
                newSquare.position = origin + newSquare.position
                
                let cell = game.board[y][x]
                let cellState = game.boardState[y][x]
                
                if cellState == .revealed {
                    switch cell {
                    case .empty: break
                    case .number(let n):
                        let label = SKLabelNode(text: "\(n)")
                        label.fontName = "Monaco"
                        label.fontSize = 28
                        label.horizontalAlignmentMode = .center
                        label.verticalAlignmentMode = .center
                        
                        newSquare.addChild(label)
                    case .mine:
                        newSquare.fillColor = .red
                    }
                } else {
                    newSquare.fillColor = .gray
                }
                
                boardNode.addChild(newSquare)
            }
        }
        
        addChild(boardNode)
    }
    
    func drawCenter() {
        let center = SKShapeNode(rectOf: .init(width: 5, height: 5))
        center.position = .zero
        addChild(center)
    }
    
    func touchDown(atPoint pos: CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
        
        let origin = getOrigin()
        let resultX = Int(round((pos.x - origin.x) / squareSize))
        let resultY = Int(round((-pos.y + origin.y) / squareSize))
        
        game.reveal(x: resultX, y: resultY)
        drawBoard()
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos: CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:
            break
//            if let label = self.label {
//                label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//            }
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

extension CGPoint {
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
}
