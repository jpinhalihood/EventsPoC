//
//  EBEvent.swift
//  NearMe
//
//  Created by Jeff Price on 2016-04-28.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

import Foundation


@objc
public class EBEvent : NSObject, EventProtocol/*, NSSecureCoding, NSCopying*/ {
    
    public var eventId: NSNumber?
    public var eventName: String?
    public var startTime: NSDate?
    public var endTime: NSDate?
    public var eventDescription: String?
    public var placeName: String?
    public var placeLattitude: NSNumber?
    public var placeLongitude: NSNumber?
    public var eventHost: String?
    
    // Eventbrite specific
    public var address1: String?
    public var address2: String?
    public var city: String?
    public var region: String?
    public var country: String?
    public var postalCode: String?
    
    
    
    init(jsonDictionary:NSDictionary) {

        let numberFormatter = NSNumberFormatter()
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let eventIdStr = jsonDictionary["id"] as? String {
            self.eventId = numberFormatter.numberFromString(eventIdStr)
        }
        
        if let nameDict = jsonDictionary["name"] as? [String: AnyObject] {
            self.eventName = (nameDict["text"] as? String)!
        }
        
        if let descDict = jsonDictionary["description"] as? [String: AnyObject] {
            self.eventDescription = (descDict["text"] as? String)!
        }

        if let startJson = jsonDictionary["start"] as? [String: AnyObject] {
            if let localStart = startJson["local"] as? String {
                self.startTime = dateFormatter.dateFromString(localStart)
            }
        }

        if let endJson = jsonDictionary["end"] as? [String: AnyObject] {
            if let localEnd = endJson["local"] as? String {
                self.endTime = dateFormatter.dateFromString(localEnd)
            }
        }
        
        if let venueJson = jsonDictionary["venue"] as? [String: AnyObject] {
            self.placeName = venueJson["name"] as? String
            if let addressJson = venueJson["address"] as? [String: AnyObject] {
                self.address1 = addressJson["address_1"] as? String
                self.address2 = addressJson["address_2"] as? String
                self.city = addressJson["city"] as? String
                self.region = addressJson["region"] as? String
                self.postalCode = addressJson["postal_code"] as? String
                self.country = addressJson["country"] as? String
                self.placeLongitude = addressJson["longitude"] as? NSNumber
                self.placeLattitude = addressJson["latitude"] as? NSNumber
            }
        }
    } 
}