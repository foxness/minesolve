//
//  Board.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-16.
//

struct Board {
    let width: Int
    let height: Int
    let mines: Int
    
    private var board: [[Cell]]
    private var boardState: [[CellState]]
    
    init(width: Int, height: Int, mines: Int) {
        self.width = width
        self.height = height
        self.mines = mines
        
        board = []
        boardState = []
        
        for _ in 0..<height {
            board.append(Array(repeating: .empty, count: width))
            boardState.append(Array(repeating: .unrevealed, count: width))
        }
    }
    
    func cell(_ point: Point) -> Cell {
        board[point.y][point.x]
    }
    
    func state(_ point: Point) -> CellState {
        boardState[point.y][point.x]
    }
    
    mutating func set(cell: Cell, at point: Point) {
        board[point.y][point.x] = cell
    }
    
    mutating func set(state: CellState, at point: Point) {
        boardState[point.y][point.x] = state
    }
}
