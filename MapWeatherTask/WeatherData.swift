//
//  WeatherData.swift
//  MapWeatherTask
//
//  Created by Egor Yanukovich on 9/14/17.
//  Copyright © 2017 Egor Yanukovich. All rights reserved.
//

import Alamofire
import RealmSwift

class WeatherData: NSObject {
    
    var realm = try! Realm()
    
    var longitude : String = ""
    var latitude  : String = ""
    
    //Daily weather
    private var _temperature : String?
    private var _weather : String?
    private var _cityName : String?
    private var _date : String?
    private var _humidity : String?
    private var _icon : String?
    private var _cityId : String?
    
    
    var icon : String{
        return _icon ?? "Invalid icon"
    }
    var date : String{
        return _date ?? "Invalid date"
    }
    
    var temperature : String{
        return _temperature ?? "0 °C"
    }
    var cityName : String{
        return _cityName ?? "Invalid city"
    }
    
    var weather : String{
        return _weather ?? "Invalid weather"
    }
    var humidity : String{
        return _humidity ?? "Invalid weather"
    }
    var cityId : String{
        return _cityId ?? "Invalid Id"
    }
    func downloadWeatherDailyRealmWeather(completed : @escaping() -> ()){
        let url = URL(string:"http://api.openweathermap.org/data/2.5/forecast/daily?lat=\(latitude)&lon=\(longitude)&cnt=6&mode=json&appid=5dbd6e93d8ceeada8a687e06be362fc1")!
        
            Alamofire.request(url).responseJSON(completionHandler: {
                response in
                let result = response.result
                if let dict = result.value as? [String : Any]{
                    if let cityInfo = dict["city"] as? [String : Any]{
                        let nameOfCity = cityInfo["name"] as? String
                        let nameOfCountry = cityInfo["country"] as? String
                        let nameOfPlace = ("\(nameOfCity ?? "There is no such city"),\(nameOfCountry ?? "There is no such country")")
                        self._cityName = nameOfPlace//6
                        let cityId = cityInfo["id"] as? Double
                        self._cityId = String(format:"%.0f", cityId!)
                    }
                    if let list = dict["list"] as? [[String : Any]]{
                        
                        for item in list{
                            let humidity = item["humidity"] as? Double
                            self._humidity = String(format:"%.0f", humidity!)// 1
                            //Правильно ли редактировать данные при приеме? и когда их надо редактировать
                            //мб для парсинга использовать плэйграунд, чтобы сразу видеть, что отображается, а не запускать каждый раз
                            let temperatureArray = item["temp"] as? [String : Any]
                            // вся температура за сутки. ночь, день, вечер, утро.
                            let tempMax = temperatureArray?["max"] as? Float
                            let tempMin = temperatureArray?["min"] as? Float
                            let temperature = (tempMax! + tempMin!)/2.0
                            self._temperature = String(format:"%.0f °C", temperature - 273.15)// 2
                            
                            if let weather = item["weather"] as? [[String : Any]]{
                                for weatherInfo in weather{
                                    let weatherIcon = weatherInfo["icon"] as? String
                                    self._icon = weatherIcon // 3
                                    let weatherMain = weatherInfo["main"] as? String
                                    self._weather = weatherMain// 4
                                }
                            }
                            let date = item["dt"] as? Double
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .long
                            dateFormatter.timeStyle = .long
                            dateFormatter.dateFormat = "dd-MM"
                            let dateSince = Date(timeIntervalSince1970:date!)
                            let formDate = dateFormatter.string(from: dateSince)
                            self._date = formDate// 5
                            
                           // self._compoundKey = "\(self._date ?? "Bad date") \(self._cityName ?? "Bad city")"
                                let realmWeather = DailyRealmWeather(value:["temperature": self._temperature!,
                                                                            "weather": self._weather!,
                                                                            "cityName":self._cityName!,
                                                                            "date":self._date!,
                                                                            "humidity":self._humidity!,
                                                                            "icon":self._icon!,
                                                                            "cityId":self._cityId!])
                            
                                do {
                                    try! self.realm.write{
                                        self.realm.add(realmWeather, update: true)
                                    }
                                    
                                }
                                print("Show")
                        }
                    }
                
                }
                
                completed()
            })
            print("ALL")
        
    }
    
}
