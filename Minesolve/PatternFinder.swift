//
//  PatternFinder.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-21.
//

struct PatternFinder {
    
    // MARK: - Properties
    
    let util: Util
    
    var patterns: [String: [[PatternCell]]] {
        var result: [String: [[PatternCell]]] = [:]
        
        result["Gate"] = [
            [.certain, .certain, .certain],
            [.certain, .digit(1), .certain],
            [.uncertain, .digit(1), .uncertain],
            [.safe, .safe, .safe],
        ]
        
        result["Antigate"] = [
            [.certain, .certain, .certain],
            [.uncertain, .digit(1), .uncertain],
            [.certain, .digit(1), .certain],
            [.safe, .safe, .safe],
        ]
        
        result["Corner"] = [
            [.safe, .uncertain, .uncertain, .certain],
            [.uncertain, .digit(2), .digit(1), .certain],
            [.uncertain, .digit(1), .certain, .certain],
            [.certain, .certain, .certain, .any],
        ]
        
        result["Outlet"] = [
            [.certain, .certain, .certain],
            [.uncertain, .digit(1), .certain],
            [.uncertain, .digit(1), .certain],
            [.safe, .certain, .certain],
        ]
        
        result["Anticorner"] = [
            [.mine, .uncertain, .uncertain, .certain],
            [.uncertain, .digit(3), .digit(1), .certain],
            [.uncertain, .digit(1), .certain, .certain],
            [.certain, .certain, .certain, .any],
        ]

        return result
    }
    
    // MARK: - Methods
    
    func findPatterns(in board: RenderedBoard) -> SolveResult {
        var pointsToFlag: Set<Point> = []
        var pointsToReveal: Set<Point> = []

        for (name, cells) in patterns {
            let pattern = Pattern(cells: cells)
            let (findCount, solveResult) = find(pattern: pattern, in: board)

            if findCount > 0 {
                print("Found \(findCount) \(name) patterns")
                pointsToFlag.formUnion(solveResult.pointsToFlag)
                pointsToReveal.formUnion(solveResult.pointsToReveal)
            }
        }
        
        return SolveResult(pointsToReveal: pointsToReveal, pointsToFlag: pointsToFlag)
    }
    
    // MARK: - Private methods
    
    func find(pattern: Pattern, in board: RenderedBoard) -> (Int, SolveResult) {
        let flagged = Set(board.allPoints.filter { board.get($0) == .flagged })
        let uncertain = board.allPoints.filter { board.get($0) == .unrevealed }
        let adjusted = adjustedDigits(board: board, flagged: flagged)
        
        var foundPoints: Set<Point> = []
        var pointsToFlag: Set<Point> = []
        var pointsToReveal: Set<Point> = []
        
        for permutation in pattern.allPermutations {
            for point in board.allPoints {
                let rightX = point.x + permutation.width - 1
                let bottomY = point.y + permutation.height - 1
                
                guard rightX < board.width, bottomY < board.height else {
                    continue
                }
                
                var isMatch = true
                var safePoints: Set<Point> = []
                var minePoints: Set<Point> = []
                
                for patternPoint in permutation.points {
                    let boardPoint = point + patternPoint
                    let patternCell = permutation.get(patternPoint)
                    
                    switch patternCell {
                    case .uncertain:
                        if !uncertain.contains(boardPoint) {
                            isMatch = false
                        }
                    case .certain:
                        if uncertain.contains(boardPoint) {
                            isMatch = false
                        }
                    case .digit(let n):
                        if adjusted[boardPoint] != n {
                            isMatch = false
                        }
                    case .safe:
                        if uncertain.contains(boardPoint) {
                            safePoints.insert(boardPoint)
                        }
                    case .mine:
                        if uncertain.contains(boardPoint) {
                            minePoints.insert(boardPoint)
                        }
                    case .any:
                        break
                    }
                    
                    if !isMatch {
                        break
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
    
    private func adjustedDigits(board: RenderedBoard, flagged: Set<Point>) -> [Point: Int] {
        let digits = board.allPoints.filter { board.get($0).isDigit() }
        
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
            
            let adjacentFlags = Set(util.adjacent(to: digit)).intersection(flagged)
            adjusted -= adjacentFlags.count
            
            result[digit] = adjusted
        }
        
        return result
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
