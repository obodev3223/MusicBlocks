//
//  TopBarRendererFactory.swift
//  MusicBlocks
//
//  Created by Jose R. García on 18/4/25.
//

import Foundation
import SpriteKit

/// Factory for creating TopBar renderers based on the bar type
class TopBarRendererFactory {
    /// Creates and returns the appropriate renderer for the given bar type
    /// - Parameter barType: The type of TopBar to create a renderer for
    /// - Returns: A TopBarViewRenderer implementation appropriate for the given type
    static func createRenderer(for barType: TopBarViewModel.BarType) -> TopBarViewRenderer {
        switch barType {
        case .main:
            return MainTopBarRenderer()
        case .objectives:
            return ObjectivesTopBarRenderer()
        }
    }
}
