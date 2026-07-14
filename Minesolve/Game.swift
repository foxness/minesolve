//
//  Game.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-14.
//

struct Game {
    
    let width = 10
    let height = 10
    let mines = 10
    
    var board: [[Cell]] = []
    
    init() {
        for _ in 0..<height {
            board.append(Array.init(repeating: .empty, count: width))
        }
    }
    
    mutating func initialize() {
        generateMines()
        fillNumbers()
    }
    
    mutating func generateMines() {
        for y in 0..<height {
            for x in 0..<width {
                board[y][x] = .empty
            }
        }
        
        var placedMines = 0
        while placedMines < mines {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            
            if board[y][x] == .mine {
                continue
            }
            
            board[y][x] = .mine
            placedMines += 1
        }
    }
    
    mutating func fillNumbers() {
        let adjacentOffsets: [(Int, Int)] = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),         (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
        
        for y in 0..<height {
            for x in 0..<width {
                if board[y][x] == .mine {
                    continue
                }
                
                var mineCount = 0
                for offset in adjacentOffsets {
                    let nx = x + offset.0
                    let ny = y + offset.1
                    
                    if isInBoard(x: nx, y: ny), board[ny][nx] == .mine {
                        mineCount += 1
                    }
                }
                
                if mineCount > 0 {
                    board[y][x] = .number(mineCount)
                }
            }
        }
    }
    
    mutating func reveal(x: Int, y: Int) {
        var revealString = "Reveal (\(x), \(y)) = "
       
        let cell = board[y][x]
        switch cell {
        case .empty:
            revealString.append("empty")
        case .number(let n):
            revealString.append("number \(n)")
        case .mine:
            revealString.append("mine")
        }
        
        print(revealString)
    }
    
    func isInBoard(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }
}

