//
//  Solver.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

struct Solver {
    
    // MARK: - Constants

    let width: Int
    let height: Int
    
    // MARK: - Private properties
    
    private let util: Util
    
    // MARK: - Init
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        self.util = Util(width: width, height: height)
    }
    
    // MARK: - Public methods
    
    func solve(board: RenderedBoard) -> SolveResult {
        let primitiveSolve = primitiveSolveStep(board: board)
        
        let primitiveFlagged = primitiveSolve.pointsToFlag
        let primitiveRevealed = primitiveSolve.pointsToReveal
        
        guard primitiveRevealed.isEmpty else {
            // return primitive
            return SolveResult(pointsToReveal: primitiveRevealed, pointsToFlag: primitiveFlagged)
        }
        
        let complexToReveal = solveIslands(board: board, primitiveFlagged: primitiveFlagged)
        return SolveResult(pointsToReveal: complexToReveal, pointsToFlag: primitiveFlagged)
    }

    func primitiveSolveStep(board: RenderedBoard) -> SolveResult {
        let pointsToFlag = primitiveFlag(board: board)
        let pointsToReveal = primitiveReveal(board: board, pointsToFlag: pointsToFlag)
        
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    // MARK: - Private methods
    
    private func solveIslands(board: RenderedBoard, primitiveFlagged: Set<Point>) -> Set<Point> {
//        var lightPoints = Set<Point>() // points that touch a digit
        var darkPoints: Set<Point> = [] // points that dont touch a digit
        
        let unrevealed = Set(board.allPoints.filter { board.get($0).isUnrevealed() })
        let uncertain = unrevealed.subtracting(primitiveFlagged)
        
        for point in uncertain {
            let neighbors = util.adjacent(to: point)
            let isTouchingDigit = neighbors.contains { board.get($0).isDigit() }
            
            if isTouchingDigit {
//                lightPoints.insert(point)
            } else {
                darkPoints.insert(point)
            }
        }
        
        let digits = Set(board.allPoints.filter { board.get($0).isDigit() })
        let lightDigits = digits.filter { digit in
            let neighbors = Set(util.adjacent(to: digit))
            let isTouchingUncertain = !neighbors.intersection(uncertain).isEmpty
            return isTouchingUncertain
        }
        
        let lightDigitIslands = divideLightDigitIslands(board: board, lightDigits: lightDigits)
        for island in lightDigitIslands {
            print(island)
        }
        
        return Set<Point>()
    }
    
    private func divideLightDigitIslands(board: RenderedBoard, lightDigits: Set<Point>) -> [Set<Point>] {
        var unclaimed = lightDigits
        var islands: [Set<Point>] = []
        
        while !unclaimed.isEmpty {
            var island: Set<Point> = []
            
            var currentWave: Set<Point> = [unclaimed.first!]
            while !currentWave.isEmpty {
                island.formUnion(currentWave)
                
                var newWave: Set<Point> = []
                for wavePoint in currentWave {
                    let neighbors = util.touching(point: wavePoint)
                    let eligibleNeighbors = neighbors.intersection(unclaimed).subtracting(island)
                    
                    newWave.formUnion(eligibleNeighbors)
                }
                
                currentWave = newWave
            }
            
            islands.append(island)
            unclaimed.subtract(island)
        }
        
        print("Islands found: \(islands.count)")
        return islands
    }

    private func primitiveFlag(board: RenderedBoard) -> Set<Point> {
        var pointsToFlag: Set<Point> = []
        
        for point in board.allPoints {
            if case .digit(let n) = board.get(point) {
                let neighbors = util.adjacent(to: point)
                let unrevealedNeighbors = Set(neighbors.filter { board.get($0).isUnrevealed() })
                
                if unrevealedNeighbors.count == n {
                    pointsToFlag.formUnion(unrevealedNeighbors)
                }
            }
        }

        return pointsToFlag
    }
    
    private func primitiveReveal(board: RenderedBoard, pointsToFlag: Set<Point>) -> Set<Point> {
        var pointsToReveal: Set<Point> = []
        var neighborsOfFlagged: Set<Point> = []
        for point in pointsToFlag {
            let digitNeighbors = util.adjacent(to: point).filter { board.get($0).isDigit() }
            neighborsOfFlagged.formUnion(digitNeighbors)
        }
        
        for point in neighborsOfFlagged {
            let neighbors = Set(util.adjacent(to: point))
            let intersection = neighbors.intersection(pointsToFlag)
            
            if case let .digit(n) = board.get(point), intersection.count == n {
                let unrevealedNeighbors = neighbors.filter { board.get($0).isUnrevealed() }
                let toReveal = unrevealedNeighbors.subtracting(pointsToFlag)
                
                pointsToReveal.formUnion(toReveal)
            }
        }
        
        return pointsToReveal
    }
}

// MARK: - Helper misc

struct SolveResult {
    let pointsToReveal: Set<Point>
    let pointsToFlag: Set<Point>
}
