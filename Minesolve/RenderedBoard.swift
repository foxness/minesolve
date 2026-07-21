//
//  RenderedBoard.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-16.
//

struct RenderedBoard {
    let width: Int
    let height: Int
    let mines: Int
    
    private var board: [[RenderedCell]]
    
    var allPoints: [Point] {
        var result = [Point]()
        
        for y in 0..<height {
            for x in 0..<width {
                result.append(Point(x: x, y: y))
            }
        }
        
        return result
    }
    
    init(width: Int, height: Int, mines: Int) {
        self.width = width
        self.height = height
        self.mines = mines
        
        board = []
        
        for _ in 0..<height {
            board.append(Array(repeating: .empty, count: width))
        }
    }
    
    func get(_ point: Point) -> RenderedCell {
        board[point.y][point.x]
    }
    
    func isInBounds(_ point: Point) -> Bool {
        point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    }
    
    mutating func set(cell: RenderedCell, at point: Point) {
        board[point.y][point.x] = cell
    }
}
