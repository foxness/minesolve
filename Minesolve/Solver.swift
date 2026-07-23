//
//  Solver.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

// todo:
// - store digit neighbors to not recalculate them
// - parallelize islands between threads
// - parallelize depth zero fork
// - remember flags from complex solutions in solver instead of
//       assuming that flags are correct
// - try solving half of big islands to check for guaranteed flags/reveals
// - apply heuristic: when you have to choose between
//       revealing multiple cells reveal the one that has least uncertain neighbors?
// - add instant replay / last board keybind

import Foundation

struct Solver {
    
    // MARK: - Constants
    
    let width: Int
    let height: Int
    
    // assume all placed flags are correct
    let assumeNoHuman = true
    
    // MARK: - Private properties
    
    private let util: Util
    private let patternFinder: PatternFinder
    
    private var setsOfIslandSolutions: [Island: [[Point: Bool]]] = [:]
    
    private var boardFlagged: Set<Point> = []
    private var boardDigits: [Point: Int] = [:]
    private var boardUnrevealed: Set<Point> = []

    // MARK: - Init
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        self.util = Util(width: width, height: height)
        self.patternFinder = PatternFinder(util: util)
    }
    
    // MARK: - Public methods
    
    mutating func newGame() {
        setsOfIslandSolutions.removeAll()
    }
    
    mutating func solve(board: RenderedBoard) -> SolveResult {
        boardFlagged = Set(board.allPoints.filter { board.get($0) == .flagged })
        boardDigits = Solver.getBoardDigits(in: board)

        let primitiveSolve = primitiveSolveStep(board: board)
        
        let primitiveFlagged = primitiveSolve.pointsToFlag
        let primitiveRevealed = primitiveSolve.pointsToReveal
        
        let newFlags = primitiveFlagged.subtracting(boardFlagged)
        
        guard primitiveRevealed.isEmpty && newFlags.isEmpty else {
            print("Primitive solution found (flags: \(newFlags.count), reveals: \(primitiveRevealed.count))")
            return SolveResult(pointsToReveal: primitiveRevealed, pointsToFlag: newFlags)
        }
        
        let adjustedDigits = getAdjustedDigits(board: board, from: Set(boardDigits.keys))
        let patternSolveResult = patternFinder.findPatterns(in: board, adjustedDigits: adjustedDigits)
        
        let patternFlagged = patternSolveResult.pointsToFlag
        let patternRevealed = patternSolveResult.pointsToReveal
        
        guard patternFlagged.isEmpty && patternRevealed.isEmpty else {
            if patternRevealed.count > 0 {
                print("Revealing \(patternRevealed.count) pattern points: \(patternRevealed)")
            }
            
            if patternFlagged.count > 0 {
                print("Flagging \(patternFlagged.count) pattern points: \(patternFlagged)")
            }
            
            return SolveResult(pointsToReveal: patternRevealed, pointsToFlag: patternFlagged)
        }
        
        var flagged = primitiveFlagged
        if assumeNoHuman {
            flagged.formUnion(boardFlagged)
        }
        
        return solveIslands(board: board)
    }

    func primitiveSolveStep(board: RenderedBoard) -> SolveResult {
        let primitiveFlagged = primitiveFlag(board: board)
        let primitiveRevealed = primitiveReveal(board: board, primitiveFlagged: primitiveFlagged)
        
        return SolveResult(pointsToReveal: primitiveRevealed, pointsToFlag: primitiveFlagged)
    }
    
    // MARK: - Private methods
    
    private mutating func solveIslands(board: RenderedBoard) -> SolveResult {
        boardUnrevealed = Set(board.allPoints.filter { board.get($0) == .unrevealed })
        
        let lightDigits = Set(boardDigits.keys.filter { digit in
            let neighbors = util.adjacent(to: digit)
            let isTouchingUnrevealed = neighbors.contains { board.get($0) == .unrevealed }
            return isTouchingUnrevealed
        })
        
        let pseudoIslands = divideLightDigitIslands(board: board, lightDigits: lightDigits)
        let digitIslands = mergeIntoTrueIslands(pseudoIslands: pseudoIslands, board: board)
        print("Islands: \(digitIslands.count)")
        
        let islands = digitIslands
            .map { digits in
                let uncertain = Set(digits.flatMap { util.adjacent(to: $0) }).filter { board.get($0) == .unrevealed }
                return Island(uncertain: uncertain, digits: digits)
            }
            .sorted { $0.uncertain.count < $1.uncertain.count }

        var currentSetsOfSolutions: [[[Point: Bool]]] = []
        var islandsToKeep: Set<Island> = []
        
        for island in islands {
            if let setOfSolutions = setsOfIslandSolutions[island] {
                islandsToKeep.insert(island)
                print("Found an already solved island of \(island.uncertain.count)")
                
                let pruned = pruneForNewMinesLeft(setOfSolutions: setOfSolutions, board: board)
                if pruned.count < setOfSolutions.count {
                    print("Island has pruned from \(setOfSolutions.count) to \(pruned.count)")
                }
                
                setsOfIslandSolutions[island] = pruned
                currentSetsOfSolutions.append(pruned)
                continue
            }
            
            print("Solving island of \(island.uncertain.count)")
            let setOfSolutions = solveIsland(island, board: board)
            print("Solutions: \(setOfSolutions.count)")
            
            setsOfIslandSolutions[island] = setOfSolutions
            islandsToKeep.insert(island)
            
            currentSetsOfSolutions.append(setOfSolutions)
        }
        
        print("Forgetting solutions of \(setsOfIslandSolutions.keys.count - islandsToKeep.count) islands")
        setsOfIslandSolutions = setsOfIslandSolutions.filter { key, value in islandsToKeep.contains(key) }
        
        let (darkIsland, minDarkIslandMines, maxDarkIslandMines) = solveDarkIsland(board: board, currentSetsOfSolutions: currentSetsOfSolutions)
        
        return formSolution(
            currentSetsOfSolutions,
            darkIsland: darkIsland,
            minDarkIslandMines: minDarkIslandMines,
            maxDarkIslandMines: maxDarkIslandMines
        )
    }
    
    private func pruneForNewMinesLeft(setOfSolutions: [[Point: Bool]], board: RenderedBoard) -> [[Point: Bool]] {
        let minesLeft = board.mines - boardFlagged.count
        return setOfSolutions.filter { solution in
            let mineCount = solution.values.count { $0 }
            return mineCount <= minesLeft
        }
    }
    
    private func solveDarkIsland(board: RenderedBoard, currentSetsOfSolutions: [[[Point: Bool]]]) -> (Set<Point>, Int, Int) {
        var darkIsland: Set<Point> = [] // points that dont touch a digit
        for point in boardUnrevealed {
            let neighbors = util.adjacent(to: point)
            let isTouchingDigit = neighbors.contains { board.get($0).isDigit() }
            
            if !isTouchingDigit {
                darkIsland.insert(point)
            }
        }
        
        var minTotalMines = 0
        var maxTotalMines = 0
        for setOfSolutions in currentSetsOfSolutions {
            let mineCounts = setOfSolutions.map { solution in solution.values.count { $0 } }
            
            minTotalMines += mineCounts.min()!
            maxTotalMines += mineCounts.max()!
        }
        
        let minDarkIslandMines = max(0, board.mines - (boardFlagged.count + maxTotalMines))
        let maxDarkIslandMines = min(darkIsland.count, board.mines - (boardFlagged.count + minTotalMines))
        
        return (darkIsland, minDarkIslandMines, maxDarkIslandMines)
    }
    
    private func formSolution(
        _ setOfIslandSolutions: [[[Point: Bool]]],
        darkIsland: Set<Point>,
        minDarkIslandMines: Int,
        maxDarkIslandMines: Int
    ) -> SolveResult {
        
        var mineProbabilities: [Point: Double] = [:]
        
        if !darkIsland.isEmpty {
            let minDarkIslandProbability = Double(minDarkIslandMines) / Double(darkIsland.count)
            let maxDarkIslandProbability = Double(maxDarkIslandMines) / Double(darkIsland.count)
            
            darkIsland.forEach { mineProbabilities[$0] = maxDarkIslandProbability }
            
            let minProbabilityString = String(format: "%.5f", minDarkIslandProbability)
            let maxProbabilityString = String(format: "%.5f", maxDarkIslandProbability)
            print("Dark island size: \(darkIsland.count), min: \(minDarkIslandMines) (\(minProbabilityString)), max: \(maxDarkIslandMines) (\(maxProbabilityString))")
        } else {
            print("Dark island is empty")
        }

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
        let safePoints = Set(sortedProbabilities.filter { (key, value) in value == 0 }.map(\.0))
        
        var safeString = "Found \(safePoints.count) safe"
        let safeDarkIsland = darkIsland.intersection(safePoints)
        if !safeDarkIsland.isEmpty {
            safeString += " (\(safeDarkIsland.count) from dark island)"
        }
        
        print(safeString)

        let pointsToReveal: Set<Point>
        if safePoints.isEmpty {
            let lowestProbability = sortedProbabilities.first!.1
            let riskyPoints = sortedProbabilities.filter { $1 == lowestProbability }.map(\.0)
            let riskyPoint = riskyPoints.randomElement()!
            
            let lowProbString = String(format: "%.5f", lowestProbability)
            var riskyString = "Found \(riskyPoints.count) equally risky cells with probability \(lowProbString)"
            riskyString += " and randomly chose \(riskyPoint)"
            
            if darkIsland.contains(riskyPoint) {
                riskyString += " (from a dark island)"
            }
            
            print(riskyString)
            pointsToReveal = [riskyPoint]
        } else {
            pointsToReveal = safePoints
        }
        
        var pointsToFlag = Set(sortedProbabilities.filter { (key, value) in value == 1 }.map(\.0))
        
        if minDarkIslandMines != maxDarkIslandMines {
            pointsToFlag.subtract(darkIsland)
        }
        
        print("Flagging \(pointsToFlag.count), revealing: \(pointsToReveal.count)")
        print("Revealing: \(pointsToReveal)")
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    private func solveIsland(_ island: Island, board: RenderedBoard) -> [[Point: Bool]] {
        var setOfSolutions: [[Point: Bool]] = []
        
        let minesLeft = board.mines - boardFlagged.count
        let adjustedDigits = getAdjustedDigits(board: board, from: island.digits)

        var current: [Point: Bool?] = [:] // [coord: isMine?]
        island.uncertain.forEach { current.updateValue(nil, forKey: $0) }
        
        depthSolveIsland(
            current: current,
            last: nil,
            digits: adjustedDigits,
            minesLeft: minesLeft,
            depth: 0,
            solutions: &setOfSolutions
        )
        
        return setOfSolutions
    }
    
    private func depthSolveIsland(
        current: [Point: Bool?],
        last: Point?,
        digits: [Point: Int],
        minesLeft: Int,
        depth: Int,
        solutions: inout [[Point: Bool]]
    ) {
        let solved = current.keys.filter { current[$0]! != nil }

        if let last {
            let digitsToCheck = Set(util.adjacent(to: last)).intersection(digits.keys)
            for point in digitsToCheck {
                let digitValue = digits[point]!
                
                let neighbors = Set(util.adjacent(to: point)).intersection(current.keys)
                let unsolvedNeighbors = neighbors.subtracting(solved)
                if !unsolvedNeighbors.isEmpty {
                    continue
                }
                
                let mineCount = neighbors.compactMap { current[$0]! }.count { $0 }
                if digitValue != mineCount {
                    return
                }
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
        depthSolveIsland(
            current: newCurrent,
            last: pointToSolve,
            digits: digits,
            minesLeft: minesLeft,
            depth: depth + 1,
            solutions: &solutions
        )
        
        let newMinesLeft = minesLeft - 1
        guard newMinesLeft >= 0 else {
            return
        }
        
        newCurrent[pointToSolve] = true
        depthSolveIsland(
            current: newCurrent,
            last: pointToSolve,
            digits: digits,
            minesLeft: newMinesLeft,
            depth: depth + 1,
            solutions: &solutions
        )
    }
    
    private func getAdjustedDigits(board: RenderedBoard, from digits: Set<Point>) -> [Point: Int] {
        var result: [Point: Int] = [:]
        
        for digit in digits {
            var adjusted: Int
            if case .digit(let n) = board.get(digit) {
                adjusted = n
            } else {
                fatalError()
            }

            let adjacentFlags = util.adjacent(to: digit).filter { board.get($0) == .flagged }
            adjusted -= adjacentFlags.count

            result[digit] = adjusted
        }

        return result
    }

    private func mergeIntoTrueIslands(pseudoIslands: [Set<Point>], board: RenderedBoard) -> [Set<Point>] {
        var merged = pseudoIslands
        
        while true {
            let newMerged = mergeIntoTrueIslandsStep(pseudoIslands: merged, board: board)
            if newMerged.count == merged.count {
                break
            }
            
            merged = newMerged
        }
        
        return merged
    }

    private func mergeIntoTrueIslandsStep(pseudoIslands: [Set<Point>], board: RenderedBoard) -> [Set<Point>] {
        guard pseudoIslands.count > 1 else { return pseudoIslands }
        // preudo islands and true islands are digits
        
        var trueIslands: [Set<Point>] = []
        
        var islands: [Island] = []
        for digitIsland in pseudoIslands {
            let uncertainIsland = Set(digitIsland.flatMap { util.adjacent(to: $0) }).filter { board.get($0) == .unrevealed }
            islands.append(Island(uncertain: uncertainIsland, digits: digitIsland))
        }
        
        while !islands.isEmpty {
            let firstIsland = islands.removeFirst()
            let (digitIsland, uncertainIsland) = (firstIsland.digits, firstIsland.uncertain)
            
            var digitIslandsToMerge: [Set<Point>] = []
            for otherIsland in islands {
                let (otherDigitIsland, otherUncertainIsland) = (otherIsland.digits, otherIsland.uncertain)
                
                let shouldMerge = !uncertainIsland.intersection(otherUncertainIsland).isEmpty
                if shouldMerge {
                    digitIslandsToMerge.append(otherDigitIsland)
                }
            }
            
            islands.removeAll { island in digitIslandsToMerge.contains(island.digits) }
            
            var trueIsland = digitIsland
            for islandToMerge in digitIslandsToMerge {
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
        var primitiveFlagged: Set<Point> = []
        
        for (point, n) in boardDigits {
            let neighbors = util.adjacent(to: point)
            let unrevealedNeighbors = Set(neighbors.filter { board.get($0).isUnrevealed() })
            
            if unrevealedNeighbors.count == n {
                primitiveFlagged.formUnion(unrevealedNeighbors)
            }
        }
        
        return primitiveFlagged
    }
    
    private func primitiveReveal(board: RenderedBoard, primitiveFlagged: Set<Point>) -> Set<Point> {
        var primitiveRevealed: Set<Point> = []
        
        var flagged = primitiveFlagged
        if assumeNoHuman {
            flagged.formUnion(boardFlagged)
        }
        
        var digitsToReveal: Set<Point> = []
        for point in flagged {
            let digitNeighbors = util.adjacent(to: point).filter { board.get($0).isDigit() }
            digitsToReveal.formUnion(digitNeighbors)
        }
        
        for digitPoint in digitsToReveal {
            let neighbors = Set(util.adjacent(to: digitPoint))
            let flaggedNeighbors = neighbors.intersection(flagged)
            
            if case let .digit(n) = board.get(digitPoint), flaggedNeighbors.count == n {
                let unrevealedNeighbors = neighbors.filter { board.get($0) == .unrevealed }
                primitiveRevealed.formUnion(unrevealedNeighbors)
            }
        }
        
        return primitiveRevealed
    }
    
    private func convertToUncertainIsland(digitIsland: Set<Point>, uncertain: Set<Point>) -> Set<Point> {
        Set(digitIsland.flatMap { util.adjacent(to: $0) }).intersection(uncertain)
    }
    
    private static func getBoardDigits(in board: RenderedBoard) -> [Point: Int] {
        Dictionary(uniqueKeysWithValues: board.allPoints.compactMap { point in
            guard case let .digit(n) = board.get(point) else { return nil }
            return (point, n)
        })
    }
}

// MARK: - Helper misc

struct SolveResult {
    let pointsToReveal: Set<Point>
    let pointsToFlag: Set<Point>
}

struct Island: Hashable {
    let uncertain: Set<Point>
    let digits: Set<Point>
}
