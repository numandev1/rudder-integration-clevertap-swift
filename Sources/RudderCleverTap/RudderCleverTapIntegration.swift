
import Foundation
import Rudder
import CleverTapSDK

@objc class RudderCleverTapIntegration: NSObject, RSIntegration {
    
    var accountId: String?
    var accountToken: String?
    var region: String?
    var logLevel: Int = 0
    
    // MARK: - Initialization
    @objc init(config: [String: Any], analytics: RSClient, rudderConfig: RSConfig) {
        super.init()
        
        self.accountId = config["accountId"] as? String
        self.accountToken = config["accountToken"] as? String
        self.region = config["region"] as? String
        self.logLevel = rudderConfig.logLevel
        
        if let accountId = self.accountId, let accountToken = self.accountToken {
            if region != "none" {
                CleverTap.setCredentialsWithAccountID(accountId, token: accountToken, region: region!)
            } else {
                CleverTap.setCredentialsWithAccountID(accountId, token: accountToken)
            }
            
            CleverTap.sharedInstance()?.notifyApplicationLaunched(options: nil)
            
            switch logLevel {
            case RSLogLevel.debug.rawValue:
                CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
            case RSLogLevel.none.rawValue:
                CleverTap.setDebugLevel(CleverTapLogLevel.off.rawValue)
            default:
                CleverTap.setDebugLevel(CleverTapLogLevel.info.rawValue)
            }
            
            RSLogger.logDebug("Initializing CleverTap SDK")
        } else {
            RSLogger.logWarn("Failed to Initialize CleverTap Factory")
        }
    }
    
    // MARK: - Event Handlers
    func dump(_ message: RSMessage) {
        processRudderEvent(message)
    }
    
    func reset() {
        RSLogger.logDebug("Inside reset")
    }
    
    func flush() {
        // Flush logic, if any
    }
    
    func processRudderEvent(_ message: RSMessage) {
        let type = message.type
        if type == "identify" {
            var traits = message.context.traits?.mutableCopy() as? [String: Any] ?? [:]
            var profile = [String: Any]()
            let userId = message.userId
            
            if let userId = userId {
                profile["Identity"] = userId
                traits.removeValue(forKey: "userId")
            }
            
            if let email = traits["email"] as? String {
                profile["Email"] = email
                traits.removeValue(forKey: "email")
            }
            
            if let name = traits["name"] as? String {
                profile["Name"] = name
                traits.removeValue(forKey: "name")
            }
            
            if let phone = traits["phone"] as? String {
                profile["Phone"] = phone
                traits.removeValue(forKey: "phone")
            }
            
            if let gender = traits["gender"] as? String {
                if ["male", "m"].contains(gender.lowercased()) {
                    profile["Gender"] = "M"
                } else if ["female", "f"].contains(gender.lowercased()) {
                    profile["Gender"] = "F"
                }
                traits.removeValue(forKey: "gender")
            }
            
            if let birthday = traits["birthday"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd"
                profile["DOB"] = dateFormatter.date(from: birthday)
                traits.removeValue(forKey: "birthday")
            } else if let birthday = traits["birthday"] as? Date {
                profile["DOB"] = birthday
                traits.removeValue(forKey: "birthday")
            }
            
            for (key, value) in traits {
                if !(value is [String: Any]) {
                    profile[key] = value
                } else if ["address", "company"].contains(key) {
                    var nestedMap = value as! [String: Any]
                    for (nestedKey, nestedValue) in nestedMap {
                        if nestedKey == "id" {
                            profile["companyId"] = nestedValue
                        } else if nestedKey == "name" {
                            profile["companyName"] = nestedValue
                        } else {
                            profile[nestedKey] = nestedValue
                        }
                    }
                }
            }
            
            CleverTap.sharedInstance()?.onUserLogin(profile)
            
        } else if type == "track" {
            let eventName = message.event
            if eventName == "Order Completed" {
                handleEcommerceEvent(message)
            } else {
                if let eventProperties = message.properties {
                    CleverTap.sharedInstance()?.recordEvent(eventName, withProps: eventProperties)
                } else {
                    CleverTap.sharedInstance()?.recordEvent(eventName)
                }
            }
        } else if type == "screen" {
            let screenName = message.event
            if let screenProperties = message.properties {
                CleverTap.sharedInstance()?.recordEvent("Screen Viewed: \(screenName)", withProps: screenProperties)
            } else {
                CleverTap.sharedInstance()?.recordEvent("Screen Viewed: \(screenName)")
            }
        } else {
            RSLogger.logDebug("CleverTap Integration: Message type not supported")
        }
    }
    
    // MARK: - Push Notification Methods
    func registeredForRemoteNotifications(withDeviceToken deviceToken: Data) {
        RSLogger.logDebug("registering for remote notifications")
        CleverTap.sharedInstance()?.setPushToken(deviceToken)
    }
    
    func receivedRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        RSLogger.logDebug("received remote notification")
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
    }
    
    func handleAction(withIdentifier identifier: String, forRemoteNotification userInfo: [AnyHashable: Any]) {
        RSLogger.logDebug("handling action with identifier")
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
    }
    
    // MARK: - Utils
    func handleEcommerceEvent(_ message: RSMessage) {
        guard let eventProperties = message.properties else { return }
        
        var chargeDetails = [String: Any]()
        var items = [Any]()
        
        for (key, value) in eventProperties {
            if key == "products", let products = value as? [[String: Any]] {
                items = getProductList(products)
            } else if value is [String: Any] || value is [Any] {
                continue
            } else if key == "order_id" {
                chargeDetails["Charged ID"] = value
            } else if key == "revenue" {
                chargeDetails["Amount"] = value
            } else {
                chargeDetails[key] = value
            }
        }
        
        CleverTap.sharedInstance()?.recordChargedEvent(withDetails: chargeDetails, andItems: items)
    }
    
    func getProductList(_ products: [[String: Any]]) -> [Any] {
        return products.map { product in
            var transformedProduct = [String: Any]()
            for (key, value) in product {
                transformedProduct[key == "product_id" ? "id" : key] = value
            }
            return transformedProduct
        }
    }
}
