//
//  GameScene.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    let squareSize: CGFloat = 32
    let fontRatio: CGFloat = 28 / 50

//    private var label : SKLabelNode?
    private var spinnyNode: SKShapeNode?
    private var boardNode: SKShapeNode? = nil
    private var stateNode: SKLabelNode? = nil
    private var mineCountNode: SKLabelNode? = nil

    private var isGameOver = false
    private var leftMouseDown = false
    private var rightMouseDown = false
    
    let localCamera = SKCameraNode()
    var game = Game()
    let semaphore = DispatchSemaphore(value: 1)
    
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
        
        drawGame()
        drawCenter()
    }
    
    func getOrigin() -> CGPoint {
        .init(
            x: -CGFloat(game.width) * squareSize / 2 + squareSize / 2,
            y: CGFloat(game.height) * squareSize / 2 - squareSize / 2
        )
    }
    
    func drawGame() {
        drawBoard()
        drawState()
        drawMineCount()
    }
    
    func drawBoard() {
        boardNode?.removeFromParent()
        
        let boardWidth = CGFloat(game.width) * squareSize
        let boardHeight = CGFloat(game.height) * squareSize
        boardNode = SKShapeNode(rectOf: .init(width: boardWidth, height: boardHeight))
        guard let boardNode else { return }
        
        let origin = getOrigin()
        let square = SKShapeNode(rectOf: .init(width: squareSize, height: squareSize))

        let board = game.render()
        for point in board.allPoints {
            let newSquare = square.copy() as! SKShapeNode
            
            newSquare.position = CGPoint(
                x: CGFloat(point.x) * squareSize,
                y: CGFloat(point.y) * -squareSize
            )
            
            newSquare.position = origin + newSquare.position
            
            let cell = board.get(point)
            switch cell {
            case .empty:
                newSquare.fillColor = .blue
            case .flagged:
                newSquare.fillColor = .black
            case .mine:
                newSquare.fillColor = .red
            case .unrevealed:
                newSquare.fillColor = .gray
            case .digit(let n):
                newSquare.fillColor = .blue
                
                let label = SKLabelNode(text: "\(n)")
                label.fontName = "Monaco"
                label.fontSize = squareSize * fontRatio
                label.horizontalAlignmentMode = .center
                label.verticalAlignmentMode = .center
                
                newSquare.addChild(label)
            }
            
            boardNode.addChild(newSquare)
        }
        
        addChild(boardNode)
    }
    
    func drawState() {
        let text: String
        switch game.state {
        case .uninitialized: text = "Uninitialized"
        case .ongoing: text = "Ongoing"
        case .loss: text = "Loss"
        case .win: text = "Win"
        }
        
        if stateNode == nil {
            let newLabel = SKLabelNode(text: text)
            newLabel.fontName = "Monaco"
            newLabel.fontSize = 50
            newLabel.horizontalAlignmentMode = .center
            newLabel.verticalAlignmentMode = .center
            
            let boardHeight = CGFloat(game.height) * squareSize
            
            let margin = squareSize
            let x: CGFloat = 0
            let y = boardHeight / 2 + margin
            
            newLabel.position = CGPoint(x: x, y: y)
            
            self.stateNode = newLabel
            addChild(newLabel)
        }
        
        guard let stateNode else { return }
        
        stateNode.text = text
        stateNode.isHidden = game.state == .ongoing
    }
    
    func drawMineCount() {
        let text = "\(game.minesLeft)"
        
        if mineCountNode == nil {
            let newLabel = SKLabelNode(text: text)
            newLabel.fontName = "Monaco"
            newLabel.fontSize = 50
            newLabel.horizontalAlignmentMode = .right
            newLabel.verticalAlignmentMode = .center
            
            let boardWidth = CGFloat(game.width) * squareSize
            let boardHeight = CGFloat(game.height) * squareSize

            let margin = squareSize
            let x: CGFloat = boardWidth / 2
            let y = boardHeight / 2 + margin
            
            newLabel.position = CGPoint(x: x, y: y)

            self.mineCountNode = newLabel
            addChild(newLabel)
        }
        
        guard let mineCountNode else { return }
        mineCountNode.text = text
    }
    
    func drawCenter() {
        let center = SKShapeNode(rectOf: .init(width: 5, height: 5))
        center.position = .zero
        addChild(center)
    }
    
    func touchDown(atPoint pos: CGPoint, right: Bool = false) {
        if right {
            rightMouseDown = true
        } else {
            leftMouseDown = true
        }
        
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos: CGPoint, right: Bool = false) {
        if right {
            rightMouseDown = false
        } else {
            leftMouseDown = false
        }
        
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
        
        let origin = getOrigin()
        let resultX = Int(round((pos.x - origin.x) / squareSize))
        let resultY = Int(round((-pos.y + origin.y) / squareSize))
        let point = Point(x: resultX, y: resultY)
        
        if right && leftMouseDown || !right && rightMouseDown {
            leftMouseDown = false
            rightMouseDown = false
            game.revealMany(point: point)
        } else if right {
            game.toggleFlag(point: point)
        } else {
            game.reveal(point: point)
        }
        
        drawGame()
    }
    
    override func mouseDown(with event: NSEvent) {
        touchDown(atPoint: event.location(in: self))
    }
    
    override func rightMouseDown(with event: NSEvent) {
        touchDown(atPoint: event.location(in: self), right: true)
    }
    
    override func mouseDragged(with event: NSEvent) {
        touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        touchUp(atPoint: event.location(in: self))
    }
    
    override func rightMouseUp(with event: NSEvent) {
        touchUp(atPoint: event.location(in: self), right: true)
    }
    
    override func keyDown(with event: NSEvent) {
        if event.isARepeat { return }
        
        switch event.keyCode {
        case 2: // D
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                self.game.newGame()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.drawGame()
                }
            }
        case 17: // T
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                self.game.primitiveSolve()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.drawGame()
                }
            }
        case 5: // G
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                self.game.primitiveSolveStep()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.drawGame()
                }
            }
        case 3: // F
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                self.game.solveStep()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.drawGame()
                }
            }
        case 9: // C
            loopify()
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
    
    func loopify() {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            
            while true {
                if self.game.state != .ongoing {
                    break
                }
                
                self.semaphore.wait()
                self.game.solveStep()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    
                    self.drawGame()
                    self.semaphore.signal()
                }
                
            }
        }
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
