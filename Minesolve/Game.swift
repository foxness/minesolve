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
    let mines = 10
    
    // MARK: - Properties
    
    var board: [[Cell]]
    var boardState: [[CellState]]
    var isGenerated = false
    var state: GameState = .ongoing
    
    // MARK: - Init

    init() {
        board = []
        boardState = []
        
        for _ in 0..<height {
            board.append(Array(repeating: .empty, count: width))
            boardState.append(Array(repeating: .unrevealed, count: width))
        }
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
    
    mutating func reveal(x: Int, y: Int) {
        guard case .ongoing = state else { return }
        guard isValidPoint(x: x, y: y) else { return }
        guard boardState[y][x] == .unrevealed else { return }
        
        if !isGenerated {
            generateNew(x: x, y: y)
            isGenerated = true
        }
        
        var revealString = "Reveal (\(x), \(y)) = "
        let cell = board[y][x]
        switch cell {
        case .empty:
            revealString.append("empty")
            revealEmpty(x: x, y: y)
        case .number(let n):
            revealString.append("number \(n)")
            boardState[y][x] = .revealed
        case .mine:
            revealString.append("mine")
            boardState[y][x] = .revealed
            state = .loss
            print("You lose!")
        }
        
        print(revealString)
        checkForWin()
    }
    
    mutating func flag(x: Int, y: Int) {
        guard case .ongoing = state else { return }
        guard isValidPoint(x: x, y: y) else { return }

        switch boardState[y][x] {
        case .unrevealed:
            boardState[y][x] = .flagged
        case .revealed:
            break
        case .flagged:
            boardState[y][x] = .unrevealed
        }
    }
    
    mutating func revealMany(x: Int, y: Int) {
        guard case .ongoing = state else { return }
        guard isValidPoint(x: x, y: y) else { return }
        guard boardState[y][x] == .revealed else { return }
        guard case .number(let n) = board[y][x] else { return }
        
        let neighbors = getValidNeighbors(x: x, y: y)
        let flaggedNeighborCount = neighbors.count(where: { boardState[$0.1][$0.0] == .flagged })
        guard flaggedNeighborCount == n else { return }
        
        let unrevealedNeighbors = neighbors.filter { boardState[$1][$0] == .unrevealed }
        for (nx, ny) in unrevealedNeighbors {
            reveal(x: nx, y: ny)
        }
        
        print("RevealMany (\(x), \(y))")
    }

    // MARK: - Private methods
    
    private mutating func generateNew(x: Int, y: Int) {
        generateMines(initialX: x, initialY: y)
        fillNumbers()
        print("New game generated.")
    }
    
    private mutating func generateMines(initialX: Int, initialY: Int) {
        assert(!isGenerated)
        
        var placedMines = 0
        while placedMines < mines {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            
            if (x == initialX && y == initialY) || board[y][x] == .mine {
                continue
            }
            
            board[y][x] = .mine
            placedMines += 1
        }
    }
    
    private mutating func fillNumbers() {
        for y in 0..<height {
            for x in 0..<width {
                if board[y][x] == .mine {
                    continue
                }
                
                var mineCount = 0
                for neighbor in getValidNeighbors(x: x, y: y) {
                    let nx = neighbor.0
                    let ny = neighbor.1
                    
                    if board[ny][nx] == .mine {
                        mineCount += 1
                    }
                }
                
                if mineCount > 0 {
                    board[y][x] = .number(mineCount)
                }
            }
        }
    }
    
    private mutating func revealEmpty(x: Int, y: Int) {
        var visited = [(Int, Int)]()
        var currentWave = [(x, y)]
        
        while !currentWave.isEmpty {
            visited += currentWave
            
            var newWave = [(Int, Int)]()
            for point in currentWave {
                let (px, py) = point
                
                if board[py][px] != .empty {
                    continue
                }
                
                for neighbor in getValidNeighbors(x: px, y: py) {
                    let (nx, ny) = neighbor
                    
                    if visited.contains(where: { $0 == (nx, ny) }) {
                        continue
                    }
                    
                    if newWave.contains(where: { $0 == (nx, ny) }) {
                        continue
                    }
                    
                    newWave += [(nx, ny)]
                }
            }
            
            currentWave = newWave
        }
        
        for (px, py) in visited {
            boardState[py][px] = .revealed
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
    
    // MARK: - Helper
    
    private func isValidPoint(x: Int, y: Int) -> Bool {
        x >= 0 && x < width && y >= 0 && y < height
    }
    
    private func getValidNeighbors(x: Int, y: Int) -> [(Int, Int)] {
        getAdjacentOffsets().compactMap { offset in
            let nx = x + offset.0
            let ny = y + offset.1
            return isValidPoint(x: nx, y: ny) ? (nx, ny) : nil
        }
    }
    
    private func getAdjacentOffsets() -> [(Int, Int)] {
        [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),         (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
    }
}

