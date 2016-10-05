//
//  AppConfiguration.swift
//  ICSMainFramework
//
//  Created by LEI on 5/14/15.
//  Copyright (c) 2015 TouchingApp. All rights reserved.
//

import Foundation

private let sharedConfigInstance = AppConfig()

public struct ConfigKey {
    public static let lifeCycle = "lifecycle"
    public static let custom = "custom"
}

public struct LifeCycleKey {
    public static let didFinishLaunchingWithOptions = "didFinishLaunchingWithOptions"
    public static let didEnterBackground = "didEnterBackground"
    public static let willEnterForeground = "willEnterForeground"
    public static let didBecomeActive = "didBecomeActive"
    public static let remoteNotification = "remoteNotification"
    public static let willTerminate = "willTerminate"
    public static let openURL = "openURL"
}

let appConfig = AppConfig.sharedConfig

open class AppConfig {
    
    open var lifeCycleConfig = [String: [AppLifeCycleItem]]()
    open var customConfig = [String: AnyObject]()
    
    open class var sharedConfig: AppConfig {
        return sharedConfigInstance
    }
    
    open func loadConfig(fileName: String) {
        
        var components = fileName.components(separatedBy:".")
        let type = components.popLast()
        let name = components.joined(separator: ".")
        if let path = Bundle.main.path(forResource: name, ofType: type) {
            let configDict:[String: AnyObject] = NSDictionary(contentsOfFile: path) as! [String: AnyObject]
            loadConfig(dictionary:configDict)
        }
    }
    
    open func loadConfig(dictionary: [String: AnyObject]) {
        if let lifeCycleDict = dictionary[ConfigKey.lifeCycle] as? [String: AnyObject] {
            loadLifeCycleConfig(dictionary: lifeCycleDict)
        }
        if let lifeCycleDict = dictionary[ConfigKey.custom] as? [String: AnyObject] {
            loadCustomConfig(lifeCycleDict)
        }
    }
    
    func loadLifeCycleConfig(dictionary: [String: AnyObject]) {
        for (key, value) in dictionary {
            var items = [AppLifeCycleItem]()
            if let itemArray = value as? [AnyObject] {
                items = itemArray.map { AppLifeCycleItem(dictionary: $0 as! [String: AnyObject]) }.filter { $0 != nil }.map { $0! }
            }
            lifeCycleConfig[key] = items
        }
    }
    
    func loadCustomConfig(_ dictionary: [String: AnyObject]) {
        customConfig = dictionary
    }
    
}













