//
//  PatternFinder.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-21.
//

struct PatternFinder {
    
    // MARK: - Properties
    
    let util: Util
    
    // MARK: - Methods
    
    func findPatterns(in board: RenderedBoard) -> Set<Point> {
        var pointsToReveal: Set<Point> = []
        
        let (gateCounts, gateSafePoints) = findGatePattern(in: board)
        if !gateSafePoints.isEmpty {
            print("Found \(gateCounts) gate patterns")
            print("Safe gate pattern points: \(gateSafePoints.count)")
            
            pointsToReveal.formUnion(gateSafePoints)
        }
        
        let (antigateCounts, antigateSafePoints) = findAntigatePattern(in: board)
        if !antigateSafePoints.isEmpty {
            print("Found \(antigateCounts) antigate patterns")
            print("Safe antigate pattern points: \(antigateSafePoints.count)")
            
            pointsToReveal.formUnion(antigateSafePoints)
        }
        
        return pointsToReveal
    }

    func findGatePattern(in board: RenderedBoard) -> (Int, Set<Point>) {
        let gatePatternCells: [[PatternCell]] =
        [
            [.certain, .certain, .certain],
            [.certain, .one, .certain],
            [.uncertain, .one, .uncertain],
            [.safe, .safe, .safe],
        ]
        
        let gatePattern = Pattern(cells: gatePatternCells)
        return find(pattern: gatePattern, in: board)
    }

    func findAntigatePattern(in board: RenderedBoard) -> (Int, Set<Point>) {
        let gatePatternCells: [[PatternCell]] =
        [
            [.certain, .certain, .certain],
            [.uncertain, .one, .uncertain],
            [.certain, .one, .certain],
            [.safe, .safe, .safe],
        ]
        
        let gatePattern = Pattern(cells: gatePatternCells)
        return find(pattern: gatePattern, in: board)
    }
    
    // MARK: - Private methods
    
    func find(pattern: Pattern, in board: RenderedBoard) -> (Int, Set<Point>) {
        let flagged = Set(board.allPoints.filter { board.get($0) == .flagged })
        let uncertain = board.allPoints.filter { board.get($0) == .unrevealed }
        let adjusted = adjustedDigits(board: board, flagged: flagged)
        
        var foundPoints: Set<Point> = []
        var pointsToReveal: Set<Point> = []
        
        for rotation in pattern.allRotations {
            for point in board.allPoints {
                let rightX = point.x + rotation.width - 1
                let bottomY = point.y + rotation.height - 1
                
                guard rightX < board.width, bottomY < board.height else {
                    continue
                }
                
                var isMatch = true
                var safePoints: Set<Point> = []
                for patternPoint in rotation.points {
                    let boardPoint = point + patternPoint
                    let patternCell = rotation.get(patternPoint)
                    
                    switch patternCell {
                    case .uncertain:
                        if !uncertain.contains(boardPoint) {
                            isMatch = false
                        }
                    case .certain:
                        if uncertain.contains(boardPoint) {
                            isMatch = false
                        }
                    case .one:
                        if adjusted[boardPoint] != 1 {
                            isMatch = false
                        }
                    case .safe:
                        if uncertain.contains(boardPoint) {
                            safePoints.insert(boardPoint)
                        }
                    }
                    
                    if !isMatch {
                        break
                    }
                }
                
                if safePoints.isEmpty {
                    isMatch = false
                }
                
                if isMatch {
                    foundPoints.insert(point)
                    pointsToReveal.formUnion(safePoints)
                }
            }
        }
        
        return (foundPoints.count, pointsToReveal)
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

enum PatternCell {
    case uncertain
    case certain
    case one // after adjusting digits
    case safe
}

struct Pattern {
    let cells: [[PatternCell]]
    
    var width: Int {
        return cells[0].count
    }
    
    var height: Int {
        return cells.count
    }
    
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
    
    var rotated: Pattern {
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
    
    var allRotations: [Pattern] {
        [self, self.rotated, self.rotated.rotated, self.rotated.rotated.rotated]
    }
    
    func get(_ point: Point) -> PatternCell {
        cells[point.y][point.x]
    }
}
