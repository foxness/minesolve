//
//  Game.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

struct Game {
    
    // MARK: - Constants
    
    let width = 9
    let height = 9
    let mines = 20
    let easyMode = true
    
    // MARK: - Properties
    
    private var board: Board
    private var isGenerated = false
    var state: GameState = .ongoing
    
    private let solver: Solver
    private let util: Util

    // MARK: - Init

    init() {
        board = Board(width: width, height: height, mines: mines)
        
        solver = Solver(width: width, height: height)
        util = Util(width: width, height: height)
    }
    
    // MARK: - Public methods
    
    mutating func newGame() {
        state = .ongoing
        
        for point in board.allPoints {
            board.set(cell: .empty, at: point)
            board.set(state: .unrevealed, at: point)
        }
        
        isGenerated = false
    }
    
    mutating func reveal(point: Point) {
        guard case .ongoing = state else { return }
        guard util.isValid(point: point) else { return }
        guard board.state(point) == .unrevealed else { return }
        
        if !isGenerated {
            generateNew(point: point)
            isGenerated = true
        }
        
        var revealString = "Reveal (\(point.x), \(point.y)) = "
        let cell = board.cell(point)
        switch cell {
        case .empty:
            revealString.append("empty")
            revealEmpty(point: point)
        case .number(let n):
            revealString.append("number \(n)")
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
        guard case .ongoing = state else { return }
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
        guard case .ongoing = state else { return }
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
        guard case .ongoing = state else { return }
        guard util.isValid(point: point) else { return }
        guard board.state(point) == .revealed else { return }
        guard case .number(let n) = board.cell(point) else { return }
        
        let neighbors = util.getValidNeighbors(of: point)
        let flaggedNeighborCount = neighbors.count { board.state($0) == .flagged }
        guard flaggedNeighborCount == n else { return }
        
        let unrevealedNeighbors = neighbors.filter { board.state($0) == .unrevealed }
        for neighbor in unrevealedNeighbors {
            reveal(point: neighbor)
        }
        
        print("RevealMany (\(point.x), \(point.y))")
    }
    
    mutating func primitiveSolveStep() {
        guard case .ongoing = state else { return }
        
        let rendered = render()
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
            
            let rendered = render()
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

    func render() -> [[RenderedCell]] {
        var result = [[RenderedCell]]()
        
        for y in 0..<height {
            result.append(Array(repeating: .empty, count: width))
            
            for x in 0..<width {
                let point = Point(x: x, y: y)
                
                switch board.state(point) {
                case .unrevealed:
                    result[y][x] = .unrevealed
                case .revealed:
                    switch board.cell(point) {
                    case .empty:
                        result[y][x] = .empty
                    case .mine:
                        result[y][x] = .mine
                    case .number(let n):
                        result[y][x] = .number(n)
                    }
                case .flagged:
                    result[y][x] = .flagged
                }
            }
        }
        
        return result
    }

    // MARK: - Private methods
    
    private mutating func generateNew(point: Point) {
        generateMines(initialPoint: point)
        fillNumbers()
        print("New game generated.")
    }
    
    private mutating func generateMines(initialPoint: Point) {
        assert(!isGenerated)
        
        var placedMines = 0
        while placedMines < mines {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let newPoint = Point(x: x, y: y)
            
            if easyMode {
                let neighbors = util.getValidNeighbors(of: initialPoint)
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
    
    private mutating func fillNumbers() {
        for point in board.allPoints {
            if board.cell(point) == .mine {
                continue
            }
            
            var mineCount = 0
            for neighbor in util.getValidNeighbors(of: point) {
                if board.cell(neighbor) == .mine {
                    mineCount += 1
                }
            }
            
            if mineCount > 0 {
                board.set(cell: .number(mineCount), at: point)
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
                
                for neighbor in util.getValidNeighbors(of: wavePoint) {
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
