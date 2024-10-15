import Foundation
import Rudder

class RudderCleverTapFactory: NSObject, RSIntegrationFactory {
    
    // Shared instance
    static let sharedInstance = RudderCleverTapFactory()
    
    // Private initializer to enforce singleton
    private override init() {
        super.init()
    }

    // Class function to get the shared instance
    class func instance() -> RudderCleverTapFactory {
        return sharedInstance
    }
    
    // Function to return the integration key
    func key() -> String {
        return "CleverTap"
    }

    // Function to initiate the integration
    func initiate(config: [AnyHashable: Any], client: RSClient, rudderConfig: RSConfig) -> RSIntegration {
        RSLogger.logDebug("Creating RudderIntegrationFactory: CleverTap")
        return RudderCleverTapIntegration(config: config, withAnalytics: client, withRudderConfig: rudderConfig)
    }
}
