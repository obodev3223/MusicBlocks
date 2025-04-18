//
//  TopBarType.swift
//  MusicBlocks
//
//  Created by Jose R. García on 18/4/25.
//

import Foundation

/// Enumeration defining the types of TopBar
enum TopBarType {
    /// Main TopBar (score, lives)
    case main
    
    /// Objectives TopBar (objectives, time)
    case objectives
    
    /// Converts TopBarType to ViewModel.BarType
    var toBarType: TopBarViewModel.BarType {
        switch self {
        case .main: return .main
        case .objectives: return .objectives
        }
    }
}
