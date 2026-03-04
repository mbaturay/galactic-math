import SpriteKit
import UIKit

extension SKScene {
    /// Reliable safe area top inset with UIApplication fallback.
    /// SpriteKit's `view?.safeAreaInsets` sometimes returns 0; this uses
    /// the window scene as a backup.
    var safeTop: CGFloat {
        if let top = view?.safeAreaInsets.top, top > 0 {
            return top
        }
        return UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 59
    }

    /// Y position for back/nav buttons: screenHeight - safeTop - 22
    var navBarY: CGFloat {
        return size.height - safeTop - 22
    }

    /// Y position for the page title: screenHeight - safeTop - 50
    var titleSafeY: CGFloat {
        return size.height - safeTop - 50
    }

    /// Y position for first content element: screenHeight - safeTop - 120
    var contentStartY: CGFloat {
        return size.height - safeTop - 120
    }
}
