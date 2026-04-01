
import HotwireNative
import UIKit

final class TopAppBarBridge: BridgeComponent {
    override class var name: String { "top-app-bar-bridge" }
    
    private var currentData: MessageData?
    
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        let event = message.event
        
        if event == "connect" {
            handleConnectEvent(message: message)
        } else {
            print("⚠️ TopAppBarBridge: Unknown event '\(event)'")
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleConnectEvent(message: Message) {
        guard let data: MessageData = message.data() else {
            print("⚠️ TopAppBarBridge: Failed to decode MessageData")
            print("Message data: \(message)")
            return
        }
        
        currentData = data
        setupTopAppBarIcons(data: data)
    }
    
    // MARK: - UI Setup
    
    private func setupTopAppBarIcons(data: MessageData) {
        guard let viewController = viewController else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Set title
            viewController.navigationItem.title = "Pastor Benz"
            
            var rightBarItems: [UIBarButtonItem] = []
            
            // 1. Profile button (rightmost)
            let profileButton = self.createProfileButton(profileURL: data.profile)
            rightBarItems.append(profileButton)
            
            // 2. Notification button
            let notificationButton = self.createNotificationButton(info: data.info)
            rightBarItems.append(notificationButton)
            
            // 3. Language button (leftmost of right buttons)
            let languageButton = self.createLanguageButton()
            rightBarItems.append(languageButton)
            
            viewController.navigationItem.rightBarButtonItems = rightBarItems
        }
    }
    
    private func createLanguageButton() -> UIBarButtonItem {
        let action = UIAction { [weak self] _ in
            self?.languageButtonTapped()
        }
        
        // Use SF Symbol or your custom image
        let button = UIBarButtonItem(
            image: UIImage(systemName: "globe") ?? UIImage(named: "lang_switch"),
            primaryAction: action
        )
        button.tintColor = UIColor(red: 88/255, green: 43/255, blue: 30/255, alpha: 1.0)
        return button
    }
    
    private func createNotificationButton(info: String) -> UIBarButtonItem {
        let action = UIAction { [weak self] _ in
            self?.notificationButtonTapped()
        }
        
        // Match Android logic: "notifications_unread" shows bell.badge
        let imageName = info == "notifications_unread" ? "bell.badge" : "bell"
        let button = UIBarButtonItem(
            image: UIImage(systemName: imageName) ?? UIImage(named: "notifications"),
            primaryAction: action
        )
        button.tintColor = UIColor(red: 88/255, green: 43/255, blue: 30/255, alpha: 1.0)
        return button
    }
    
    private func createProfileButton(profileURL: String) -> UIBarButtonItem {
        let action = UIAction { [weak self] _ in
            self?.profileButtonTapped()
        }
        
        let button = UIBarButtonItem(
            image: UIImage(systemName: "person.circle.fill"),
            primaryAction: action
        )
        button.tintColor = UIColor(red: 88/255, green: 43/255, blue: 30/255, alpha: 1.0)
        
        // Load profile image asynchronously
        if !profileURL.isEmpty {
            loadProfileImage(from: profileURL) { [weak button] image in
                if let image = image {
                    let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 32, height: 32))
                    let roundedImage = self.makeImageCircular(image: resizedImage)
                    button?.image = roundedImage.withRenderingMode(.alwaysOriginal)
                }
            }
        }
        
        return button
    }
    
    // MARK: - Actions
    
    private func languageButtonTapped() {
        print("🌐 Language button tapped")
        reply(to: "connect", with: ["action": "language_clicked"])
    }
    
    private func notificationButtonTapped() {
        print("🔔 Notification button tapped")
        reply(to: "connect", with: [
            "action": "notification_clicked",
            "info": currentData?.info ?? "notifications"
        ])
    }
    
    private func profileButtonTapped() {
        print("👤 Profile button tapped")
        reply(to: "connect", with: [
            "action": "profile_clicked",
            "profile": currentData?.profile ?? ""
        ])
    }
    
    // MARK: - Image Loading
    
    private func loadProfileImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = CGSize(width: size.width * min(widthRatio, heightRatio),
                            height: size.height * min(widthRatio, heightRatio))
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func makeImageCircular(image: UIImage) -> UIImage {
        let minEdge = min(image.size.height, image.size.width)
        let size = CGSize(width: minEdge, height: minEdge)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.addEllipse(in: CGRect(origin: .zero, size: size))
        context?.clip()
        
        let origin = CGPoint(x: (size.width - image.size.width) / 2,
                           y: (size.height - image.size.height) / 2)
        image.draw(in: CGRect(origin: origin, size: image.size))
        
        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return circularImage ?? image
    }
}

// MARK: - Message Data Model

private extension TopAppBarBridge {
    struct MessageData: Decodable {
        let info: String      // "notifications_unread" or "notifications"
        let profile: String   // URL to profile image
    }
}
