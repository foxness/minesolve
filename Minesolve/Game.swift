//
//  Game.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

struct Game {
    
    // MARK: - Constants
    
    let width = 30
    let height = 16
    let mines = 99
    let easyMode = true
    
    // MARK: - Properties
    
    private var board: [[Cell]]
    private var boardState: [[CellState]]
    private var isGenerated = false
    var state: GameState = .ongoing
    
    private let solver: Solver
    private let util: Util

    // MARK: - Init

    init() {
        board = []
        boardState = []
        
        for _ in 0..<height {
            board.append(Array(repeating: .empty, count: width))
            boardState.append(Array(repeating: .unrevealed, count: width))
        }
        
        solver = Solver(width: width, height: height)
        util = Util(width: width, height: height)
    }
    
    // MARK: - Public methods
    
    mutating func newGame() {
        state = .ongoing
        
        for y in 0..<height {
            for x in 0..<width {
                board[y][x] = .empty
                boardState[y][x] = .unrevealed
            }
        }
        
        isGenerated = false
    }
    
    mutating func reveal(point: Point) {
        guard case .ongoing = state else { return }
        guard util.isValid(point: point) else { return }
        guard boardState[point.y][point.x] == .unrevealed else { return }
        
        if !isGenerated {
            generateNew(point: point)
            isGenerated = true
        }
        
        var revealString = "Reveal (\(point.x), \(point.y)) = "
        let cell = board[point.y][point.x]
        switch cell {
        case .empty:
            revealString.append("empty")
            revealEmpty(point: point)
        case .number(let n):
            revealString.append("number \(n)")
            boardState[point.y][point.x] = .revealed
        case .mine:
            revealString.append("mine")
            boardState[point.y][point.x] = .revealed
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
        
        switch boardState[point.y][point.x] {
        case .unrevealed:
            boardState[point.y][point.x] = .flagged
        case .revealed:
            break
        case .flagged:
            boardState[point.y][point.x] = .unrevealed
        }
    }

    mutating func flag(point: Point) {
        guard case .ongoing = state else { return }
        guard util.isValid(point: point) else { return }

        switch boardState[point.y][point.x] {
        case .unrevealed:
            boardState[point.y][point.x] = .flagged
        case .revealed:
            break
        case .flagged:
            break
        }
    }
    
    mutating func revealMany(point: Point) {
        guard case .ongoing = state else { return }
        guard util.isValid(point: point) else { return }
        guard boardState[point.y][point.x] == .revealed else { return }
        guard case .number(let n) = board[point.y][point.x] else { return }
        
        let neighbors = util.getValidNeighbors(of: point)
        let flaggedNeighborCount = neighbors.count(where: { boardState[$0.y][$0.x] == .flagged })
        guard flaggedNeighborCount == n else { return }
        
        let unrevealedNeighbors = neighbors.filter { boardState[$0.y][$0.x] == .unrevealed }
        for neighbor in unrevealedNeighbors {
            reveal(point: neighbor)
        }
        
        print("RevealMany (\(point.x), \(point.y))")
    }
    
    mutating func solve() {
        let rendered = render()
        let result = solver.solve(board: rendered)
        
        print("Flagging \(result.pointsToFlag.count) and revealing \(result.pointsToReveal.count)")
        for point in result.pointsToFlag {
            flag(point: point)
        }
        
        for point in result.pointsToReveal {
            reveal(point: point)
        }
    }
    
    func render() -> [[RenderedCell]] {
        var result = [[RenderedCell]]()
        
        for y in 0..<height {
            result.append(Array(repeating: .empty, count: width))
            
            for x in 0..<width {
                switch boardState[y][x] {
                case .unrevealed:
                    result[y][x] = .unrevealed
                case .revealed:
                    switch board[y][x] {
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
            
            if newPoint == initialPoint || board[y][x] == .mine {
                continue
            }
            
            board[y][x] = .mine
            placedMines += 1
        }
    }
    
    private mutating func fillNumbers() {
        for y in 0..<height {
            for x in 0..<width {
                let point = Point(x: x, y: y)
                if board[y][x] == .mine {
                    continue
                }
                
                var mineCount = 0
                for neighbor in util.getValidNeighbors(of: point) {
                    if board[neighbor.y][neighbor.x] == .mine {
                        mineCount += 1
                    }
                }
                
                if mineCount > 0 {
                    board[y][x] = .number(mineCount)
                }
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
                if board[wavePoint.y][wavePoint.x] != .empty {
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
            boardState[p.y][p.x] = .revealed
        }
    }
    
    private mutating func checkForWin() {
        guard case .ongoing = state else { return }
        
        var unrevealedCount = 0
        for y in 0..<height {
            for x in 0..<width {
                if boardState[y][x] != .revealed {
                    unrevealedCount += 1
                }
            }
        }
        
        if unrevealedCount == mines {
            state = .win
            print("You win!")
        }
    }
    
    private mutating func revealAllMines() {
        for y in 0..<height {
            for x in 0..<width {
                if board[y][x] == .mine, boardState[y][x] != .flagged {
                    boardState[y][x] = .revealed
                }
            }
        }
    }
}
