//
//  RenderedCell.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

enum RenderedCell: Equatable {
    case empty
    case mine
    case number(Int)
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
}
