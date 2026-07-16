//
//  Util.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

struct Util {
    let width: Int
    let height: Int
    
    func isValid(point: Point) -> Bool {
        point.x >= 0 && point.x < width && point.y >= 0 && point.y < height
    }
    
    func adjacent(to point: Point) -> [Point] {
        adjacentPoints().compactMap { adjacentOffset in
            let newPoint = point + adjacentOffset
            return isValid(point: newPoint) ? newPoint : nil
        }
    }
    
    func touching(point: Point) -> Set<Point> {
        Set(touchingPoints().compactMap { touchingOffset in
            let newPoint = point + touchingOffset
            return isValid(point: newPoint) ? newPoint : nil
        })
    }

    func adjacentPoints() -> [Point] {
        [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),         (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
            .map { .init(x: $0, y: $1) }
    }
    
    func touchingPoints() -> [Point] {
        [
            (-1, 0), (1, 0),
            (0, -1), (0, 1),
        ]
            .map { .init(x: $0, y: $1) }
    }
}
