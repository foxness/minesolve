//
//  Solver.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

struct Solver {
    
    let width: Int
    let height: Int
    
    let util: Util
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        self.util = Util(width: width, height: width)
    }
    
    func solve(board: [[RenderedCell]]) -> SolveResult {
        var pointsToReveal = [Point]()
        var pointsToFlag = [Point]()

        for y in 0..<height {
            for x in 0..<width {
                switch board[y][x] {
                case .number(let n): break
                default: break
                }
            }
        }
        
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    // MARK: - Helper
}

struct SolveResult {
    let pointsToReveal: [Point]
    let pointsToFlag: [Point]
}
