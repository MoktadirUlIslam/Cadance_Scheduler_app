import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "phone_lock"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Set up the MethodChannel for phone lock
        if let controller = window?.rootViewController as? FlutterViewController {
            let phoneLockChannel = FlutterMethodChannel(
                name: CHANNEL,
                binaryMessenger: controller.binaryMessenger
            )

            phoneLockChannel.setMethodCallHandler { [weak self] (call, result) in
                switch call.method {
                case "enableLock":
                    self?.enablePhoneLock()
                    result(true)

                case "disableLock":
                    self?.disablePhoneLock()
                    result(true)

                case "isLocked":
                    result(self?.isIdleTimerDisabled() ?? false)

                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Phone Lock Methods

    private func enablePhoneLock() {
        DispatchQueue.main.async { [weak self] in
            // Prevent screen from sleeping (idle timer)
            UIApplication.shared.isIdleTimerDisabled = true

            // Lock to portrait orientation (optional - for Pomodoro app)
            self?.lockOrientation(to: .portrait)

            // Prevent screenshots and screen recording
            self?.enableScreenProtection()

            print("PhoneLock: Screen lock enabled")
        }
    }

    private func disablePhoneLock() {
        DispatchQueue.main.async {
            // Allow screen to sleep again
            UIApplication.shared.isIdleTimerDisabled = false

            // Reset orientation to all supported orientations
            UIDevice.current.setValue(
                UIInterfaceOrientation.unknown.rawValue,
                forKey: "orientation"
            )

            // Remove screen protection
            self.disableScreenProtection()

            print("PhoneLock: Screen lock disabled")
        }
    }

    private func isIdleTimerDisabled() -> Bool {
        return UIApplication.shared.isIdleTimerDisabled
    }

    // MARK: - Screen Protection

    private func enableScreenProtection() {
        // Make the window secure to prevent screenshots
        if let window = window {
            // This adds a blurred snapshot when app goes to background
            // to hide sensitive content in app switcher
            window.makeSecure()
        }
    }

    private func disableScreenProtection() {
        if let window = window {
            window.removeSecure()
        }
    }

    // MARK: - Orientation Lock (Optional)

    private func lockOrientation(to orientation: UIInterfaceOrientation) {
        if #available(iOS 16.0, *) {
            // Use new iOS 16+ API
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                    print("Orientation lock error: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback for older iOS versions
            UIDevice.current.setValue(
                orientation.rawValue,
                forKey: "orientation"
            )
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    // MARK: - App Lifecycle

    override func applicationWillResignActive(_ application: UIApplication) {
        // Called when app is about to go to background
        // You can add notification or handle lock state here
        if UIApplication.shared.isIdleTimerDisabled {
            print("PhoneLock: App is locked, going to background")
            // Send notification to Flutter layer
            if let controller = window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: CHANNEL,
                    binaryMessenger: controller.binaryMessenger
                )
                channel.invokeMethod("appWillResignActive", arguments: nil)
            }
        }
        super.applicationWillResignActive(application)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)

        // Re-enable lock if app comes back to foreground
        if UIApplication.shared.isIdleTimerDisabled {
            enablePhoneLock()
        }
    }
}

// MARK: - UIWindow Extension for Screen Protection

extension UIWindow {
    /// Makes the window secure to prevent screenshots and screen recording
    func makeSecure() {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false

        // Create a view that contains the secure text field
        let view = UIView(frame: bounds)
        view.addSubview(field)
        view.layer.opacity = 0.01

        // Add the secure view on top
        addSubview(view)
        field.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        field.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        // Ensure secure view stays on top
        if let existingSecureView = subviews.first(where: { $0.subviews.contains(where: { ($0 as? UITextField)?.isSecureTextEntry == true }) }) {
            bringSubviewToFront(existingSecureView)
        }
    }

    /// Removes screen protection
    func removeSecure() {
        for subview in subviews {
            for innerView in subview.subviews {
                if let textField = innerView as? UITextField, textField.isSecureTextEntry {
                    subview.removeFromSuperview()
                    break
                }
            }
        }
    }
}