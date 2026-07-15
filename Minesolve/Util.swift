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
    
    func getValidNeighbors(of point: Point) -> [Point] {
        getAdjacentPoints().compactMap { adjacent in
            let newPoint = point + adjacent
            return isValid(point: newPoint) ? newPoint : nil
        }
    }
    
    func getAdjacentPoints() -> [Point] {
        [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),         (0, 1),
            (1, -1), (1, 0), (1, 1),
        ]
            .map { .init(x: $0, y: $1) }
    }
}
