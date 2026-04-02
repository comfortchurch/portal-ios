import UIKit
import HotwireNative

class CustomWebViewController: HotwireWebViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar for this view controller
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show it again when leaving (optional, depends on your needs)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
