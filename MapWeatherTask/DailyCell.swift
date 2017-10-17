//
//  DailyCell.swift
//  MapWeatherTask
//
//  Created by Egor Yanukovich on 9/14/17.
//  Copyright © 2017 Egor Yanukovich. All rights reserved.
//

import UIKit

class DailyCell: UICollectionViewCell {
    
    @IBOutlet var dateLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var weatherImage: UIImageView!
    
    @IBOutlet weak var weatherInfo: UILabel!
    
    @IBOutlet weak var humidityLabel: UILabel!
    
}
