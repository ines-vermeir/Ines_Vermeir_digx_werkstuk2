//
//  ViewController.swift
//  Ines_Vermeir_digx_werkstuk2
//
//  Created by VERMEIR Inès (s) on 02/06/2018.
//  Copyright © 2018 VERMEIR Inès (s). All rights reserved.
//

import UIKit
import Foundation
import CoreData
import MapKit

class ViewController: UIViewController,  MKMapViewDelegate {

    @IBOutlet weak var myMapView: MKMapView!
    var locationManager = CLLocationManager()
    @IBOutlet weak var updateTime: UILabel!
    
    @IBAction func update(_ sender: Any) {
        self.getData()
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.requestAlwaysAuthorization()
        
        locationManager.startUpdatingLocation()
        
        self.getData()
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))
        
        myMapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let station = view.annotation as! VilloStation
        let placeName = station.name
        let placeInfo = station.address
        
        let ac = UIAlertController(title: placeName, message: placeInfo, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func setAnnotation(station: VilloStation){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: station.lat,longitude: station.lng)
        //annotation.title = station.name
        //annotation.subtitle = station.address
     
        self.myMapView.addAnnotation(annotation)
    }
    
    func getData(){
    
        let url = URL(string: "https://api.jcdecaux.com/vls/v1/stations?apiKey=6d5071ed0d0b3b68462ad73df43fd9e5479b03d6&contract=Bruxelles-Capitale")
        let urlRequest = URLRequest(url: url!)
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        session.dataTask(with: urlRequest){
            (data, response, error) in
            guard error == nil else {
                print("Error calling GET")
                print(error!)
                return
            }
            guard let responseData = data
            else {
                print("Error: no data")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [[String: AnyObject]] {
                    DispatchQueue.main.async {
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                        let managedContext = appDelegate.persistentContainer.viewContext
                        
                        let delstationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "VilloStation")
                        let delopgehaaldeStations:[VilloStation]
                        do{
                            delopgehaaldeStations = try managedContext.fetch(delstationFetch) as! [VilloStation]
                            for station in delopgehaaldeStations{
                                managedContext.delete(station)
                            }
                            try! managedContext.save()
                        }catch {
                            print("Error")
                        }
                        
                        for station in json {
                            let id = station["number"] as? Int16
                            let name = station["name"] as? String
                            let address = station["address"] as? String
                            let status = station["status"] as? String
                            let available_bike_stands = station["available_bike_stands"] as? Int16
                            let available_bikes = station["available_bikes"] as? Int16
                            let position = station["position"]!
                            let lat = position["lat"] as? Double
                            let lng = position["lng"] as? Double
                            if let station = NSEntityDescription.insertNewObject(forEntityName: "VilloStation", into: managedContext) as? VilloStation {
                                station.id = id!
                                station.name = name!
                                station.address = address!
                                station.status = status!
                                station.available_bikes = available_bikes!
                                station.available_bike_stands = available_bike_stands!
                                station.lat = lat!
                                station.lng = lng!
                            }
                        }
                        do {
                            try managedContext.save()
                        }catch {
                            fatalError("could not save")
                        }
                        let today = Date()
                        self.updateTime.text = today.toString(dateFormat: "yyyy-MM-dd HH:mm:ss")
                        let stationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "VilloStation")
                        let opgehaaldeStations:[VilloStation]
                        do{
                            opgehaaldeStations = try managedContext.fetch(stationFetch) as! [VilloStation]
                            for station in opgehaaldeStations{
                                self.setAnnotation(station: station)
                            }
                        }catch {
                                print("Error")
                        }
                        
                    }
                }
            } catch let error {
                print(error)
            }
        }.resume()
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
