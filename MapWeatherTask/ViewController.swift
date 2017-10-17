//
//  ViewController.swift
//  MapWeatherTask
//
//  Created by Egor Yanukovich on 9/13/17.
//  Copyright © 2017 Egor Yanukovich. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

private let reuseIdentifier = "DailyCell"

class ViewController: UIViewController {
    
    @IBOutlet var weatherView: UIView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    
    var locationManager : CLLocationManager!
    
    var weatherData = WeatherData()
    var realm : Realm!
    var dailyWeather : Results<DailyRealmWeather>?
    private var messageToken : NotificationToken?
    var specialToken : NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //delegation
        mapView.delegate = self
        
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        
        myCollectionView.register(UINib(nibName: "DailyCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        
        let currentLocationButton = UIBarButtonItem(title:"Current location", style:UIBarButtonItemStyle.plain, target:self, action:#selector(currentLocationButtonAction(sender:)))
        self.navigationItem.leftBarButtonItem = currentLocationButton
        
        let removeAllPoints = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeLastPointsAction(sender:)))
        self.navigationItem.rightBarButtonItem = removeAllPoints
        
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(pinchOn(sender:)))
        tapGesture.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(tapGesture)
        
        myActivityIndicator.startAnimating()
    }
    //MARK: - Gestures
    func pinchOn(sender : UITapGestureRecognizer){
        if sender.state == .ended{
            let touchesPoint = sender.location(in: mapView)
            let newCoodrinate = mapView.convert(touchesPoint, toCoordinateFrom: mapView)
            
            weatherData.latitude = String(Double(newCoodrinate.latitude))
            
            weatherData.longitude = String(Double(newCoodrinate.longitude))
            
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = newCoodrinate
            
            pointAnnotation.title = "\(self.mapView.annotations.count + 1)"
            
            print(pointAnnotation.title!)
            mapView.addAnnotation(pointAnnotation)
            
            
            
        }
        
    }
    
    func loadData(){
        do {
            self.realm = try Realm()
            
        } catch {
            
        }
        self.dailyWeather = self.realm.objects(DailyRealmWeather.self).sorted(byKeyPath: "date")
        weatherData.downloadWeatherDailyRealmWeather(completed: {
            self.myActivityIndicator.stopAnimating()
            print("Completed")
            
        })
        self.messageToken = self.dailyWeather?.observe{ [weak self] changes in
            guard let collectionView = self?.myCollectionView else {return }
            
            switch changes {
            case .initial(_):
                collectionView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 0) })
                    collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 0) })
                    collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 0) })
                }, completion: { _ in })
            case .error:
                break
                
            }
            
            
        }
        //        specialToken = dailyWeather!.observe { notification in
        //            self.myCollectionView.reloadData()
        //        }
        print(self.dailyWeather ?? "Ploho")
        self.myCollectionView.reloadData()
    }
    
    //MARK: - Actions
    func currentLocationButtonAction(sender : UIBarButtonItem){
        if (CLLocationManager.locationServicesEnabled()) {
            if locationManager == nil {
                locationManager = CLLocationManager()
            }
            locationManager?.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
    }
    
    func removeLastPointsAction(sender : UIBarButtonItem){
        if self.mapView.annotations.count > 0{
            let annotation = self.mapView.annotations.last
            self.mapView.removeAnnotation(annotation!)
            
            for point in self.mapView.annotations{
                self.mapView.removeAnnotation(point)
                
                self.mapView.addAnnotation(point)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        messageToken?.invalidate()
        //specialToken?.invalidate()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
        myActivityIndicator.startAnimating()
        
        self.weatherData.downloadWeatherDailyRealmWeather{
            print(self.weatherData.cityName)
            self.loadData()
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var av = mapView.dequeueReusableAnnotationView(withIdentifier: "id")
        if av == nil {
            av = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            
        }
        
        let weatherWidthConstraint = NSLayoutConstraint(item: weatherView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 213)
        weatherView.addConstraint(weatherWidthConstraint)
        
        let weatherHeightConstraint = NSLayoutConstraint(item: weatherView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 159)
        weatherView.addConstraint(weatherHeightConstraint)
        
        
        av!.detailCalloutAccessoryView = weatherView
        av!.canShowCallout = true
        
        return av!
    }
    
}
// MARK: MKMapViewDelegate
extension ViewController : MKMapViewDelegate{
    
    public func mapViewDidFinishLoadingMap(_ mapView: MKMapView){
        myActivityIndicator.stopAnimating()
    }
}

// MARK: CLLocationManagerDelegate
extension ViewController : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        let userLocation:CLLocation = locations[0] as CLLocation
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
        
        
        let myAnnotation = MKPointAnnotation()
        myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude);
        myAnnotation.title = "Current location"
        
        self.locationManager.stopUpdatingLocation()
    }
}

// MARK: UICollectionViewDelegate
extension ViewController : UICollectionViewDelegate{
    
}

// MARK: UICollectionViewDataSource
extension ViewController : UICollectionViewDataSource{
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.dailyWeather?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell : DailyCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! DailyCell
        let weatherObject = dailyWeather?[indexPath.row]
        cell.dateLabel.text = weatherObject?.date
        
        cell.weatherImage.image = UIImage(named: (weatherObject?.icon)!)
        cell.weatherInfo.text = weatherObject?.weather
        cell.temperatureLabel.text = weatherObject?.temperature
        cell.humidityLabel.text = weatherObject?.humidity
        
        cell.layer.borderWidth = 1.0
        cell.layer.cornerRadius = 4.0
//        cell.layer.borderColor = CGColor(CGColorSpaceCreateDeviceRGB(), [1.0, 0.5, 0.5, 1.0])
    
        //как перенос вот этой информации скажется, если я перенесу ее в класс  DailyCollectionCell???
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        var reusableView = UICollectionReusableView()
        
        switch kind {
        case UICollectionElementKindSectionFooter:
            let footerView : DailyCollectionReusableView = myCollectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FooterView", for: indexPath) as! DailyCollectionReusableView
            footerView.cityNameLabel.text = self.dailyWeather?[indexPath.item].cityName
            reusableView = footerView
        default:
            break
        }
        
        return reusableView
    }
    
    
}

extension ViewController : UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        
        return CGSize(width: 90, height: 60)
    }
}


