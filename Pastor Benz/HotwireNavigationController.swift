import UIKit

class HotwireNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the navigation bar completely
        setNavigationBarHidden(true, animated: false)
    }
}
