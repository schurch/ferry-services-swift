//
//  Weather.swift
//  FerryServices_2
//
//  Created by Stefan Church on 4/01/15.
//  Copyright (c) 2015 Stefan Church. All rights reserved.
//

import UIKit

struct Weather {
    // See http://openweathermap.org/weather-conditions for list of codes/icons/descriptions
    
    var weatherId: Int?
    var weatherGroup: String? // the group of weather (Rain, Snow, Extreme etc.)
    var weatherDescription: String? // description for weather within group
    
    // Returns a value such as 03n
    // Can be used using the URL: http://openweathermap.org/img/w/ e.g.
    // http://openweathermap.org/img/w/03n.png
    var icon: String?
    
    init(data: JSONValue) {
        self.weatherId = data["id"].integer
        self.weatherGroup = data["main"].string
        self.weatherDescription = data["description"].string
        self.icon = data["icon"].string
    }
}

struct LocationWeather {
    
    var cityId: Int?
    var cityName: String?
    
    var dateReceieved: NSDate?
    
    var latitude: Double?
    var longitude: Double?
    
    var sunrise: NSDate?
    var sunset: NSDate?
    
    // wind
    var windSpeed: Double? // meters per second
    var gustSpeed: Double? // meters per second
    var windDirection: Double? // degrees (meteorological)
    
    // temp
    var temp: Double? // kelvin
    var tempMin: Double? // kelvin
    var tempMax: Double? // kelvin
    
    var humidity: Double? // %
    
    //pressure
    var pressure: Double? // hpa
    var pressureGroundLevel: Double? // hpa
    var pressureSeaLevel: Double? // hpa
    
    var clouds: Double? // cloudiness, %
    
    var rain: [String: Double]? // precipitation volume for specified hours, mm
    var snow: [String: Double]? // snow volume for specified hours, mm
    
    // weather descriptions
    var weather: [Weather]?
    
    init (data: JSONValue) {
        self.cityId = data["id"].integer
        self.cityName = data["name"].string
        
        if let dateReceivedData = data["dt"].double {
            self.dateReceieved = NSDate(timeIntervalSince1970: dateReceivedData)
        }
        
        self.latitude = data["coord"]["lat"].double
        self.longitude = data["coord"]["lon"].double
        
        if let sunriseData = data["sys"]["sunrise"].double {
            self.sunrise = NSDate(timeIntervalSince1970: sunriseData)
        }
        
        if let sunsetData = data["sys"]["sunset"].double {
            self.sunset = NSDate(timeIntervalSince1970: sunsetData)
        }
        
        self.windSpeed = data["wind"]["speed"].double
        self.gustSpeed = data["wind"]["gust"].double
        self.windDirection = data["wind"]["deg"].double
        
        self.temp = data["main"]["temp"].double
        self.tempMax = data["main"]["temp_max"].double
        self.tempMin = data["main"]["temp_min"].double
        
        self.humidity = data["main"]["humidity"].double
        
        self.pressure = data["main"]["pressure"].double
        self.pressureGroundLevel = data["main"]["grnd_level"].double
        self.pressureSeaLevel = data["main"]["sea_level"].double
        
        self.clouds = data["clouds"]["all"].double
        
        if let rainData = data["rain"].object {
            var rain = [String: Double]()
            for (time, volume) in rainData {
                rain[time] = volume.double
            }
            self.rain = rain
        }
        
        if let snowData = data["snow"].object {
            var snow = [String: Double]()
            for (time, volume) in snowData {
                snow[time] = volume.double
            }
            self.snow = snow
        }
        
        self.weather = data["weather"].array?.map { json in Weather(data: json) }
    }
}