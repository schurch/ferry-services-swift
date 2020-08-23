//
//  WeatherAPIClient.swift
//  FerryServices_2
//
//  Created by Stefan Church on 2/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

class WeatherAPIClient {
    static let sharedInstance: WeatherAPIClient = WeatherAPIClient()
    
    static let baseURL = URL(string: "http://api.openweathermap.org/")
    static let cacheTimeoutSeconds = 600.0 // 10 minutes
    static let clientErrorDomain = "WeatherAPICientErrorDomain"
    
    private static let error = NSError(domain: WeatherAPIClient.clientErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "There was an error fetching the data. Please try again."])
    
    // MARK: - properties
    fileprivate var lastFetchTime: [String: (Date, LocationWeather)] = [String: (Date, LocationWeather)]()
    
    // MARK: - methods
    func fetchWeatherForLocation(_ location: Location, completion: @escaping (_ weather: LocationWeather?, _ error: NSError?) -> ()) {
        switch (location.latitude, location.longitude) {
        case let (.some(lat), .some(lng)):
            let requestURL = "data/2.5/weather?lat=\(lat)&lon=\(lng)&APPID=\(APIKeys.openWeatherMapAPIKey)"
            
            // check if we have made a request in the last 10 minutes
            if let lastFetchForURL = self.lastFetchTime[requestURL] {
                if Date().timeIntervalSince(lastFetchForURL.0) < WeatherAPIClient.cacheTimeoutSeconds {
                    completion(lastFetchForURL.1, nil)
                    return
                }
            }
            
            let url = URL(string: requestURL, relativeTo: WeatherAPIClient.baseURL)
            JSONRequester().requestWithURL(url!) { json, error in
                guard error == nil else {
                    DispatchQueue.main.async(execute: {
                        completion(nil, error)
                    })
                    
                    return
                }
                
                guard let json = json else {
                    DispatchQueue.main.async(execute: {
                        completion(nil, WeatherAPIClient.error)
                    })
                    
                    return
                }
                
                guard json["cod"].int == 200 else {
                    DispatchQueue.main.async(execute: {
                        completion(nil, WeatherAPIClient.error)
                    })
                    
                    return
                }
                
                let weather = LocationWeather(data: json)
                self.lastFetchTime[requestURL] = (Date(), weather) // cache result
                DispatchQueue.main.async(execute: {
                    completion(weather, nil)
                })
            }
        
        default:
            completion(nil, WeatherAPIClient.error)
        }
    }
}
