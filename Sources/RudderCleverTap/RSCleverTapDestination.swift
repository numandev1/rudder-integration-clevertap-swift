
import Foundation
import Rudder
import CleverTapSDK

class RSCleverTapDestination: RSDestinationPlugin {
    let type = PluginType.destination
    let key = "Clevertap"
    var client: RSClient?
    var controller = RSController()
    
    //
    var accountId: String?
    var accountToken: String?
    var region: String?
    var logLevel: Int = 0
    
    
    func update(serverConfig: RSServerConfig, type: UpdateType) {
         guard type == .initial else { return }
         CleverTap.autoIntegrate()
         CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
         client?.log(message: "Initializing Clevertap SDK", logLevel: .debug)
     }
    
    func identify(message: IdentifyMessage) -> IdentifyMessage? {
        if let traits = extractTraits(properties: message.traits) {
            var profile = [String: Any]()
            for (key, value) in traits {
                switch key {
                case RSKeys.Identify.userId:
                    profile["Identity"] = value
                    break
                case RSKeys.Identify.Traits.email:
                    profile["Email"] = value
                    break
                case RSKeys.Identify.Traits.name:
                    profile["Name"] = value
                    break
                case RSKeys.Identify.Traits.phone:
                    profile["Phone"] = value
                    break
                case RSKeys.Identify.Traits.gender:
                    if let gender = value as? String {
                        if ["male", "m"].contains(gender.lowercased()) {
                            profile["Gender"] = "M"
                        } else if ["female", "f"].contains(gender.lowercased()) {
                            profile["Gender"] = "F"
                        }
                    }
                    break
                case RSKeys.Identify.Traits.birthday:
                    if let birthday = value as? String {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        profile["DOB"] = dateFormatter.date(from: birthday)
                    } else if let birthday = traits["birthday"] as? Date {
                        profile["DOB"] = birthday
                    }
                    break
                default:
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
            }
             CleverTap.sharedInstance()?.onUserLogin(profile)
        }
        return message
    }
    
    func track(message: TrackMessage) -> TrackMessage? {
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
        return message
    }
        
    func screen(message: ScreenMessage) -> ScreenMessage? {
        let screenName = message.name
        if let screenProperties = message.properties {
            CleverTap.sharedInstance()?.recordEvent("Screen Viewed: \(screenName)", withProps: screenProperties)
        } else {
            CleverTap.sharedInstance()?.recordEvent("Screen Viewed: \(screenName)")
        }
        return message
    }
    
    func reset() {
        client?.log(message: "Inside reset", logLevel: .debug)
    }
    
    func flush() {
        
    }
    
    func handleEcommerceEvent(_ message: TrackMessage) {
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

extension RSCleverTapDestination: RSPushNotifications {
    // Refer: https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/push_notifications/integration/
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        client?.log(message: "registering for remote notifications", logLevel: .debug)
        CleverTap.sharedInstance()?.setPushToken(deviceToken)
    }
        
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        client?.log(message: "handling action with identifier", logLevel: .debug)
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
    }
}


extension RSCleverTapDestination {
    func extractTraits(properties: [String: Any]?) -> [String: Any]? {
        var params: [String: Any]?
        if let properties = properties {
            params = [String: Any]()
            for (key, value) in properties {
                switch value {
                case let v as String:
                    params?[key] = v
                case let v as NSNumber:
                    params?[key] = v
                case let v as Bool:
                    params?[key] = v
                default:
                    break
                }
            }
        }
        return params
    }
}


@objc
public class RudderCleverTapDestination: RudderDestination {
    
    @objc
    public override init() {
        super.init()
        plugin = RSCleverTapDestination()
    }
    
}
