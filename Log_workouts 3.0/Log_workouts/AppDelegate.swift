import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        do{
            _ = try Realm()
        }
        catch{
            print("The error: \(error)")
        }
        
        
        let navigationBarAppearance = UINavigationBar.appearance()

        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white] // Set your desired title color
        navigationBarAppearance.isTranslucent = false // Ensure it's not translucent
        
        
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func toggleAppearanceMode() {
        let currentStyle = UITraitCollection.current.userInterfaceStyle
        let newStyle: UIUserInterfaceStyle = currentStyle == .dark ? .light : .dark
        
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            window.overrideUserInterfaceStyle = newStyle
        }
        
        // Optionally save the user's preference
        UserDefaults.standard.set(newStyle == .dark, forKey: "isDarkMode")
    }


    
}



