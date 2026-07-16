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
        
        self.util = Util(width: width, height: height)
    }
    
    func primitiveSolveStep(board: RenderedBoard) -> SolveResult {
        var pointsToFlag = Set<Point>()
        var pointsToReveal = Set<Point>()

        for point in board.allPoints {
            if case .number(let n) = board.get(point) {
                let neighbors = util.getValidNeighbors(of: point)
                let unrevealedNeighbors = Set(neighbors.filter { board.get($0).isUnrevealed() })
                
                if unrevealedNeighbors.count == n {
                    pointsToFlag.formUnion(unrevealedNeighbors)
                }
            }
        }
        
        var neighborsOfFlagged = Set<Point>()
        for point in pointsToFlag {
            let numberNeighbors = util.getValidNeighbors(of: point).filter {
                if case .number = board.get($0) {
                    return true
                }
                
                return false
            }
            
            neighborsOfFlagged.formUnion(numberNeighbors)
        }
        
        for point in neighborsOfFlagged {
            let neighbors = Set(util.getValidNeighbors(of: point))
            let intersection = neighbors.intersection(pointsToFlag)
            
            if case let .number(n) = board.get(point), intersection.count == n {
                let unrevealedNeighbors = neighbors.filter { board.get($0).isUnrevealed() }
                let toReveal = unrevealedNeighbors.subtracting(pointsToFlag)
                
                pointsToReveal.formUnion(toReveal)
            }
        }
        
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
}

struct SolveResult {
    let pointsToReveal: Set<Point>
    let pointsToFlag: Set<Point>
}
