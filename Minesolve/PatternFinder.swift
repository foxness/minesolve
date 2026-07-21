//
//  PatternFinder.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-21.
//

struct PatternFinder {
    
    let util: Util
    
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

    func findGatePattern(in board: RenderedBoard) -> Set<Point> {
        let gatePatternCells: [[PatternCell]] =
        [
            [.certain, .certain, .certain],
            [.certain, .one, .certain],
            [.uncertain, .one, .uncertain],
            [.safe, .safe, .safe],
        ]
        
        let gatePattern = Pattern(cells: gatePatternCells)
        
        let flagged = Set(board.allPoints.filter { board.get($0) == .flagged })
        let uncertain = board.allPoints.filter { board.get($0) == .unrevealed }
        let adjusted = adjustedDigits(board: board, flagged: flagged)
        
        // todo: rotate

        var foundPoints: Set<Point> = []
        var pointsToReveal: Set<Point> = []
        for point in board.allPoints {
            let rightX = point.x + gatePattern.width - 1
            let bottomY = point.y + gatePattern.height - 1
            
            guard rightX < board.width, bottomY < board.height else {
                continue
            }
            
            var isMatch = true
            var safePoints: Set<Point> = []
            for patternPoint in gatePattern.points {
                let boardPoint = point + patternPoint
                let patternCell = gatePattern.get(patternPoint)
                
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
        
        if !foundPoints.isEmpty {
            print("!!! Found gate patterns at: \(foundPoints) !!!")
        }
        
        return pointsToReveal
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
    
    func get(_ point: Point) -> PatternCell {
        cells[point.y][point.x]
    }
}
