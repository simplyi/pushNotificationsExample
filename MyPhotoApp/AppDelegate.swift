//
//  AppDelegate.swift
//  MyPhotoApp
//
//  Created by Sergey Kargopolov on 2016-02-08.
//  Copyright © 2016 Sergey Kargopolov. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var settings: UIUserNotificationSettings?
  
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { (isSuccess, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            })
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
         application.registerForRemoteNotifications()
 
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var deviceTokenString = ""
        for i in 0..<deviceToken.count {
            deviceTokenString = deviceTokenString + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        
        // Check if application notification settings
        let settings = UIApplication.shared.currentUserNotificationSettings
        let pushBadge = settings!.types.contains(.badge) ? "enabled" : "disabled"
        let pushAlert = settings!.types.contains(.alert) ? "enabled" : "disabled"
        let pushSound = settings!.types.contains(.sound) ? "enabled" : "disabled"
        
        let myDevice = UIDevice();
        let deviceName = myDevice.name
        let deviceModel = myDevice.model
        let systemVersion = myDevice.systemVersion
        let deviceId = myDevice.identifierForVendor?.uuid
        
        var appName:String?
        if let appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")
        {
            appName = appDisplayName as? String
        } else {
            appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        }
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        
        
        let myUrl = URL(string: "http://ec2-52-53-247-248.us-west-1.compute.amazonaws.com/photo-app/apns/apns.php");
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST";
        
        let postString = "task=register&appname=\(appName!)&appversion=\(appVersion!)&deviceuid=\(deviceId)&devicetoken=\(deviceTokenString)&devicename=\(deviceName)&devicemodel=\(deviceModel)&deviceversion=\(systemVersion)&pushbadge=\(pushBadge)&pushalert=\(pushAlert)&pushsound=\(pushSound)"
        
        request.httpBody = postString.data(using: String.Encoding.utf8);
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
  
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("response \(responseString!)")
            
        }
        task.resume()
        
        
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
        print("Handle push from background or closed \(response.notification.request.content.userInfo)")

        completionHandler()
    }
    
 
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,  willPresent notification: UNNotification, withCompletionHandler   completionHandler: @escaping (_ options:   UNNotificationPresentationOptions) -> Void) {
        
        // custom code to handle push while app is in the foreground
        print("Handle push from foreground \(notification.request.content.userInfo)")
        
        let dict = notification.request.content.userInfo["aps"] as! NSDictionary
        print(dict["alert"]! )
        
        var messageBody:String?
        var messageTitle:String = "Alert"
        
        
        
        if let alertDict = dict["alert"] as? Dictionary<String, String> {
            messageBody = alertDict["body"]!
            if alertDict["title"] != nil { messageTitle  = alertDict["title"]! }
            
        } else {
            messageBody = dict["alert"] as? String
        }
        
        print("Message body is \(messageBody!) ")
        print("Message messageTitle is \(messageTitle) ")
   
        // Or let iOS to display message
        completionHandler([.alert,.sound, .badge])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(" ******************** \(userInfo)")
        print("Article avaialble for download: \(userInfo["articleId"]!)")
        
        let state : UIApplicationState = application.applicationState
        switch state {
        case UIApplicationState.active:
            print("If needed notify user about the message")
        default:
            print("Run code to download content")
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    

    
}

