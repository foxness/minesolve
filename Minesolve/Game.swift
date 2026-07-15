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
        for y in 0..<height {
            for x in 0..<width {
                board[y][x] = .empty
                boardState[y][x] = .unrevealed
            }
        }
        
        isGenerated = false
    }
    
    mutating func reveal(x: Int, y: Int) {
        if !isValidPoint(x: x, y: y) {
            return
        }
        
        if !isGenerated {
            generateNew(x: x, y: y)
            isGenerated = true
        }
        
        if boardState[y][x] == .revealed {
            return
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
        }
        
        print(revealString)
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
    
    // MARK: - Helper
    
    private func isValidPoint(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
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

