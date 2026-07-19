//
//  Game.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

import Foundation

struct Game {
    
    // MARK: - Constants
    
    let width = 30
    let height = 16
    let mines: Int
    let easyMode = true
    
    // MARK: - Properties
    
    private var board: Board
    var state: GameState = .uninitialized
    
    private let solver: Solver
    private let util: Util
    
    var minesLeft: Int {
        let flagCount = board.allPoints.count { board.state($0) == .flagged }
        return mines - flagCount
    }

    // MARK: - Init

    init() {
        let mineDensity: Double = 99 / (30 * 16)
        mines = Int(round(mineDensity * (Double(width) * Double(height))))
        
        board = Board(width: width, height: height, mines: mines)

        solver = Solver(width: width, height: height)
        util = Util(width: width, height: height)
    }
    
    // MARK: - Public methods
    
    mutating func newGame() {
        state = .uninitialized
        
        for point in board.allPoints {
            board.set(cell: .empty, at: point)
            board.set(state: .unrevealed, at: point)
        }
    }
    
    mutating func reveal(point: Point) {
        switch state {
        case .uninitialized, .ongoing:
            break
        case .win, .loss:
            return
        }
        
        guard util.isValid(point: point) else { return }
        guard board.state(point) == .unrevealed else { return }
        
        if state == .uninitialized {
            generateNew(point: point)
            state = .ongoing
        }
        
        var revealString = "Reveal (\(point.x), \(point.y)) = "
        let cell = board.cell(point)
        switch cell {
        case .empty:
            revealString.append("empty")
            revealEmpty(point: point)
        case .digit(let n):
            revealString.append("digit \(n)")
            board.set(state: .revealed, at: point)
        case .mine:
            revealString.append("mine")
            board.set(state: .revealed, at: point)
            state = .loss
            print("You lose!")
            revealAllMines()
        }
        
//        print(revealString)
        checkForWin()
    }
    
    mutating func toggleFlag(point: Point) {
        guard !state.isOver() else { return }
        guard util.isValid(point: point) else { return }
        
        switch board.state(point) {
        case .unrevealed:
            board.set(state: .flagged, at: point)
        case .revealed:
            break
        case .flagged:
            board.set(state: .unrevealed, at: point)
        }
    }

    mutating func flag(point: Point) {
        guard !state.isOver() else { return }
        guard util.isValid(point: point) else { return }

        switch board.state(point) {
        case .unrevealed:
            board.set(state: .flagged, at: point)
        case .revealed:
            break
        case .flagged:
            break
        }
    }
    
    mutating func revealMany(point: Point) {
        guard !state.isOver() else { return }
        
        guard util.isValid(point: point) else { return }
        guard board.state(point) == .revealed else { return }
        guard case .digit(let n) = board.cell(point) else { return }
        
        let neighbors = util.adjacent(to: point)
        let flaggedNeighborCount = neighbors.count { board.state($0) == .flagged }
        guard flaggedNeighborCount == n else { return }
        
        let unrevealedNeighbors = neighbors.filter { board.state($0) == .unrevealed }
        for neighbor in unrevealedNeighbors {
            reveal(point: neighbor)
        }
        
        print("RevealMany (\(point.x), \(point.y))")
    }
    
    mutating func primitiveSolveStep() {
        guard !state.isOver() else { return }

        let rendered = board.render()
        let result = solver.primitiveSolveStep(board: rendered)
        
        print("Flagging \(result.pointsToFlag.count) and revealing \(result.pointsToReveal.count)")
        for point in result.pointsToFlag {
            flag(point: point)
        }
        
        for point in result.pointsToReveal {
            reveal(point: point)
        }
    }
    
    mutating func primitiveSolve() {
        while true {
            guard case .ongoing = state else { return }
            
            let rendered = board.render()
            let result = solver.primitiveSolveStep(board: rendered)

            print("Flagging \(result.pointsToFlag.count) and revealing \(result.pointsToReveal.count)")
            for point in result.pointsToFlag {
                flag(point: point)
            }
            
            for point in result.pointsToReveal {
                reveal(point: point)
            }
            
            if result.pointsToReveal.isEmpty {
                break
            }
        }
    }
    
    mutating func solveStep() {
        if case .uninitialized = state {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let point = Point(x: x, y: y)
            
            print("No cells to solve, starting at random point \(point)")
            reveal(point: point)
            return
        }
        
        guard case .ongoing = state else { return }
        
        let rendered = board.render()
        let result = solver.solve(board: rendered)
        
        for point in result.pointsToFlag {
            flag(point: point)
        }
        
        for point in result.pointsToReveal {
            reveal(point: point)
        }
    }

    func render() -> RenderedBoard {
        board.render()
    }

    // MARK: - Private methods
    
    private mutating func generateNew(point: Point) {
        generateMines(initialPoint: point)
        fillDigits()
        print("New game generated.")
    }
    
    private mutating func generateMines(initialPoint: Point) {
        assert(state == .uninitialized)
        
        var placedMines = 0
        while placedMines < mines {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let newPoint = Point(x: x, y: y)
            
            if easyMode {
                let neighbors = util.adjacent(to: initialPoint)
                if neighbors.contains(newPoint) {
                    continue
                }
            }
            
            if newPoint == initialPoint || board.cell(newPoint) == .mine {
                continue
            }
            
            board.set(cell: .mine, at: newPoint)
            placedMines += 1
        }
    }
    
    private mutating func fillDigits() {
        for point in board.allPoints {
            if board.cell(point) == .mine {
                continue
            }
            
            var mineCount = 0
            for neighbor in util.adjacent(to: point) {
                if board.cell(neighbor) == .mine {
                    mineCount += 1
                }
            }
            
            if mineCount > 0 {
                board.set(cell: .digit(mineCount), at: point)
            }
        }
    }
    
    private mutating func revealEmpty(point: Point) {
        var visited = [Point]()
        var currentWave = [point]
        
        while !currentWave.isEmpty {
            visited += currentWave
            
            var newWave = [Point]()
            for wavePoint in currentWave {
                if board.cell(wavePoint) != .empty {
                    continue
                }
                
                for neighbor in util.adjacent(to: wavePoint) {
                    if visited.contains(neighbor) {
                        continue
                    }
                    
                    if newWave.contains(neighbor) {
                        continue
                    }
                    
                    newWave.append(neighbor)
                }
            }
            
            currentWave = newWave
        }
        
        for p in visited {
            board.set(state: .revealed, at: p)
        }
    }
    
    private mutating func checkForWin() {
        guard case .ongoing = state else { return }
        
        let unrevealedCount = board.allPoints.count { board.state($0) != .revealed }
        if unrevealedCount == mines {
            board.allPoints.filter { board.state($0) == .unrevealed }.forEach {
                board.set(state: .flagged, at: $0)
            }
            
            state = .win
            print("You win!")
        }
    }
    
    private mutating func revealAllMines() {
        for point in board.allPoints {
            if board.cell(point) == .mine, board.state(point) != .flagged {
                board.set(state: .revealed, at: point)
            }
        }
    }
}
