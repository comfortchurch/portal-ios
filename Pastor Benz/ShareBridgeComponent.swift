import Foundation
import HotwireNative
import UIKit

final class ShareBridgeComponent: BridgeComponent {
    override class var name: String { "share" }
    
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }
    
    override func onReceive(message: Message) {
        guard let data: ShareData = message.data() else {
            print("⚠️ ShareBridgeComponent: Failed to decode ShareData")
            return
        }
        
        presentShareSheet(with: data)
    }
    
    private func presentShareSheet(with data: ShareData) {
        guard let viewController = viewController else { return }
        
        DispatchQueue.main.async {
            var itemsToShare: [Any] = []
            
            if let text = data.text {
                itemsToShare.append(text)
            }
            
            if let url = data.url, let shareURL = URL(string: url) {
                itemsToShare.append(shareURL)
            }
            
            guard !itemsToShare.isEmpty else {
                print("⚠️ ShareBridgeComponent: No items to share")
                return
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: itemsToShare,
                applicationActivities: nil
            )
            
            // For iPad support
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(
                    x: viewController.view.bounds.midX,
                    y: viewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popoverController.permittedArrowDirections = []
            }
            
            viewController.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Message Data Model

private extension ShareBridgeComponent {
    struct ShareData: Decodable {
        let text: String?
        let url: String?
    }
}
