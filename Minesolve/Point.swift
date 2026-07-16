//
//  Point.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

struct Point: Hashable, CustomStringConvertible {
    let x: Int
    let y: Int
    
    var description: String {
        "(\(x), \(y))"
    }
    
    static func +(lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func +=(lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }
}
