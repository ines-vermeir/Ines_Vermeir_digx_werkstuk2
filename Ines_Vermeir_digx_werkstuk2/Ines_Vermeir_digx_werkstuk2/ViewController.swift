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
    @IBOutlet weak var titleApp: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var nameStation: UILabel!
    @IBOutlet weak var addressStation: UILabel!
    @IBOutlet weak var statusStation: UILabel!
    @IBOutlet weak var availableSation: UILabel!
    
    
    var pointAnnotation:myAnnotation!
    var pinAnnotationView:MKPinAnnotationView!

    //update stations
    @IBAction func update(_ sender: Any) {
        self.getData()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //language
        self.titleApp.text = NSLocalizedString("title", comment: "")
         self.updateButton.setTitle(NSLocalizedString("update", comment: ""), for: UIControlState.normal)
        
        //maps
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        myMapView.showsUserLocation = true
        
        //get stations
        self.getData()
        
        /*let alertController = UIAlertController(title: "iOScreator", message:
            "Hello, world!", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)*/
    }
    

    
    //set region
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    //info when annotation tapped (not working)
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annotation = view.annotation as! MKPointAnnotation
        
        let villo = annotation.title
        
        print(villo!)
        self.nameStation.text = villo
        
    }

    
    
    //add annotation
    func setAnnotation(station: VilloStation){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: station.lat,longitude: station.lng)
        annotation.title = station.name
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
                        //core data
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                        let managedContext = appDelegate.persistentContainer.viewContext
                        
                        //delete all in core data
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
                        
                        //delete annotations
                        let allAnnotations = self.myMapView.annotations
                        self.myMapView.removeAnnotations(allAnnotations)
                        
                        //get all from json
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
                            //add to core data
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
                        //save core data
                        do {
                            try managedContext.save()
                        }catch {
                            fatalError("could not save")
                        }
                        
                        //change update time
                        let today = Date()
                        self.updateTime.text = NSLocalizedString("last_update", comment: "") + today.toString(dateFormat: "yyyy-MM-dd HH:mm:ss")
                        
                        //get all stations and add them on the map
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


//bron: https://stackoverflow.com/questions/42524651/convert-nsdate-to-string-in-ios-swift/42524767
extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
