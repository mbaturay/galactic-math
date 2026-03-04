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

    /// Y position for back/nav buttons: in the notch zone (beside Dynamic Island)
    var navBarY: CGFloat {
        return size.height - (safeTop / 2)
    }

    /// Y position for the page title: just below safe area
    var titleSafeY: CGFloat {
        return size.height - safeTop - 40
    }

    /// Y position for first content element: below title
    var contentStartY: CGFloat {
        return size.height - safeTop - 110
    }
}
