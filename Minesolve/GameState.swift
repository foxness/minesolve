//
//  GameState.swift
//  Minesolve
//
//  Created by River Deem on 2026-07-15.
//

enum GameState {
    case uninitialized
    case ongoing
    case win
    case loss
    
    func isOver() -> Bool {
        switch self {
        case .win, .loss:
            return true
        default:
            return false
        }
    }
}
