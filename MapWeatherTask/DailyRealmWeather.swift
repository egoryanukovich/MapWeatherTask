//
//  DailyRealmWeather.swift
//  MapWeatherTask
//
//  Created by Egor Yanukovich on 9/14/17.
//  Copyright © 2017 Egor Yanukovich. All rights reserved.
//

import RealmSwift

class DailyRealmWeather: Object {
    
    dynamic var temperature = ""
    dynamic var weather = ""
    dynamic var cityName = ""
    dynamic var date  = ""
    dynamic var humidity = ""
    dynamic var icon = ""
    dynamic var cityId = ""
    
    dynamic var compoundKey = ""
    
    override class func primaryKey() ->String?{
        return "date"
    }
}



