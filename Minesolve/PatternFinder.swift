//
//  PatternFinder.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-21.
//

struct PatternFinder {
    
    // MARK: - Properties
    
    let util: Util
    
    let patterns: [String: [[PatternCell]]] = {
        var patterns: [String: [[PatternCell]]] = [:]
        
        patterns["Gate"] = [
            [.safe, .safe, .safe],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Antigate"] = [ // exceptionally rare
            [.mine, .mine, .mine],
            [.uncertain, .digit(4), .uncertain],
            [.certain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Exit"] = [
            [.safe, .safe, .safe],
            [.certain, .digit(1), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Antiexit"] = [
            [.mine, .mine, .mine],
            [.certain, .digit(4), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .certain, .certain],
        ]
        
        patterns["!!!!!!AntiexitVariant2!!!!!!!"] = [
            [.mine, .mine, .certain],
            [.certain, .digit(3), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Antiexit3"] = [
            [.mine, .certain, .certain],
            [.certain, .digit(2), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .certain, .certain],
        ]
        
        patterns["!!!!!!AntiexitVariant4!!!!!!!"] = [
            [.mine, .certain, .mine],
            [.certain, .digit(3), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Antiexit5"] = [
            [.certain, .mine, .certain],
            [.certain, .digit(2), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Arrow"] = [
            [.safe, .uncertain, .uncertain, .certain],
            [.uncertain, .digit(2), .digit(1), .certain],
            [.uncertain, .digit(1), .certain, .certain],
            [.certain, .certain, .certain, .any],
        ]
        
        patterns["Antiarrow"] = [
            [.mine, .uncertain, .uncertain, .certain],
            [.uncertain, .digit(3), .digit(1), .certain],
            [.uncertain, .digit(1), .certain, .certain],
            [.certain, .certain, .certain, .any],
        ]
        
        patterns["Outlet"] = [
            [.certain, .certain, .certain],
            [.uncertain, .digit(1), .certain],
            [.uncertain, .digit(1), .certain],
            [.safe, .safe, .safe],
        ]
        
        patterns["Antioutlet"] = [
            [.certain, .certain, .certain],
            [.uncertain, .digit(1), .certain],
            [.uncertain, .digit(4), .certain],
            [.mine, .mine, .mine],
        ]
        
        patterns["Punch"] = [
            [.mine, .certain, .certain],
            [.uncertain, .digit(2), .certain],
            [.uncertain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Softpunch"] = [
            [.certain, .mine, .certain],
            [.uncertain, .digit(2), .certain],
            [.uncertain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Rarepunch"] = [ // quite rare
            [.certain, .certain, .mine],
            [.uncertain, .digit(2), .certain],
            [.uncertain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        patterns["Outpunch"] = [
            [.mine, .mine, .certain],
            [.uncertain, .digit(3), .certain],
            [.uncertain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]

        patterns["Cranepunch"] = [
            [.mine, .certain, .mine],
            [.uncertain, .digit(3), .certain],
            [.uncertain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        patterns["!!!!!! PunchVariant4 !!!!!!"] = [
            [.certain, .mine, .mine],
            [.uncertain, .digit(3), .certain],
            [.uncertain, .digit(1), .certain],
            [.certain, .certain, .certain],
        ]
        
        return patterns
    }()
    
    // MARK: - Methods
    
    func findPatterns(in board: RenderedBoard, adjustedDigits: [Point: Int]) -> SolveResult {
        var pointsToFlag: Set<Point> = []
        var pointsToReveal: Set<Point> = []

        for (name, cells) in patterns {
            let pattern = Pattern(cells: cells)
            let (findCount, solveResult) = find(pattern: pattern, in: board, adjustedDigits: adjustedDigits)

            if findCount > 0 {
                print("Found \(findCount) \(name) patterns")
                pointsToFlag.formUnion(solveResult.pointsToFlag)
                pointsToReveal.formUnion(solveResult.pointsToReveal)
            }
        }
        
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    // MARK: - Private methods
    
    func find(pattern: Pattern, in board: RenderedBoard, adjustedDigits: [Point: Int]) -> (Int, SolveResult) {
        var foundPoints: Set<Point> = []
        var pointsToFlag: Set<Point> = []
        var pointsToReveal: Set<Point> = []
        
        for permutation in pattern.allPermutations {
            let leftmostX = 0 - permutation.width + 1
            let topmostY = 0 - permutation.height + 1
            let rightmostX = board.width - 1
            let bottommostY = board.height - 1
            
            var pointsToCheck: Set<Point> = []
            for y in topmostY...bottommostY {
                for x in leftmostX...rightmostX {
                    pointsToCheck.insert(.init(x: x, y: y))
                }
            }
            
            for point in pointsToCheck {
//                let rightX = point.x + permutation.width - 1
//                let bottomY = point.y + permutation.height - 1
//                
//                guard rightX < board.width, bottomY < board.height else {
//                    continue
//                }
                
                var isMatch = true
                var safePoints: Set<Point> = []
                var minePoints: Set<Point> = []
                
                for patternPoint in permutation.points {
                    let boardPoint = point + patternPoint
                    let patternCell = permutation.get(patternPoint)
                    let boardCell = board.isInBounds(boardPoint) ? board.get(boardPoint) : nil
                    
                    let (isMatchingCell, isSafeCell, isMineCell) = match(
                        boardCell: boardCell,
                        patternCell: patternCell,
                        adjusted: adjustedDigits[boardPoint]
                    )
                    
                    if !isMatchingCell {
                        isMatch = false
                        break
                    }
                    
                    if isSafeCell {
                        safePoints.insert(boardPoint)
                    } else if isMineCell {
                        minePoints.insert(boardPoint)
                    }
                }
                
                if safePoints.isEmpty && minePoints.isEmpty {
                    isMatch = false
                }
                
                if isMatch {
                    foundPoints.insert(point)
                    pointsToFlag.formUnion(minePoints)
                    pointsToReveal.formUnion(safePoints)
                }
            }
        }
        
        return (
            foundPoints.count,
            SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
        )
    }
    
    private func match(
        boardCell: RenderedCell?,
        patternCell: PatternCell,
        adjusted: Int? = nil
    ) -> (isMatch: Bool, isSafe: Bool, isMine: Bool) {
        
        var isMatch = true
        var isSafe = false
        var isMine = false
        
        guard let boardCell else {
            // nil boardCell means it is out of bounds
            // it should count as certain
            isMatch = patternCell == .any || patternCell == .certain

            return (isMatch, isSafe, isMine)
        }
        
        let isBoardCellUnrevealed = boardCell == .unrevealed
        switch patternCell {
        case .uncertain:
            isMatch = isMatch && isBoardCellUnrevealed
        case .certain:
            isMatch = isMatch && !isBoardCellUnrevealed
        case .digit(let n):
            isMatch = isMatch && (adjusted == n)
        case .safe:
            isSafe = isBoardCellUnrevealed
        case .mine:
            isMine = isBoardCellUnrevealed
        case .any:
            break
        }
        
        return (isMatch, isSafe, isMine)
    }
    
}

enum PatternCell: Hashable {
    case uncertain
    case certain
    case digit(_ n: Int) // after adjusting digits
    case safe
    case mine
    case any
}

struct Pattern: Hashable {
    
    let cells: [[PatternCell]]
    
    var width: Int { cells[0].count }
    var height: Int { cells.count }
    
    var points: Set<Point> {
        var result: Set<Point> = []
        
        for y in 0..<height {
            for x in 0..<width {
                let point = Point(x: x, y: y)
                result.insert(point)
            }
        }
        
        return result
    }
    
    var rotated: Self {
        let newWidth = height
        let newHeight = width
        
        var newCells: [[PatternCell]] = .init(repeating: .init(repeating: .uncertain, count: newWidth), count: newHeight)
        
        for y in 0..<newHeight {
            for x in 0..<newWidth {
                let oldX = y
                let oldY = newWidth - x - 1
                
                newCells[y][x] = cells[oldY][oldX]
            }
        }
        
        return .init(cells: newCells)
    }
    
    var mirrored: Self {
        var newCells = cells
        
        for y in 0..<height {
            for x in 0..<width {
                let oldX = width - x - 1
                let oldY = y
                
                newCells[y][x] = cells[oldY][oldX]
            }
        }
        
        return .init(cells: newCells)
    }

    var allRotations: [Self] {
        Array(Set([self, self.rotated, self.rotated.rotated, self.rotated.rotated.rotated]))
    }
    
    var allPermutations: [Self] {
        Array(Set((allRotations + allRotations.map(\.mirrored))))
    }
    
    func get(_ point: Point) -> PatternCell {
        cells[point.y][point.x]
    }
}
