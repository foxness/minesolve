//
//  RenderedCell.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

enum RenderedCell: Equatable {
    case empty
    case mine
    case digit(Int)
    case unrevealed
    case flagged
    
    func isUnrevealed() -> Bool {
        switch self {
        case .unrevealed, .flagged:
            return true
        default:
            return false
        }
    }
    
    func isDigit() -> Bool {
        switch self {
        case .digit:
            return true
        default:
            return false
        }
    }
}
