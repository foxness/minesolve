//
//  Solver.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

import Foundation
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
            print("Primitive solution found")
            return SolveResult(pointsToReveal: primitiveRevealed, pointsToFlag: primitiveFlagged)
        }
        
        print("Complex solving...")
        return solveIslands(board: board, primitiveFlagged: primitiveFlagged)
    }

    func primitiveSolveStep(board: RenderedBoard) -> SolveResult {
        let pointsToFlag = primitiveFlag(board: board)
        let pointsToReveal = primitiveReveal(board: board, pointsToFlag: pointsToFlag)
        
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    // MARK: - Private methods
    
    private func solveIslands(board: RenderedBoard, primitiveFlagged: Set<Point>) -> SolveResult {
        var darkPoints: Set<Point> = [] // points that dont touch a digit
        
        let unrevealed = Set(board.allPoints.filter { board.get($0).isUnrevealed() })
        let uncertain = unrevealed.subtracting(primitiveFlagged)
        
        for point in uncertain {
            let neighbors = util.adjacent(to: point)
            let isTouchingDigit = neighbors.contains { board.get($0).isDigit() }
            
            if !isTouchingDigit {
                darkPoints.insert(point)
            }
        }
        
        let digits = Set(board.allPoints.filter { board.get($0).isDigit() })
        let lightDigits = digits.filter { digit in
            let neighbors = Set(util.adjacent(to: digit))
            let isTouchingUncertain = !neighbors.intersection(uncertain).isEmpty
            return isTouchingUncertain
        }
        
        let islands = divideLightDigitIslands(board: board, lightDigits: lightDigits)
//        print("Islands found: \(islands.count)")
//        for island in islands {
//            print(island)
//        }
        
        let trueDigitIslands = mergeIntoTrueIslands(pseudoIslands: islands, uncertain: uncertain)
        print("True islands: \(trueDigitIslands.count)")
//        for island in trueDigitIslands {
//            print(island)
//        }
        
        let uncertainIslands = trueDigitIslands.map { convertToUncertainIsland(digitIsland: $0, uncertain: uncertain) }
        var setOfIslandSolutions: [[[Point: Bool]]] = []
        for island in uncertainIslands {
            print("Solving island of \(island.count)")
            let oneIslandSolutions = solveOneIsland(island: island, board: board, primitiveFlagged: primitiveFlagged)
            print("Solutions: \(oneIslandSolutions.count)")
            
            setOfIslandSolutions.append(oneIslandSolutions)
        }
        
        return formSolution(setOfIslandSolutions, primitiveFlagged: primitiveFlagged)
    }
    
    private func formSolution(_ setOfIslandSolutions: [[[Point: Bool]]], primitiveFlagged: Set<Point>) -> SolveResult {
        guard !setOfIslandSolutions.isEmpty else {
            return SolveResult(pointsToReveal: [], pointsToFlag: [])
        }
        
        var mineProbabilities: [Point: Double] = [:]
        
        for oneIslandSolutions in setOfIslandSolutions {
            let island = oneIslandSolutions[0].keys
            var islandMineCounts: [Point: Int] = [:]
            island.forEach { islandMineCounts[$0] = 0 }
            
            for solution in oneIslandSolutions {
                for (point, isMine) in solution {
                    islandMineCounts[point]! += isMine ? 1 : 0
                }
            }
            
            island.forEach { point in
                let probability = Double(islandMineCounts[point]!) / Double(oneIslandSolutions.count)
                mineProbabilities[point] = probability
            }
        }
        
        let sortedProbabilities = mineProbabilities.map { (key, value) in (key, value) }.sorted { $0.1 < $1.1 }
//        for p in sortedProbabilities.reversed() {
//            print("\(p.0): \(String(format: "%.2f", p.1))")
//        }
        
        let safePoints = Set(sortedProbabilities.filter { (key, value) in value == 0 }.map(\.0))
        print("Safe: \(safePoints)")
        
        let pointsToReveal: Set<Point>
        if safePoints.isEmpty {
            let riskyPoint = sortedProbabilities.first!
            print("Chose a risky one: \(riskyPoint.0) with probability \(String(format: "%.2f", riskyPoint.1))")
            pointsToReveal = [riskyPoint.0]
        } else {
            pointsToReveal = safePoints
        }
        
        let pointsToFlag = Set(sortedProbabilities.filter { (key, value) in value == 1 }.map(\.0))
            .union(primitiveFlagged)

        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    private func solveOneIsland(island: Set<Point>, board: RenderedBoard, primitiveFlagged: Set<Point>) -> [[Point: Bool]] {
        var solutions: [[Point: Bool]] = []
        var current: [Point: Bool?] = [:] // [coord: isMine?]
        island.forEach { current.updateValue(nil, forKey: $0) }

        let digits = adjustedDigits(island: island, board: board, primitiveFlagged: primitiveFlagged)
        solve(current: current, digits: digits, depth: 0, solutions: &solutions)
        
        return solutions
    }
    
    private func solve(current: [Point: Bool?], digits: [Point: Int], depth: Int, solutions: inout [[Point: Bool]]) {
//        print("Depth: \(depth)")
        
        let solved = current.keys.filter { current[$0]! != nil }
//        print("solved: \(solved)")

        for (point, value) in digits {
            let neighbors = Set(util.adjacent(to: point)).intersection(current.keys)
            let unsolvedNeighbors = neighbors.subtracting(solved)
//            print("neighbors: \(neighbors), unsolvedNeighbors: \(unsolvedNeighbors)")
            if !unsolvedNeighbors.isEmpty {
                continue
            }
            
            let mineCount = neighbors.compactMap { current[$0]! }.count { $0 }
            if value != mineCount {
//                print("Found mismatch at \(point), value is \(value) but mineCount is \(mineCount), returning...")
                return
            }
        }
        
        let unsolved = Set(current.keys).subtracting(solved)
        if unsolved.isEmpty {
            var solution: [Point: Bool] = [:]
            for (k, v) in current {
                solution[k] = v!
            }
            
            solutions.append(solution)
            return
        }
        
        let pointToSolve = unsolved.first!
        var newCurrent = current
        
        newCurrent[pointToSolve] = false
        solve(current: newCurrent, digits: digits, depth: depth + 1, solutions: &solutions)
        
        newCurrent[pointToSolve] = true
        solve(current: newCurrent, digits: digits, depth: depth + 1, solutions: &solutions)
    }
    
    private func adjustedDigits(island: Set<Point>, board: RenderedBoard, primitiveFlagged: Set<Point>) -> [Point: Int] {
        let digits = Set(island.flatMap { util.adjacent(to: $0) })
            .subtracting(island)
            .filter { board.get($0).isDigit() }
        
        var result: [Point: Int] = [:]
        for digit in digits {
            let cell = board.get(digit)
            var adjusted: Int
            switch cell {
            case .digit(let n):
                adjusted = n
            default:
                fatalError()
            }
            
            let adjacentFlags = Set(util.adjacent(to: digit)).intersection(primitiveFlagged)
            adjusted -= adjacentFlags.count
            
            result[digit] = adjusted
        }
        
        return result
    }
    
    private func mergeIntoTrueIslands(pseudoIslands: [Set<Point>], uncertain: Set<Point>) -> [Set<Point>] {
        var merged = pseudoIslands
        
        while true {
            let newMerged = mergeIntoTrueIslandsStep(pseudoIslands: merged, uncertain: uncertain)
            if newMerged.count == merged.count {
                break
            }
            
            merged = newMerged
        }
        
        return merged
    }

    private func mergeIntoTrueIslandsStep(pseudoIslands: [Set<Point>], uncertain: Set<Point>) -> [Set<Point>] {
        guard pseudoIslands.count > 1 else { return pseudoIslands }
        
        var trueIslands: [Set<Point>] = []
        
        var islandsWithUncertain: [(Set<Point>, Set<Point>)] = []
        for island in pseudoIslands {
            let uncertainOfIsland = convertToUncertainIsland(digitIsland: island, uncertain: uncertain)
            islandsWithUncertain.append((island, uncertainOfIsland))
        }
        
        while !islandsWithUncertain.isEmpty {
            let (island, uncertainOfIsland) = islandsWithUncertain.removeFirst()
            
            var toMerge: [Set<Point>] = []
            for (otherIsland, otherUncertainOfIsland) in islandsWithUncertain {
                let shouldMerge = !uncertainOfIsland.intersection(otherUncertainOfIsland).isEmpty
                if shouldMerge {
                    toMerge.append(otherIsland)
                }
            }
            
            islandsWithUncertain.removeAll { (island_, uncertain_) in toMerge.contains(island_) }
            
            var trueIsland = island
            for islandToMerge in toMerge {
                trueIsland.formUnion(islandToMerge)
            }
            
            trueIslands.append(trueIsland)
        }
        
        return trueIslands
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
    
    private func convertToUncertainIsland(digitIsland: Set<Point>, uncertain: Set<Point>) -> Set<Point> {
        Set(digitIsland.flatMap { util.adjacent(to: $0) }).intersection(uncertain)
    }
}

// MARK: - Helper misc

struct SolveResult {
    let pointsToReveal: Set<Point>
    let pointsToFlag: Set<Point>
}
