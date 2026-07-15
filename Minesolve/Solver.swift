//
//  Solver.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

struct Solver {
    
    let width: Int
    let height: Int
    
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
    
    private func isValid(point: Point) -> Bool {
        point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    }
    
    private func getValidNeighbors(of point: Point) -> [Point] {
        getAdjacentPoints().compactMap { adjacent in
            let newPoint = point + adjacent
            return isValid(point: newPoint) ? newPoint : nil
        }
    }
    
    private func getAdjacentPoints() -> [Point] {
        [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),         (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
            .map { .init(x: $0, y: $1) }
    }
}

struct SolveResult {
    let pointsToReveal: [Point]
    let pointsToFlag: [Point]
}
