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
}

enum Cell: Equatable {
    case empty
    case mine
    case number(Int)
}
