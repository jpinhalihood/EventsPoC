//
//  EventBriteEventsForLocationOp.swift
//  NearMe
//
//  Created by Jeff Price on 2016-04-28.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

import Foundation

enum EventBriteEventsForLocationOpError : ErrorType {
    case ApiCallFailed
    case InvalidJsonFound
}


@objc
public class EventBriteEventsForLocationOp: NSOperation {
    var startDate:NSDate?
    var endDate:NSDate?
    var latitude:Double
    var longitude:Double
    var radius:Double
    var completionAction:((events:EventsList?, error:NSError?) -> Void)!
    
    let eventBriteAccessToken = "UKU37D7RIJZTNSZVAFQS"
    
    @objc
    init(latitude:Double, longitude:Double, radius:Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
    
    
    override public func main() {
        
        if(self.cancelled) {
            return
        }
        
        var fetchError:NSError?
        var events:EventsList?
        
        do {
            events = try fetchEvents()
            print(events!.count())
            
        } catch let error as NSError {
            fetchError = error
        }

        if completionAction != nil {
            completionAction(events: events, error: fetchError)
        }
        
    }
    
    
    func fetchEvents() throws -> EventsList {
        let events = EventsList()
        var page = 1
        
        while(true && !self.cancelled) {
            let url = getRequestUrl(page)
            NSLog("EventBrite URL: %@", url)
            if let newEvents = try fetchData(url, page: page) {
                events.addItems(newEvents.allItems())
                page += 1
                print("Adding \(newEvents.count()) eb events")
            }
            else {
                break;
            }
        }

        return events
    }
    
    func getRequestUrl(forPage:Int) -> String {
        var page = ""
        if forPage > 0 {
            page = String(format: "&page=%ld", forPage)
        }
        
        let formatter = NSDateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        var start = ""
        if (startDate != nil) {
            start = String(format: "&start_date.range_start=%@", formatter.stringFromDate(startDate!))
        }
        
        var end = ""
        if (endDate != nil) {
            end = String(format: "&start_date.range_end=%@", formatter.stringFromDate(endDate!))
        }
        
        let radiusInKm = String(format:"%.0fkm", floor(self.radius > 0 ? self.radius/1000 : 0))
        let urlTemplate = "https://www.eventbriteapi.com/v3/events/search/?location.latitude=%f&location.longitude=%f&location.within=%@&expand=venue%@%@%@"
        let url = String(format: urlTemplate, self.latitude, self.longitude, radiusInKm, start, end, page)
        
        return url
    }
    
    func fetchData(forUrl:String, page:Int) throws -> EventsList? {
        
        var jsonData:NSData?
        var json:AnyObject?
        var lookupError:NSError?
        
        let semaphore = dispatch_semaphore_create(0);

        let realUrl = NSURL(string: forUrl)
        let request = NSMutableURLRequest(URL: realUrl!)
        request.addValue("Bearer \(eventBriteAccessToken)", forHTTPHeaderField: "Authorization")
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            if (error != nil) {
                lookupError = error
                return
            }
            
            jsonData = data
//            let str = NSString(data: data!, encoding: NSUTF8StringEncoding)
//            print("EB Data:\n\(str)")
            
            // make this async call stop waiting
            dispatch_semaphore_signal(semaphore)
        }
        
        task.resume()
        
        // make this async call wait until the network call returns data
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        var eventsList: EventsList?
        if lookupError != nil || jsonData == nil {
            throw EventBriteEventsForLocationOpError.ApiCallFailed
        } else {
            do {
                json = try NSJSONSerialization.JSONObjectWithData(jsonData!, options:[]) as! [String: AnyObject]
            }
            catch {
                // eat the error
            }
            
            
            // Establish Results
            if let eventsJson = json!["events"] as? [NSDictionary] {
                if eventsJson.count  > 0 {
                    eventsList = EventsList()
                    for dictionary in eventsJson {
                        let ebEvent = EBEvent(jsonDictionary: dictionary)
                        eventsList!.add(ebEvent)
                    }
                }
            }
        }
        
        return eventsList;
        
    }
    
}